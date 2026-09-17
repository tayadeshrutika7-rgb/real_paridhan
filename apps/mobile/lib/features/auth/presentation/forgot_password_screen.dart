import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import 'auth_state.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(authProvider.notifier)
        .sendPasswordResetEmail(_emailController.text.trim());

    if (success && mounted) {
      setState(() {
        _emailSent = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _emailSent
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.mark_email_read_outlined, size: 64, color: AppTheme.successColor),
                        const SizedBox(height: 16),
                        Text('Reset Link Sent', style: Theme.of(context).textTheme.displayMedium),
                        const SizedBox(height: 8),
                        Text(
                          'We sent instructions to ${_emailController.text}. Please check your inbox.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => context.pop(),
                          child: const Text('Return to Login'),
                        ),
                      ],
                    )
                  : Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(Icons.lock_reset, size: 56, color: AppTheme.primaryColor),
                          const SizedBox(height: 16),
                          Text(
                            'Forgot your Password?',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.displayMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter your registered email address and we will send you a link to reset your password.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              hintText: 'name@example.com',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty || !val.contains('@')) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: authState.isLoading ? null : _handleReset,
                            child: authState.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Send Reset Link'),
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
