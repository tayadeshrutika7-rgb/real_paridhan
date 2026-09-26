// Core App Constants for Paridhan

class AppConstants {
  static const String appName = 'Paridhan';
  static const String tagline = 'Wear Local. Support Local.';
  
  // Default values
  static const String defaultCurrency = '₹';
  static const String currencyCode = 'INR';
  
  // Supabase Config (Live Cloud Project with --dart-define / env support)
  static const String defaultSupabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: String.fromEnvironment(
      'NEXT_PUBLIC_SUPABASE_URL',
      defaultValue: 'https://faqtswmhgintutwvnkyy.supabase.co',
    ),
  );
  static const String defaultSupabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: String.fromEnvironment(
      'NEXT_PUBLIC_SUPABASE_ANON_KEY',
      defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZhcXRzd21oZ2ludHV0d3Zua3l5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY0NjI0NTMsImV4cCI6MjEwMjAzODQ1M30.nr2puO_hmsJoqyEBVefABmNMqv6ENBb6QDUPF0BlNn8',
    ),
  );

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
