import 'package:flutter/foundation.dart';
import '../network/supabase_client.dart';

class PushNotificationService {
  static Future<void> registerPushToken({
    required String userId,
    required String playerId,
  }) async {
    final client = SupabaseService.client;
    if (client == null) {
      debugPrint('[PushNotificationService] Offline mode: skipped registering token $playerId');
      return;
    }

    try {
      String platform = 'web';
      if (!kIsWeb) {
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          platform = 'ios';
        } else if (defaultTargetPlatform == TargetPlatform.android) {
          platform = 'android';
        }
      }

      await client.from('push_subscriptions').upsert(
        {
          'user_id': userId,
          'onesignal_player_id': playerId,
          'platform': platform,
        },
        onConflict: 'user_id, onesignal_player_id',
      );
      debugPrint('[PushNotificationService] Registered push subscription for $userId ($platform)');
    } catch (e) {
      debugPrint('[PushNotificationService] Error registering push subscription: $e');
    }
  }
}
