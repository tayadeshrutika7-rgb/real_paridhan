import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/supabase_client.dart';
import '../domain/user_profile.dart';

class AuthState {
  final bool isLoading;
  final bool isGuest;
  final UserProfile? user;
  final String? errorMessage;

  const AuthState({
    this.isLoading = false,
    this.isGuest = true,
    this.user,
    this.errorMessage,
  });

  bool get isAuthenticated => user != null && !isGuest;

  AuthState copyWith({
    bool? isLoading,
    bool? isGuest,
    UserProfile? user,
    String? errorMessage,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isGuest: isGuest ?? this.isGuest,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _initAuthListener();
    return const AuthState(isGuest: true);
  }

  void _initAuthListener() {
    final client = SupabaseService.client;
    if (client == null) {
      return;
    }

    final currentSession = client.auth.currentSession;
    if (currentSession != null) {
      _loadProfile(currentSession.user.id);
    }

    client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        _loadProfile(session.user.id);
      } else {
        state = const AuthState(isGuest: true);
      }
    });
  }

  Future<void> _loadProfile(String userId) async {
    final client = SupabaseService.client;
    if (client == null) return;

    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        final profile = UserProfile.fromJson(response);
        state = state.copyWith(user: profile, isGuest: false, clearError: true);
      } else {
        // Self-heal: auth.users record exists but public.profiles row is missing
        final authUser = client.auth.currentUser;
        if (authUser != null && authUser.id == userId) {
          final meta = authUser.userMetadata ?? {};
          final roleStr = (meta['role'] as String?)?.toLowerCase() ?? 'consumer';
          final parsedRole = UserRole.values.firstWhere(
            (r) => r.name.toLowerCase() == roleStr,
            orElse: () => UserRole.consumer,
          );
          final fullName = meta['full_name'] as String? ?? (authUser.email?.split('@').first ?? 'User');
          final phone = meta['phone'] as String?;
          final profileMap = <String, dynamic>{
            'id': userId,
            'role': parsedRole.name,
            'full_name': fullName,
            'email': authUser.email?.toLowerCase().trim(),
            if (phone != null) 'phone': phone,
            'accepted_terms_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          };
          try {
            final inserted = await client.from('profiles').upsert(profileMap).select().maybeSingle();
            if (inserted != null) {
              final profile = UserProfile.fromJson(inserted);
              state = state.copyWith(user: profile, isGuest: false, clearError: true);
            }
          } catch (insertErr) {
            debugPrint('[AuthNotifier] Failed to self-heal profile: $insertErr');
          }
        }
      }
    } catch (e) {
      debugPrint('[AuthNotifier] Error loading profile: $e');
    }
  }

  void continueAsGuest() {
    state = const AuthState(isGuest: true, user: null, errorMessage: null);
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final normalizedEmail = email.trim().toLowerCase();
    final client = SupabaseService.client;

    if (client == null) {
      // Offline/Mock test simulation: role mapping based on email
      await Future.delayed(const Duration(milliseconds: 300));
      UserRole role = UserRole.consumer;
      String name = 'Aarav Sharma';
      String phone = '+91 98290 12345';

      final normalized = normalizedEmail;
      if (normalized.contains('seller')) {
        role = UserRole.seller;
        name = 'Jaipur Heritage Handlooms';
        phone = '+91 98290 54321';
      } else if (normalized.contains('delivery') || normalized.contains('driver')) {
        role = UserRole.delivery;
        name = 'Ramesh Singh (Fleet Rider)';
        phone = '+91 98765 43210';
      } else if (normalized.contains('admin')) {
        role = UserRole.admin;
        name = 'Paridhan Administrator';
        phone = '+91 99999 00000';
      }

      final mockUser = UserProfile(
        id: 'user-${role.name}-01',
        role: role,
        fullName: name,
        email: normalizedEmail,
        phone: phone,
        acceptedTermsAt: DateTime.now(),
      );
      state = AuthState(isLoading: false, isGuest: false, user: mockUser);
      return true;
    }

    try {
      final res = await client.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );
      if (res.user != null) {
        await _loadProfile(res.user!.id);
        state = state.copyWith(isLoading: false);
        return true;
      }
      state = state.copyWith(isLoading: false, errorMessage: 'Invalid email or password.');
      return false;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _formatAuthError(e));
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _formatAuthError(e));
      return false;
    }
  }

  Future<bool> quickLoginAs(UserRole role) async {
    switch (role) {
      case UserRole.admin:
        return signInWithEmail(email: 'admin@paridhan.com', password: 'password123');
      case UserRole.seller:
        return signInWithEmail(email: 'seller3@gm.com', password: 'seller3@gm.com');
      case UserRole.delivery:
        return signInWithEmail(email: 'delivery1@gm.com', password: 'delivery1@gm.com');
      case UserRole.consumer:
        return signInWithEmail(email: 'buyer1@gm.com', password: 'buyer1@gm.com');
    }
  }

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    required bool acceptedTerms,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final normalizedEmail = email.trim().toLowerCase();
    final cleanFullName = fullName.trim();
    final client = SupabaseService.client;

    if (client == null) {
      await Future.delayed(const Duration(milliseconds: 300));
      final mockUser = UserProfile(
        id: 'user-${role.name}-${DateTime.now().millisecondsSinceEpoch}',
        role: role,
        fullName: cleanFullName,
        email: normalizedEmail,
        acceptedTermsAt: acceptedTerms ? DateTime.now() : null,
      );
      state = AuthState(isLoading: false, isGuest: false, user: mockUser);
      return true;
    }

    try {
      final res = await client.auth.signUp(
        email: normalizedEmail,
        password: password,
        data: {
          'full_name': cleanFullName,
          'role': role.name,
          'accepted_terms': acceptedTerms,
        },
      );
      if (res.user != null) {
        // Obfuscated duplicate signup check: Supabase returns user with empty identities when already registered
        if (res.user!.identities != null && res.user!.identities!.isEmpty) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'An account with this email address already exists. Please Sign In.',
          );
          return false;
        }

        if (res.session != null) {
          await _loadProfile(res.user!.id);
          state = state.copyWith(isLoading: false);
          return true;
        } else {
          // If email confirmation is enabled in Supabase, session is null until confirmed
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'Account created! If email confirmation is enabled in Supabase, please check your inbox to confirm before signing in.',
          );
          return false;
        }
      }
      state = state.copyWith(isLoading: false, errorMessage: 'Sign up failed. Please try again.');
      return false;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _formatAuthError(e));
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _formatAuthError(e));
      return false;
    }
  }

  String _formatAuthError(dynamic e) {
    final str = e.toString().toLowerCase();
    if (str.contains('profiles_phone_key') || (str.contains('phone') && (str.contains('unique') || str.contains('duplicate')))) {
      return 'A user with this phone number already exists.';
    }
    if (str.contains('unable to validate email') || str.contains('invalid format') || str.contains('invalid email')) {
      return 'Invalid email address format. Please enter a complete email address including domain (e.g., seller@example.com).';
    }
    if (str.contains('error sending confirmation email') || str.contains('unexpected_failure')) {
      return 'Supabase cannot send confirmation emails (rate limit or unconfigured SMTP).\nFix: In Supabase Dashboard ➔ Authentication ➔ Providers ➔ Email ➔ Turn OFF "Confirm email".';
    }
    if (str.contains('invalid login credentials') || str.contains('invalid_credentials')) {
      return 'Invalid email or password. Please check your credentials and try again.';
    }
    if (str.contains('user already registered') || str.contains('user_already_exists') || str.contains('email_exists') || str.contains('already been registered') || str.contains('already registered')) {
      return 'An account with this email address already exists. Please Sign In.';
    }
    if (str.contains('network') || str.contains('socketexception') || str.contains('connection')) {
      return 'Network connection error. Please check your internet connection and try again.';
    }
    return e is AuthException ? e.message : e.toString();
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final normalizedEmail = email.trim().toLowerCase();
    final client = SupabaseService.client;

    if (client == null) {
      await Future.delayed(const Duration(milliseconds: 300));
      state = state.copyWith(isLoading: false);
      return true;
    }

    try {
      await client.auth.resetPasswordForEmail(normalizedEmail);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _formatAuthError(e));
      return false;
    }
  }

  Future<bool> updateProfile({
    required String fullName,
    required String phone,
    String? avatarUrl,
  }) async {
    if (state.user == null) return false;
    state = state.copyWith(isLoading: true, clearError: true);

    final updated = state.user!.copyWith(
      fullName: fullName,
      phone: phone,
      avatarUrl: avatarUrl ?? state.user!.avatarUrl,
    );

    final client = SupabaseService.client;
    if (client != null && !state.user!.id.startsWith('guest')) {
      try {
        await client.from('profiles').update({
          'full_name': fullName,
          'phone': phone,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', updated.id);
      } catch (e) {
        debugPrint('[AuthNotifier] Error updating profile: $e');
      }
    }
    state = state.copyWith(isLoading: false, user: updated);
    return true;
  }

  Future<void> acceptTerms() async {
    if (state.user == null) return;
    final updated = state.user!.copyWith(acceptedTermsAt: DateTime.now());
    state = state.copyWith(user: updated);

    final client = SupabaseService.client;
    if (client != null) {
      try {
        await client
            .from('profiles')
            .update({'accepted_terms_at': DateTime.now().toIso8601String()})
            .eq('id', updated.id);
      } catch (e) {
        debugPrint('[AuthNotifier] Error updating accepted_terms_at: $e');
      }
    }
  }

  Future<void> signOut() async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        await client.auth.signOut();
      } catch (e) {
        debugPrint('[AuthNotifier] Error signing out: $e');
      }
    }
    state = const AuthState(isGuest: true, user: null);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
