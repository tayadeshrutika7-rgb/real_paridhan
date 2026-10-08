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
    final client = SupabaseService.client;

    if (client == null) {
      // Offline/Mock test simulation: role mapping based on email
      await Future.delayed(const Duration(milliseconds: 300));
      UserRole role = UserRole.consumer;
      String name = 'Aarav Sharma';
      String phone = '+91 98290 12345';

      final normalized = email.toLowerCase().trim();
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
        email: email,
        phone: phone,
        acceptedTermsAt: DateTime.now(),
      );
      state = AuthState(isLoading: false, isGuest: false, user: mockUser);
      return true;
    }

    try {
      final res = await client.auth.signInWithPassword(
        email: email,
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
    final client = SupabaseService.client;

    if (client == null) {
      await Future.delayed(const Duration(milliseconds: 300));
      final mockUser = UserProfile(
        id: 'user-${role.name}-${DateTime.now().millisecondsSinceEpoch}',
        role: role,
        fullName: fullName,
        email: email,
        acceptedTermsAt: acceptedTerms ? DateTime.now() : null,
      );
      state = AuthState(isLoading: false, isGuest: false, user: mockUser);
      return true;
    }

    try {
      final res = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': role.name,
          'accepted_terms': acceptedTerms,
        },
      );
      if (res.user != null) {
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
    final str = e.toString();
    if (str.contains('Error sending confirmation email') || str.contains('unexpected_failure')) {
      return 'Supabase cannot send confirmation emails (rate limit or unconfigured SMTP).\nFix: In Supabase Dashboard ➔ Authentication ➔ Providers ➔ Email ➔ Turn OFF "Confirm email".';
    }
    if (str.contains('Invalid login credentials') || str.contains('invalid_credentials')) {
      return 'Invalid email or password. Please check your credentials and try again.';
    }
    if (str.contains('User already registered') || str.contains('user_already_exists')) {
      return 'An account with this email address already exists. Please Sign In.';
    }
    return e is AuthException ? e.message : str;
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final client = SupabaseService.client;

    if (client == null) {
      await Future.delayed(const Duration(milliseconds: 300));
      state = state.copyWith(isLoading: false);
      return true;
    }

    try {
      await client.auth.resetPasswordForEmail(email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
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
