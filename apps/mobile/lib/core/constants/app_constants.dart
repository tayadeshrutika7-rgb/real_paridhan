// Core App Constants for Paridhan

class AppConstants {
  static const String appName = 'Paridhan';
  static const String tagline = 'Wear Local. Support Local.';
  
  // Default values
  static const String defaultCurrency = '₹';
  static const String currencyCode = 'INR';
  
  // Supabase Config (Fallbacks / Local dev)
  static const String defaultSupabaseUrl = 'https://mock-supabase.paridhan.local';
  static const String defaultSupabaseAnonKey = 'mock-anon-key';

  // Deep linking scheme
  static const String deepLinkScheme = 'paridhan';
}

enum AppFlavor {
  consumer,
  seller,
  delivery,
}

enum UserRole {
  consumer,
  seller,
  delivery,
  admin,
}
