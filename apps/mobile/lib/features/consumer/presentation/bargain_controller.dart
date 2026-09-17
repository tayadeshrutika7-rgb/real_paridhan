import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';
import '../domain/bargain_model.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class BargainState {
  final List<Bargain> consumerBargains; // Active bargains for consumer inbox
  final List<Bargain> sellerBargains;   // Active bargains for seller inbox
  final Bargain? activeBargain;         // Currently open bargain chat
  final List<BargainMessage> messages;  // Messages for active bargain
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const BargainState({
    this.consumerBargains = const [],
    this.sellerBargains = const [],
    this.activeBargain,
    this.messages = const [],
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  BargainState copyWith({
    List<Bargain>? consumerBargains,
    List<Bargain>? sellerBargains,
    Bargain? activeBargain,
    List<BargainMessage>? messages,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearActive = false,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return BargainState(
      consumerBargains: consumerBargains ?? this.consumerBargains,
      sellerBargains: sellerBargains ?? this.sellerBargains,
      activeBargain: clearActive ? null : (activeBargain ?? this.activeBargain),
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class BargainNotifier extends Notifier<BargainState> {
  SupabaseClient? get _db => SupabaseService.client;
  RealtimeChannel? _bargainChannel;
  StreamSubscription<List<Map<String, dynamic>>>? _messagesSubscription;

  // In-memory mock storage for development / offline mode
  static final Map<String, Bargain> _mockBargains = {};
  static final Map<String, List<BargainMessage>> _mockMessages = {};

  @override
  BargainState build() {
    ref.onDispose(() {
      _bargainChannel?.unsubscribe();
      _messagesSubscription?.cancel();
    });
    return const BargainState();
  }

  // -------------------------------------------------------------------------
  // Initiate a bargain from the consumer side
  // -------------------------------------------------------------------------
  Future<String?> initiateBargain({
    required String consumerId,
    required String sellerId,
    required String productId,
    required String variantId,
    required double offerAmount,
    required double basePrice,
    required double minBargainPrice,
  }) async {
    if (offerAmount < minBargainPrice) {
      state = state.copyWith(
        errorMessage:
            'Offer ₹${offerAmount.toStringAsFixed(0)} is below the minimum acceptable price of ₹${minBargainPrice.toStringAsFixed(0)}.',
      );
      return null;
    }
    if (offerAmount >= basePrice) {
      state = state.copyWith(
        errorMessage: 'Offer must be lower than the listed price.',
      );
      return null;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    final db = _db;
    if (db == null) {
      // Mock flow
      final mockId = 'bargain-${DateTime.now().millisecondsSinceEpoch}';
      final newBargain = Bargain(
        id: mockId,
        consumerId: consumerId,
        sellerId: sellerId,
        productId: productId,
        variantId: variantId,
        status: BargainStatus.open,
        consumerOffer: offerAmount,
        basePrice: basePrice,
        minBargainPrice: minBargainPrice,
        productTitle: 'Handcrafted Festive Garment',
        productImageUrl: 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600',
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final newMsg = BargainMessage(
        id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
        bargainId: mockId,
        senderId: consumerId,
        offerAmount: offerAmount,
        messageType: BargainMessageType.offer,
        text: 'I would like to buy this for ₹${offerAmount.toStringAsFixed(0)}.',
        createdAt: DateTime.now(),
      );

      _mockBargains[mockId] = newBargain;
      _mockMessages[mockId] = [newMsg];

      state = state.copyWith(
        isLoading: false,
        consumerBargains: [newBargain, ...state.consumerBargains],
        successMessage: 'Your offer has been sent to the boutique!',
      );
      return mockId;
    }

    try {
      // Create bargain row
      final bargainRow = await db.from('bargains').insert({
        'consumer_id': consumerId,
        'seller_id': sellerId,
        'product_id': productId,
        'variant_id': variantId,
        'status': 'open',
        'consumer_offer': offerAmount,
        'expires_at': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
      }).select().single();

      final bargainId = bargainRow['id'] as String;

      // Insert initial offer message
      await db.from('bargain_messages').insert({
        'bargain_id': bargainId,
        'sender_id': consumerId,
        'offer_amount': offerAmount,
        'message_type': 'offer',
        'text': 'I would like to buy this for ₹${offerAmount.toStringAsFixed(0)}.',
      });

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Your offer has been sent to the seller!',
      );
      return bargainId;
    } catch (e) {
      String message = e.toString();
      if (message.contains('floor price')) {
        message = "Your offer is too low. The seller's minimum is ₹${minBargainPrice.toStringAsFixed(0)}.";
      }
      state = state.copyWith(isLoading: false, errorMessage: message);
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // Load bargain messages and subscribe to realtime updates
  // -------------------------------------------------------------------------
  Future<void> openBargain(String bargainId) async {
    state = state.copyWith(isLoading: true, messages: [], clearError: true);
    final db = _db;

    if (db == null) {
      final bargain = _mockBargains[bargainId] ??
          Bargain(
            id: bargainId,
            consumerId: 'demo-consumer',
            sellerId: 'demo-seller',
            productId: 'prod-01',
            variantId: 'var-01',
            status: BargainStatus.open,
            consumerOffer: 1200.0,
            basePrice: 1500.0,
            minBargainPrice: 1000.0,
            productTitle: 'Handblock Printed Kurta Set',
            expiresAt: DateTime.now().add(const Duration(hours: 24)),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

      final msgs = _mockMessages[bargainId] ??
          [
            BargainMessage(
              id: 'msg-demo-1',
              bargainId: bargainId,
              senderId: bargain.consumerId,
              offerAmount: bargain.consumerOffer,
              messageType: BargainMessageType.offer,
              text: 'I would like to buy this for ₹${bargain.consumerOffer.toStringAsFixed(0)}.',
              createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
            )
          ];

      state = state.copyWith(
        activeBargain: bargain,
        messages: msgs,
        isLoading: false,
      );
      return;
    }

    try {
      // Fetch bargain details
      final bargainData = await db
          .from('bargains')
          .select('*, products(title, base_price, min_bargain_price, product_images(url))')
          .eq('id', bargainId)
          .single();

      final productData = bargainData['products'] as Map<String, dynamic>? ?? {};
      final images = productData['product_images'] as List<dynamic>? ?? [];

      final bargain = Bargain(
        id: bargainData['id'] as String,
        consumerId: bargainData['consumer_id'] as String,
        sellerId: bargainData['seller_id'] as String,
        productId: bargainData['product_id'] as String,
        variantId: bargainData['variant_id'] as String,
        status: BargainStatus.values.firstWhere(
          (e) => e.name == bargainData['status'],
          orElse: () => BargainStatus.open,
        ),
        consumerOffer: (bargainData['consumer_offer'] as num).toDouble(),
        counterOffer: bargainData['counter_offer'] != null
            ? (bargainData['counter_offer'] as num).toDouble()
            : null,
        agreedPrice: bargainData['agreed_price'] != null
            ? (bargainData['agreed_price'] as num).toDouble()
            : null,
        basePrice: (productData['base_price'] as num? ?? 0).toDouble(),
        minBargainPrice:
            (productData['min_bargain_price'] as num? ?? 0).toDouble(),
        productTitle: productData['title'] as String?,
        productImageUrl:
            images.isNotEmpty ? (images.first as Map)['url'] as String? : null,
        expiresAt: DateTime.parse(bargainData['expires_at'] as String),
        createdAt: DateTime.parse(bargainData['created_at'] as String),
        updatedAt: DateTime.parse(bargainData['updated_at'] as String),
      );

      // Fetch messages history
      final messagesData = await db
          .from('bargain_messages')
          .select()
          .eq('bargain_id', bargainId)
          .order('created_at', ascending: true);

      final messages = (messagesData as List)
          .map((m) => BargainMessage.fromJson(m as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        activeBargain: bargain,
        messages: messages,
        isLoading: false,
      );

      // Subscribe to Realtime messages for this bargain
      _subscribeToBargain(bargainId);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void _subscribeToBargain(String bargainId) {
    final db = _db;
    if (db == null) return;

    _bargainChannel?.unsubscribe();

    _bargainChannel = db
        .channel('bargain:$bargainId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'bargain_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'bargain_id',
            value: bargainId,
          ),
          callback: (payload) {
            final newMsg = BargainMessage.fromJson(payload.newRecord);
            if (!state.messages.any((m) => m.id == newMsg.id)) {
              state = state.copyWith(messages: [...state.messages, newMsg]);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'bargains',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: bargainId,
          ),
          callback: (payload) {
            final updated = payload.newRecord;
            if (state.activeBargain != null) {
              state = state.copyWith(
                activeBargain: state.activeBargain!.copyWith(
                  status: BargainStatus.values.firstWhere(
                    (e) => e.name == updated['status'],
                    orElse: () => state.activeBargain!.status,
                  ),
                  counterOffer: updated['counter_offer'] != null
                      ? (updated['counter_offer'] as num).toDouble()
                      : state.activeBargain!.counterOffer,
                  agreedPrice: updated['agreed_price'] != null
                      ? (updated['agreed_price'] as num).toDouble()
                      : state.activeBargain!.agreedPrice,
                ),
              );
            }
          },
        )
        .subscribe();
  }

  // -------------------------------------------------------------------------
  // Seller: Counter-offer
  // -------------------------------------------------------------------------
  Future<void> counterOffer({
    required String bargainId,
    required String sellerId,
    required double counterAmount,
    required double minBargainPrice,
  }) async {
    if (counterAmount < minBargainPrice) {
      state = state.copyWith(
        errorMessage:
            'Counter offer ₹${counterAmount.toStringAsFixed(0)} cannot be lower than your minimum floor price ₹${minBargainPrice.toStringAsFixed(0)}.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    final db = _db;

    if (db == null) {
      final counterMsg = BargainMessage(
        id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
        bargainId: bargainId,
        senderId: sellerId,
        offerAmount: counterAmount,
        messageType: BargainMessageType.counter,
        text: 'How about ₹${counterAmount.toStringAsFixed(0)}?',
        createdAt: DateTime.now(),
      );

      final updatedBargain = state.activeBargain?.copyWith(
        status: BargainStatus.countered,
        counterOffer: counterAmount,
      );

      if (updatedBargain != null) {
        _mockBargains[bargainId] = updatedBargain;
        _mockMessages[bargainId] = [...state.messages, counterMsg];
        state = state.copyWith(
          isLoading: false,
          activeBargain: updatedBargain,
          messages: [...state.messages, counterMsg],
          successMessage: 'Counter offer sent to buyer.',
        );
      }
      return;
    }

    try {
      // 1. Insert counter message
      await db.from('bargain_messages').insert({
        'bargain_id': bargainId,
        'sender_id': sellerId,
        'offer_amount': counterAmount,
        'message_type': 'counter',
        'text': 'How about ₹${counterAmount.toStringAsFixed(0)}?',
      });

      // 2. Update bargain status
      await db.from('bargains').update({
        'counter_offer': counterAmount,
        'status': 'countered',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bargainId);

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Counter offer sent to buyer.',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // -------------------------------------------------------------------------
  // Consumer/Seller: Accept bargain
  // -------------------------------------------------------------------------
  Future<void> acceptBargain({
    required String bargainId,
    required String actorId,
    required double agreedPrice,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final db = _db;

    if (db == null) {
      final acceptMsg = BargainMessage(
        id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
        bargainId: bargainId,
        senderId: actorId,
        offerAmount: agreedPrice,
        messageType: BargainMessageType.accept,
        text: 'Deal accepted at ₹${agreedPrice.toStringAsFixed(0)}!',
        createdAt: DateTime.now(),
      );

      final updatedBargain = state.activeBargain?.copyWith(
        status: BargainStatus.accepted,
        agreedPrice: agreedPrice,
      );

      if (updatedBargain != null) {
        _mockBargains[bargainId] = updatedBargain;
        _mockMessages[bargainId] = [...state.messages, acceptMsg];
        state = state.copyWith(
          isLoading: false,
          activeBargain: updatedBargain,
          messages: [...state.messages, acceptMsg],
          successMessage: 'Deal accepted! Added to your cart.',
        );
      }
      return;
    }

    try {
      // 1. Insert accept message
      await db.from('bargain_messages').insert({
        'bargain_id': bargainId,
        'sender_id': actorId,
        'offer_amount': agreedPrice,
        'message_type': 'accept',
        'text': 'Deal accepted at ₹${agreedPrice.toStringAsFixed(0)}!',
      });

      // 2. Update bargain row status
      await db.from('bargains').update({
        'status': 'accepted',
        'agreed_price': agreedPrice,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bargainId);

      // 3. Upsert into cart_items with special agreed price and 24hr reservation lock
      final active = state.activeBargain;
      if (active != null) {
        await db.from('cart_items').upsert({
          'consumer_id': active.consumerId,
          'product_id': active.productId,
          'variant_id': active.variantId,
          'quantity': 1,
          'bargain_id': bargainId,
          'agreed_price': agreedPrice,
          'reserved_until':
              DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
        });
      }

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Deal accepted! Added to your cart.',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // -------------------------------------------------------------------------
  // Consumer/Seller: Reject bargain
  // -------------------------------------------------------------------------
  Future<void> rejectBargain({
    required String bargainId,
    required String actorId,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final db = _db;

    if (db == null) {
      final updatedBargain = state.activeBargain?.copyWith(
        status: BargainStatus.rejected,
      );
      if (updatedBargain != null) {
        _mockBargains[bargainId] = updatedBargain;
      }
      state = state.copyWith(isLoading: false, clearActive: true, messages: []);
      return;
    }

    try {
      await db.from('bargain_messages').insert({
        'bargain_id': bargainId,
        'sender_id': actorId,
        'message_type': 'reject',
        'text': "I've decided not to proceed with this bargain.",
      });

      await db.from('bargains').update({'status': 'rejected'}).eq('id', bargainId);

      state = state.copyWith(isLoading: false, clearActive: true, messages: []);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // -------------------------------------------------------------------------
  // Fetch consumer bargain inbox
  // -------------------------------------------------------------------------
  Future<void> loadConsumerBargains(String consumerId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final db = _db;

    if (db == null) {
      final list = _mockBargains.values.toList();
      state = state.copyWith(consumerBargains: list, isLoading: false);
      return;
    }

    try {
      final data = await db
          .from('bargains')
          .select(
              '*, products(title, base_price, product_images(url))')
          .eq('consumer_id', consumerId)
          .inFilter('status', ['open', 'countered', 'accepted'])
          .order('updated_at', ascending: false);

      final bargains = (data as List).map((row) {
        final m = row as Map<String, dynamic>;
        final prod = m['products'] as Map<String, dynamic>? ?? {};
        final imgs = prod['product_images'] as List<dynamic>? ?? [];
        return Bargain(
          id: m['id'] as String,
          consumerId: m['consumer_id'] as String,
          sellerId: m['seller_id'] as String,
          productId: m['product_id'] as String,
          variantId: m['variant_id'] as String,
          status: BargainStatus.values.firstWhere(
            (e) => e.name == m['status'],
            orElse: () => BargainStatus.open,
          ),
          consumerOffer: (m['consumer_offer'] as num).toDouble(),
          counterOffer: m['counter_offer'] != null ? (m['counter_offer'] as num).toDouble() : null,
          agreedPrice: m['agreed_price'] != null ? (m['agreed_price'] as num).toDouble() : null,
          basePrice: (prod['base_price'] as num? ?? 0).toDouble(),
          minBargainPrice: 0,
          productTitle: prod['title'] as String?,
          productImageUrl: imgs.isNotEmpty ? (imgs.first as Map)['url'] as String? : null,
          expiresAt: DateTime.parse(m['expires_at'] as String),
          createdAt: DateTime.parse(m['created_at'] as String),
          updatedAt: DateTime.parse(m['updated_at'] as String),
        );
      }).toList();

      state = state.copyWith(consumerBargains: bargains, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // -------------------------------------------------------------------------
  // Fetch seller bargain inbox
  // -------------------------------------------------------------------------
  Future<void> loadSellerBargains(String sellerId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final db = _db;

    if (db == null) {
      final list = _mockBargains.values.toList();
      state = state.copyWith(sellerBargains: list, isLoading: false);
      return;
    }

    try {
      final data = await db
          .from('bargains')
          .select('*, products(title, base_price, min_bargain_price, product_images(url))')
          .eq('seller_id', sellerId)
          .inFilter('status', ['open', 'countered'])
          .order('updated_at', ascending: false);

      final bargains = (data as List).map((row) {
        final m = row as Map<String, dynamic>;
        final prod = m['products'] as Map<String, dynamic>? ?? {};
        final imgs = prod['product_images'] as List<dynamic>? ?? [];
        return Bargain(
          id: m['id'] as String,
          consumerId: m['consumer_id'] as String,
          sellerId: m['seller_id'] as String,
          productId: m['product_id'] as String,
          variantId: m['variant_id'] as String,
          status: BargainStatus.values.firstWhere(
            (e) => e.name == m['status'],
            orElse: () => BargainStatus.open,
          ),
          consumerOffer: (m['consumer_offer'] as num).toDouble(),
          counterOffer: m['counter_offer'] != null ? (m['counter_offer'] as num).toDouble() : null,
          agreedPrice: m['agreed_price'] != null ? (m['agreed_price'] as num).toDouble() : null,
          basePrice: (prod['base_price'] as num? ?? 0).toDouble(),
          minBargainPrice: (prod['min_bargain_price'] as num? ?? 0).toDouble(),
          productTitle: prod['title'] as String?,
          productImageUrl: imgs.isNotEmpty ? (imgs.first as Map)['url'] as String? : null,
          expiresAt: DateTime.parse(m['expires_at'] as String),
          createdAt: DateTime.parse(m['created_at'] as String),
          updatedAt: DateTime.parse(m['updated_at'] as String),
        );
      }).toList();

      state = state.copyWith(sellerBargains: bargains, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

final bargainProvider =
    NotifierProvider<BargainNotifier, BargainState>(BargainNotifier.new);
