// Core App Constants for Paridhan

class AppConstants {
  static const String appName = 'Paridhan';
  static const String tagline = 'Wear Local. Support Local.';
  
  // Default values
  static const String defaultCurrency = '₹';
  static const String currencyCode = 'INR';
  
  // Supabase Config (Live Cloud Project)
  static const String defaultSupabaseUrl = 'https://zuhwilxfukdrmnmhyibg.supabase.co';
  static const String defaultSupabaseAnonKey = 'sb_publishable_i2mNdTzAEUoWriHBoO90ag_9S56I2TI';

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
