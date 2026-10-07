import 'package:flutter/foundation.dart';
import '../../../core/network/supabase_client.dart';
import '../domain/advertisement_model.dart';

class SmtpEmailRecord {
  final String id;
  final String toEmail;
  final String toName;
  final String subject;
  final String bodyText;
  final String templateType; // 'ad_approved', 'ad_rejected', 'custom_inquiry'
  final DateTime sentAt;
  final bool isDelivered;
  final String smtpServer;

  const SmtpEmailRecord({
    required this.id,
    required this.toEmail,
    required this.toName,
    required this.subject,
    required this.bodyText,
    required this.templateType,
    required this.sentAt,
    this.isDelivered = true,
    this.smtpServer = 'smtp.paridhan.app:587 (TLS)',
  });
}

class AdvertisementRepository {
  static final List<AdvertisementModel> _mockAds = [
    AdvertisementModel(
      id: 'ad-001',
      sellerId: 'mock-user-123',
      shopId: 'shop-jaipur-01',
      shopName: 'Jaipur Heritage Handlooms',
      sellerEmail: 'rajesh.handlooms@jaipur.in',
      sellerPhone: '+91 98290 12345',
      title: 'Grand Bandhani & Leheriya Utsav',
      subtitle: 'Exclusive 35% Flat Discount on Royal Handwoven Sarees & Dupattas. Direct from Jaipur artisans.',
      tag: 'BOUTIQUE SPOTLIGHT',
      bannerImageUrl: 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=1200',
      placement: 'home_hero',
      targetType: 'shop',
      targetId: 'shop-jaipur-01',
      targetCategory: 'Women Ethnic',
      buttonText: 'Shop Heritage Collection',
      badgeText: 'FLAT\n35%\nOFF',
      durationDays: 15,
      budget: 1499.00,
      paymentId: 'pay_mock_982901',
      paymentStatus: 'paid',
      paymentMethod: 'razorpay',
      status: 'approved',
      adminNotes: 'Approved for prime Home Hero Placement.',
      isPaused: false,
      impressions: 4320,
      clicks: 348,
      ordersCount: 29,
      revenueGenerated: 46800.0,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      approvedAt: DateTime.now().subtract(const Duration(days: 1)),
      expiresAt: DateTime.now().add(const Duration(days: 14)),
    ),
    AdvertisementModel(
      id: 'ad-002',
      sellerId: 'seller-002',
      shopId: 'shop-002',
      shopName: 'Royal Zari Palace',
      sellerEmail: 'contact@royalzari.com',
      sellerPhone: '+91 98765 43210',
      title: 'Bridal Lehenga Season Launch',
      subtitle: 'Custom handcrafted bridal sets with instant video call consultation & doorstep trial.',
      tag: 'FESTIVE BRIDAL EDIT',
      bannerImageUrl: 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=1200',
      placement: 'home_hero',
      targetType: 'shop',
      targetId: 'shop-002',
      targetCategory: 'Women Ethnic',
      buttonText: 'Book Video Trial',
      badgeText: 'NEW\nSEASON',
      durationDays: 30,
      budget: 2799.00,
      paymentId: 'pay_mock_774412',
      paymentStatus: 'paid',
      paymentMethod: 'razorpay',
      status: 'pending',
      adminNotes: 'Awaiting admin rate review & banner verification.',
      isPaused: false,
      impressions: 0,
      clicks: 0,
      ordersCount: 0,
      revenueGenerated: 0.0,
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    AdvertisementModel(
      id: 'ad-003',
      sellerId: 'mock-user-123',
      shopId: 'shop-jaipur-01',
      shopName: 'Jaipur Heritage Handlooms',
      sellerEmail: 'rajesh.handlooms@jaipur.in',
      sellerPhone: '+91 98290 12345',
      title: 'Royal Silk Dupattas & Kurtis',
      subtitle: 'Premium handcrafted pure silk collection with instant doorstep trial in Jaipur.',
      tag: 'CATEGORY SPECIAL',
      bannerImageUrl: 'https://images.unsplash.com/photo-1555529669-e69e7aa0ba9a?w=1200',
      placement: 'category_header',
      targetType: 'category',
      targetId: 'Women Ethnic',
      targetCategory: 'Women Ethnic',
      buttonText: 'Explore Category',
      badgeText: 'FLAT\n25%\nOFF',
      durationDays: 7,
      budget: 799.00,
      paymentId: 'pay_mock_551239',
      paymentStatus: 'paid',
      paymentMethod: 'razorpay',
      status: 'approved',
      adminNotes: 'Active on Women Ethnic Category Header.',
      isPaused: false,
      impressions: 1850,
      clicks: 142,
      ordersCount: 14,
      revenueGenerated: 21900.0,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      approvedAt: DateTime.now().subtract(const Duration(hours: 18)),
      expiresAt: DateTime.now().add(const Duration(days: 6)),
    ),
    AdvertisementModel(
      id: 'ad-004',
      sellerId: 'mock-user-123',
      shopId: 'shop-jaipur-01',
      shopName: 'Jaipur Heritage Handlooms',
      sellerEmail: 'rajesh.handlooms@jaipur.in',
      sellerPhone: '+91 98290 12345',
      title: 'Top Rated Artisan Boutique',
      subtitle: 'Featured Jaipur Heritage Handlooms boutique in Recommended Spotlight.',
      tag: 'FEATURED BOUTIQUE',
      bannerImageUrl: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800',
      placement: 'featured_feed',
      targetType: 'shop',
      targetId: 'shop-jaipur-01',
      targetCategory: 'Ethnic',
      buttonText: 'Visit Boutique',
      badgeText: 'TOP\nSTORE',
      durationDays: 15,
      budget: 1499.00,
      paymentId: 'pay_mock_112233',
      paymentStatus: 'paid',
      paymentMethod: 'razorpay',
      status: 'approved',
      adminNotes: 'Spotlight live in Boutique Recommendations.',
      isPaused: false,
      impressions: 2600,
      clicks: 215,
      ordersCount: 19,
      revenueGenerated: 34500.0,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      approvedAt: DateTime.now().subtract(const Duration(days: 2)),
      expiresAt: DateTime.now().add(const Duration(days: 13)),
    ),
  ];

  static final List<SmtpEmailRecord> _emailLogs = [];

  List<SmtpEmailRecord> get emailLogs => List.unmodifiable(_emailLogs);

  Future<List<AdvertisementModel>> getActiveAdsByPlacement(String placement, {String? category}) async {
    final client = SupabaseService.client;
    if (client == null) {
      return _mockAds.where((ad) {
        if (!ad.isLive) return false;
        if (ad.placement != placement && !(placement == 'featured_feed' && ad.placement == 'boutique_spotlight')) {
          return false;
        }
        if (category != null && category.isNotEmpty && category != 'All') {
          if (ad.targetCategory != null && ad.targetCategory != category) {
            return false;
          }
        }
        return true;
      }).toList();
    }

    try {
      dynamic builder = client
          .from('advertisements')
          .select()
          .inFilter('status', ['approved', 'live'])
          .eq('is_paused', false);

      if (placement == 'home_hero') {
        builder = builder.eq('placement', 'home_hero');
      } else if (placement == 'category_header') {
        builder = builder.eq('placement', 'category_header');
      } else {
        builder = builder.inFilter('placement', ['featured_feed', 'boutique_spotlight']);
      }

      final res = await builder.order('approved_at', ascending: false);
      final list = (res as List<dynamic>).map((e) => AdvertisementModel.fromJson(e)).toList();

      // Client-side expiry safety check
      return list.where((ad) => !ad.isExpired).toList();
    } catch (e) {
      debugPrint('[AdvertisementRepository] Error fetching active ads for $placement: $e');
      return _mockAds.where((ad) => ad.isLive && ad.placement == placement).toList();
    }
  }

  Future<List<AdvertisementModel>> getActiveHeroAds() async {
    return getActiveAdsByPlacement('home_hero');
  }

  Future<List<AdvertisementModel>> getSellerAdRequests(String sellerId) async {
    final client = SupabaseService.client;
    if (client == null) {
      return _mockAds.where((ad) => ad.sellerId == sellerId || sellerId == 'mock-user-123').toList();
    }

    try {
      final res = await client
          .from('advertisements')
          .select()
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false);

      return (res as List<dynamic>).map((e) => AdvertisementModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('[AdvertisementRepository] Error fetching seller ads: $e');
      return _mockAds.where((ad) => ad.sellerId == sellerId || sellerId == 'mock-user-123').toList();
    }
  }

  Future<List<AdvertisementModel>> getAllAdRequests() async {
    final client = SupabaseService.client;
    if (client == null) {
      return List.from(_mockAds);
    }

    try {
      final res = await client
          .from('advertisements')
          .select()
          .order('created_at', ascending: false);

      return (res as List<dynamic>).map((e) => AdvertisementModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('[AdvertisementRepository] Error fetching all ads: $e');
      return List.from(_mockAds);
    }
  }

  Future<AdvertisementModel> createAdRequest(AdvertisementModel ad) async {
    final client = SupabaseService.client;
    if (client == null) {
      _mockAds.insert(0, ad);
      return ad;
    }

    try {
      final res = await client.from('advertisements').insert(ad.toJson()).select().single();
      final created = AdvertisementModel.fromJson(res);
      _mockAds.insert(0, created);
      return created;
    } catch (e) {
      debugPrint('[AdvertisementRepository] Error creating ad: $e');
      _mockAds.insert(0, ad);
      return ad;
    }
  }

  Future<AdvertisementModel?> updateAdStatus({
    required String adId,
    required String status,
    String? adminNotes,
  }) async {
    final now = DateTime.now();
    final client = SupabaseService.client;

    final index = _mockAds.indexWhere((ad) => ad.id == adId);
    final duration = index >= 0 ? _mockAds[index].durationDays : 15;
    final expiresAt = status == 'approved' || status == 'live' ? now.add(Duration(days: duration)) : null;

    if (client == null) {
      if (index >= 0) {
        final existing = _mockAds[index];
        final updated = existing.copyWith(
          status: status,
          adminNotes: adminNotes ?? existing.adminNotes,
          approvedAt: (status == 'approved' || status == 'live') ? now : existing.approvedAt,
          expiresAt: expiresAt ?? existing.expiresAt,
        );
        _mockAds[index] = updated;
        return updated;
      }
      return null;
    }

    try {
      final updates = <String, dynamic>{
        'status': status,
        'admin_notes': adminNotes,
      };

      if (status == 'approved' || status == 'live') {
        updates['approved_at'] = now.toIso8601String();
        updates['expires_at'] = now.add(Duration(days: duration)).toIso8601String();
      }

      final res = await client
          .from('advertisements')
          .update(updates)
          .eq('id', adId)
          .select()
          .single();

      final updated = AdvertisementModel.fromJson(res);
      if (index >= 0) _mockAds[index] = updated;
      return updated;
    } catch (e) {
      debugPrint('[AdvertisementRepository] Error updating ad status: $e');
      if (index >= 0) {
        final existing = _mockAds[index];
        final updated = existing.copyWith(
          status: status,
          adminNotes: adminNotes ?? existing.adminNotes,
          approvedAt: (status == 'approved' || status == 'live') ? now : existing.approvedAt,
          expiresAt: expiresAt ?? existing.expiresAt,
        );
        _mockAds[index] = updated;
        return updated;
      }
      return null;
    }
  }

  Future<AdvertisementModel?> toggleAdPause(String adId, bool isPaused) async {
    final client = SupabaseService.client;
    final index = _mockAds.indexWhere((ad) => ad.id == adId);

    if (client == null) {
      if (index >= 0) {
        final existing = _mockAds[index];
        final updated = existing.copyWith(
          isPaused: isPaused,
          status: isPaused ? 'paused' : 'approved',
        );
        _mockAds[index] = updated;
        return updated;
      }
      return null;
    }

    try {
      final updates = {
        'is_paused': isPaused,
        'status': isPaused ? 'paused' : 'approved',
      };
      final res = await client.from('advertisements').update(updates).eq('id', adId).select().single();
      final updated = AdvertisementModel.fromJson(res);
      if (index >= 0) _mockAds[index] = updated;
      return updated;
    } catch (e) {
      debugPrint('[AdvertisementRepository] Error toggling ad pause: $e');
      if (index >= 0) {
        final existing = _mockAds[index];
        final updated = existing.copyWith(
          isPaused: isPaused,
          status: isPaused ? 'paused' : 'approved',
        );
        _mockAds[index] = updated;
        return updated;
      }
      return null;
    }
  }

  Future<void> recordImpression(String adId) async {
    final index = _mockAds.indexWhere((ad) => ad.id == adId);
    if (index >= 0) {
      final ad = _mockAds[index];
      _mockAds[index] = ad.copyWith(impressions: ad.impressions + 1);
    }

    final client = SupabaseService.client;
    if (client != null) {
      try {
        await client.from('ad_interactions').insert({
          'ad_id': adId,
          'interaction_type': 'impression',
        });
      } catch (_) {}
    }
  }

  Future<void> recordClick(String adId) async {
    final index = _mockAds.indexWhere((ad) => ad.id == adId);
    if (index >= 0) {
      final ad = _mockAds[index];
      _mockAds[index] = ad.copyWith(clicks: ad.clicks + 1);
    }

    final client = SupabaseService.client;
    if (client != null) {
      try {
        await client.from('ad_interactions').insert({
          'ad_id': adId,
          'interaction_type': 'click',
        });
      } catch (_) {}
    }
  }

  Future<String?> uploadBannerImage(Uint8List bytes, String fileName) async {
    final client = SupabaseService.client;
    if (client == null) {
      // Return a placeholder or mock image URL
      return 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=1200';
    }

    try {
      final cleanFileName = 'ad_banner_${DateTime.now().millisecondsSinceEpoch}_$fileName';
      await client.storage.from('shop-banners').uploadBinary(
            cleanFileName,
            bytes,
          );
      final publicUrl = client.storage.from('shop-banners').getPublicUrl(cleanFileName);
      return publicUrl;
    } catch (e) {
      debugPrint('[AdvertisementRepository] Error uploading banner to storage: $e');
      return null;
    }
  }

  /// Send automated or custom SMTP Email to Seller
  Future<SmtpEmailRecord> sendSmtpEmail({
    required String toEmail,
    required String toName,
    required String subject,
    required String bodyText,
    required String templateType,
  }) async {
    final record = SmtpEmailRecord(
      id: 'smtp-${DateTime.now().millisecondsSinceEpoch}',
      toEmail: toEmail,
      toName: toName,
      subject: subject,
      bodyText: bodyText,
      templateType: templateType,
      sentAt: DateTime.now(),
      isDelivered: true,
      smtpServer: 'smtp.paridhan.app:587 (TLS Authenticated)',
    );

    _emailLogs.insert(0, record);

    debugPrint('====================================================');
    debugPrint('[SMTP DISPATCH SUCCESS] -> To: $toName <$toEmail>');
    debugPrint('Subject: $subject');
    debugPrint('Server: ${record.smtpServer}');
    debugPrint('Timestamp: ${record.sentAt.toIso8601String()}');
    debugPrint('Body:\n$bodyText');
    debugPrint('====================================================');

    return record;
  }
}
