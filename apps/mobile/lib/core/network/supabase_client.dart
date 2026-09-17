import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

class SupabaseService {
  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  static Future<void> initialize({String? url, String? anonKey}) async {
    final supabaseUrl = url ?? AppConstants.defaultSupabaseUrl;
    final supabaseKey = anonKey ?? AppConstants.defaultSupabaseAnonKey;

    try {
      if (supabaseUrl.contains('mock-supabase')) {
        debugPrint('[SupabaseService] Running in offline / mock mode.');
        _isInitialized = false;
        return;
      }

      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabaseKey,
        debug: kDebugMode,
      );
      _isInitialized = true;
      debugPrint('[SupabaseService] Successfully connected to Supabase.');
    } catch (e) {
      debugPrint('[SupabaseService] Error initializing Supabase: $e');
      _isInitialized = false;
    }
  }

  static SupabaseClient? get client {
    if (!_isInitialized) return null;
    return Supabase.instance.client;
  }
}
