import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import 'auth_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSignUp = false;
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  UserRole _selectedRole = UserRole.consumer;
  bool _acceptedTerms = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_isSignUp && !_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms & Conditions and Privacy Policy to continue.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final authNotifier = ref.read(authProvider.notifier);
    bool success = false;

    if (_isSignUp) {
      success = await authNotifier.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _nameController.text.trim(),
        role: _selectedRole,
        acceptedTerms: _acceptedTerms,
      );
    } else {
      success = await authNotifier.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    }

    if (success && mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Badge
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_mall_outlined, size: 16, color: AppTheme.accentColor),
                            SizedBox(width: 6),
                            Text(
                              AppConstants.tagline,
                              style: TextStyle(
                                color: AppTheme.accentColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isSignUp ? 'Create your Account' : 'Welcome to Paridhan',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isSignUp
                          ? 'Join India\'s hyperlocal fashion marketplace'
                          : 'Sign in to bargain, explore local fashion & track deliveries',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 28),

                    if (authState.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                authState.errorMessage!,
                                style: const TextStyle(color: AppTheme.errorColor, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_isSignUp) ...[
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          hintText: 'e.g. Priya Sharma',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your full name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Role Selector
                      DropdownButtonFormField<UserRole>(
                        initialValue: _selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'I want to join as',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: UserRole.consumer,
                            child: Text('Buyer / Consumer (Shop & Bargain)'),
                          ),
                          DropdownMenuItem(
                            value: UserRole.seller,
                            child: Text('Clothing Seller (Local Boutique)'),
                          ),
                          DropdownMenuItem(
                            value: UserRole.delivery,
                            child: Text('Delivery Partner (Local Fleet)'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedRole = val);
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        hintText: 'name@example.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty || !value.contains('@')) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),

                    if (!_isSignUp) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => context.push('/forgot-password'),
                          child: const Text('Forgot Password?'),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _acceptedTerms,
                            activeColor: AppTheme.primaryColor,
                            onChanged: (val) => setState(() => _acceptedTerms = val ?? false),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Wrap(
                                  children: [
                                    const Text('I agree to the ', style: TextStyle(fontSize: 12)),
                                    InkWell(
                                      onTap: () => context.push('/legal/terms'),
                                      child: const Text(
                                        'Terms of Service',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accentColor),
                                      ),
                                    ),
                                    const Text(' & ', style: TextStyle(fontSize: 12)),
                                    InkWell(
                                      onTap: () => context.push('/legal/privacy'),
                                      child: const Text(
                                        'Privacy Policy',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accentColor),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    const SizedBox(height: 8),

                    ElevatedButton(
                      onPressed: authState.isLoading ? null : _submit,
                      child: authState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(_isSignUp ? 'Create Account' : 'Sign In'),
                    ),

                    const SizedBox(height: 16),

                    // Toggle between Login / Sign Up
                    Center(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _isSignUp = !_isSignUp;
                          });
                        },
                        child: Text(
                          _isSignUp
                              ? 'Already have an account? Sign In'
                              : 'New to Paridhan? Create an Account',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),

                    const Divider(height: 32),

                    // Quick Test Accounts for Developer Evaluation
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.science_outlined, size: 16, color: AppTheme.accentColor),
                              SizedBox(width: 6),
                              Text('1-Tap Test Accounts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ActionChip(
                                avatar: const Icon(Icons.person, size: 14, color: AppTheme.primaryColor),
                                label: const Text('Buyer / Consumer', style: TextStyle(fontSize: 11)),
                                onPressed: () async {
                                  await ref.read(authProvider.notifier).quickLoginAs(UserRole.consumer);
                                  if (context.mounted) context.go('/');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.store, size: 14, color: AppTheme.secondaryColor),
                                label: const Text('Seller Boutique', style: TextStyle(fontSize: 11)),
                                onPressed: () async {
                                  await ref.read(authProvider.notifier).quickLoginAs(UserRole.seller);
                                  if (context.mounted) context.go('/');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.two_wheeler, size: 14, color: AppTheme.accentColor),
                                label: const Text('Delivery Partner', style: TextStyle(fontSize: 11)),
                                onPressed: () async {
                                  await ref.read(authProvider.notifier).quickLoginAs(UserRole.delivery);
                                  if (context.mounted) context.go('/');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.admin_panel_settings, size: 14, color: Colors.purple),
                                label: const Text('Admin', style: TextStyle(fontSize: 11)),
                                onPressed: () async {
                                  await ref.read(authProvider.notifier).quickLoginAs(UserRole.admin);
                                  if (context.mounted) context.go('/');
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Guest Browsing Mode CTA
                    OutlinedButton.icon(
                      onPressed: () {
                        ref.read(authProvider.notifier).continueAsGuest();
                        context.go('/');
                      },
                      icon: const Icon(Icons.explore_outlined),
                      label: const Text('Continue as Guest'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
