import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_state.dart';
import '../data/advertisement_repository.dart';
import '../domain/advertisement_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/notifications/domain/app_notification_model.dart';
import '../../../core/notifications/presentation/role_notification_controller.dart';

class AdvertisementState {
  final bool isLoading;
  final List<AdvertisementModel> activeHeroAds;
  final List<AdvertisementModel> activeCategoryAds;
  final List<AdvertisementModel> activeSpotlightAds;
  final List<AdvertisementModel> sellerAds;
  final List<AdvertisementModel> adminAds;
  final List<SmtpEmailRecord> emailLogs;
  final String? errorMessage;
  final String? successMessage;

  const AdvertisementState({
    this.isLoading = false,
    this.activeHeroAds = const [],
    this.activeCategoryAds = const [],
    this.activeSpotlightAds = const [],
    this.sellerAds = const [],
    this.adminAds = const [],
    this.emailLogs = const [],
    this.errorMessage,
    this.successMessage,
  });

  AdvertisementState copyWith({
    bool? isLoading,
    List<AdvertisementModel>? activeHeroAds,
    List<AdvertisementModel>? activeCategoryAds,
    List<AdvertisementModel>? activeSpotlightAds,
    List<AdvertisementModel>? sellerAds,
    List<AdvertisementModel>? adminAds,
    List<SmtpEmailRecord>? emailLogs,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AdvertisementState(
      isLoading: isLoading ?? this.isLoading,
      activeHeroAds: activeHeroAds ?? this.activeHeroAds,
      activeCategoryAds: activeCategoryAds ?? this.activeCategoryAds,
      activeSpotlightAds: activeSpotlightAds ?? this.activeSpotlightAds,
      sellerAds: sellerAds ?? this.sellerAds,
      adminAds: adminAds ?? this.adminAds,
      emailLogs: emailLogs ?? this.emailLogs,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class AdvertisementNotifier extends Notifier<AdvertisementState> {
  final AdvertisementRepository _repository = AdvertisementRepository();

  @override
  AdvertisementState build() {
    Future.microtask(() => loadInitialData());
    return const AdvertisementState(isLoading: true);
  }

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final authState = ref.read(authProvider);
      final sellerId = authState.user?.id ?? 'mock-user-123';

      final heroAds = await _repository.getActiveAdsByPlacement('home_hero');
      final catAds = await _repository.getActiveAdsByPlacement('category_header');
      final spotAds = await _repository.getActiveAdsByPlacement('featured_feed');
      final sellerList = await _repository.getSellerAdRequests(sellerId);
      final allList = await _repository.getAllAdRequests();

      state = state.copyWith(
        isLoading: false,
        activeHeroAds: heroAds,
        activeCategoryAds: catAds,
        activeSpotlightAds: spotAds,
        sellerAds: sellerList,
        adminAds: allList,
        emailLogs: _repository.emailLogs,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<String?> uploadBannerImage(Uint8List bytes, String fileName) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final url = await _repository.uploadBannerImage(bytes, fileName);
      state = state.copyWith(isLoading: false);
      return url;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to upload banner: $e');
      return null;
    }
  }

  Future<bool> submitAdRequest({
    required String title,
    required String subtitle,
    required String tag,
    required String bannerImageUrl,
    required String placement,
    required String targetType,
    String? targetId,
    String? targetCategory,
    required String buttonText,
    String? badgeText,
    required int durationDays,
    required double budget,
    required String paymentId,
    String paymentMethod = 'razorpay',
    String? shopId,
    String? shopName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final authState = ref.read(authProvider);
      final user = authState.user;
      final sellerId = user?.id ?? 'mock-user-123';

      final effectiveShopId = shopId ?? 'shop-jaipur-01';
      final effectiveShopName = shopName ?? (user?.fullName ?? 'Jaipur Heritage Handlooms');

      final newAd = AdvertisementModel(
        id: 'ad-${DateTime.now().millisecondsSinceEpoch}',
        sellerId: sellerId,
        shopId: effectiveShopId,
        shopName: effectiveShopName,
        sellerEmail: user?.email ?? 'rajesh.handlooms@jaipur.in',
        sellerPhone: user?.phone ?? '+91 98290 12345',
        title: title,
        subtitle: subtitle,
        tag: tag,
        bannerImageUrl: bannerImageUrl,
        placement: placement,
        targetType: targetType,
        targetId: targetId ?? effectiveShopId,
        targetCategory: targetCategory,
        buttonText: buttonText,
        badgeText: badgeText,
        durationDays: durationDays,
        budget: budget,
        paymentId: paymentId,
        paymentStatus: 'paid',
        paymentMethod: paymentMethod,
        status: 'pending',
        isPaused: false,
        createdAt: DateTime.now(),
      );

      final created = await _repository.createAdRequest(newAd);

      // Auto notify admin via SMTP mock dispatcher
      await _repository.sendSmtpEmail(
        toEmail: 'admin@paridhan.app',
        toName: 'Super Admin Operations',
        subject: '[Ad Review Required] "${created.title}" from ${created.shopName}',
        bodyText: 'New Campaign Submission Received:\n'
            '• Shop: ${created.shopName} (${created.sellerEmail})\n'
            '• Title: ${created.title}\n'
            '• Placement: ${created.placement}\n'
            '• Target: ${created.targetType} (${created.targetCategory ?? created.targetId})\n'
            '• Package: ${created.durationDays} Days (₹${created.budget.toStringAsFixed(2)})\n'
            '• Payment: Verified (${created.paymentId} via Razorpay)\n\n'
            'Please review in Super Admin Portal -> Seller Advertisements.',
        templateType: 'admin_notification',
      );

      // Seller Notification
      ref.read(roleNotificationProvider(UserRole.seller).notifier).postNotification(
        title: 'Campaign Submitted for Review',
        body: 'Your campaign "${created.title}" is pending admin approval.',
        category: NotificationCategory.campaign,
        deepLink: '/seller/advertisements',
      );

      // Admin Notification
      ref.read(roleNotificationProvider(UserRole.admin).notifier).postNotification(
        title: 'New Ad Campaign for Approval',
        body: '${created.shopName} submitted campaign "${created.title}" (₹${created.budget.toStringAsFixed(0)}).',
        category: NotificationCategory.campaign,
        deepLink: '/admin/advertisements',
      );

      await loadInitialData();
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Advertisement request & payment submitted! Admin will review and activate.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> approveAdRequest(
    String adId, {
    String? adminNotes,
    bool sendEmail = true,
    String? customEmailBody,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated = await _repository.updateAdStatus(
        adId: adId,
        status: 'approved',
        adminNotes: adminNotes ?? 'Approved and activated on Customer Platform.',
      );

      if (updated != null && sendEmail) {
        final emailText = customEmailBody ??
            'Dear ${updated.shopName},\n\n'
            'Congratulations! Your advertisement campaign "${updated.title}" has been APPROVED by the Paridhan Platform Team.\n\n'
            'Campaign Summary:\n'
            '• Campaign Title: ${updated.title}\n'
            '• Placement: ${updated.placement}\n'
            '• Target: ${updated.targetCategory ?? updated.targetId ?? updated.targetType}\n'
            '• Duration: ${updated.durationDays} Days (Active from today)\n'
            '• Live Status: LIVE & VISIBLE TO CUSTOMERS\n\n'
            'You can monitor real-time impressions and clicks under "My Campaigns" in the Seller Studio.\n\n'
            'Thank you for partnering with Paridhan.\n'
            'Best Regards,\n'
            'Paridhan Operations Team';

        await _repository.sendSmtpEmail(
          toEmail: updated.sellerEmail.isNotEmpty ? updated.sellerEmail : 'seller@boutique.com',
          toName: updated.shopName,
          subject: '✅ Advertisement Approved & Live: "${updated.title}"',
          bodyText: emailText,
          templateType: 'ad_approved',
        );

        // Notify Seller
        ref.read(roleNotificationProvider(UserRole.seller).notifier).postNotification(
          title: 'Ad Campaign Approved & Live! 🎉',
          body: 'Your campaign "${updated.title}" is now active and visible to customers.',
          category: NotificationCategory.campaign,
          deepLink: '/seller/advertisements',
        );

        // Notify Admin
        ref.read(roleNotificationProvider(UserRole.admin).notifier).postNotification(
          title: 'Campaign Activated',
          body: 'Approved campaign "${updated.title}" for ${updated.shopName}.',
          category: NotificationCategory.campaign,
          deepLink: '/admin/advertisements',
        );
      }

      await loadInitialData();
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Advertisement approved! Now live on Customer screens.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> rejectAdRequest(
    String adId, {
    required String reason,
    bool sendEmail = true,
    String? customEmailBody,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated = await _repository.updateAdStatus(
        adId: adId,
        status: 'rejected',
        adminNotes: reason,
      );

      if (updated != null && sendEmail) {
        final emailText = customEmailBody ??
            'Dear ${updated.shopName},\n\n'
            'Regarding your advertisement request for "${updated.title}":\n\n'
            'Status: Not Approved\n'
            'Feedback / Reason: $reason\n\n'
            'Please update your creative or details and submit again, or contact seller support.\n\n'
            'Best Regards,\n'
            'Paridhan Operations Team';

        await _repository.sendSmtpEmail(
          toEmail: updated.sellerEmail.isNotEmpty ? updated.sellerEmail : 'seller@boutique.com',
          toName: updated.shopName,
          subject: 'Update on Advertisement Request: "${updated.title}"',
          bodyText: emailText,
          templateType: 'ad_rejected',
        );

        // Notify Seller
        ref.read(roleNotificationProvider(UserRole.seller).notifier).postNotification(
          title: 'Ad Campaign Needs Revisions',
          body: 'Campaign "${updated.title}" was not approved: $reason',
          category: NotificationCategory.campaign,
          deepLink: '/seller/advertisements',
        );

        // Notify Admin
        ref.read(roleNotificationProvider(UserRole.admin).notifier).postNotification(
          title: 'Campaign Rejected',
          body: 'Rejected "${updated.title}" for ${updated.shopName}.',
          category: NotificationCategory.campaign,
          deepLink: '/admin/advertisements',
        );
      }

      await loadInitialData();
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Advertisement request rejected and seller notified.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> toggleAdPause(String adId, bool isPaused) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.toggleAdPause(adId, isPaused);
      await loadInitialData();
      state = state.copyWith(
        isLoading: false,
        successMessage: isPaused ? 'Campaign paused successfully.' : 'Campaign resumed and live.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> recordImpression(String adId) async {
    await _repository.recordImpression(adId);
  }

  Future<void> recordClick(String adId) async {
    await _repository.recordClick(adId);
  }

  Future<bool> sendCustomSmtpEmail({
    required String toEmail,
    required String toName,
    required String subject,
    required String message,
  }) async {
    try {
      await _repository.sendSmtpEmail(
        toEmail: toEmail,
        toName: toName,
        subject: subject,
        bodyText: message,
        templateType: 'custom_inquiry',
      );
      state = state.copyWith(
        emailLogs: _repository.emailLogs,
        successMessage: 'SMTP Email sent successfully to $toEmail!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to send SMTP email: $e');
      return false;
    }
  }
}

final advertisementProvider =
    NotifierProvider<AdvertisementNotifier, AdvertisementState>(() {
  return AdvertisementNotifier();
});
