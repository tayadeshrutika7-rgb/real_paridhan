import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_state.dart';

enum LegalType {
  terms,
  privacy,
}

class LegalScreen extends ConsumerWidget {
  final LegalType type;

  const LegalScreen({
    super.key,
    required this.type,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isTerms = type == LegalType.terms;
    final title = isTerms ? 'Terms of Service' : 'Privacy Policy';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.accentLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Last Updated: September 17, 2026',
                          style: TextStyle(color: AppTheme.accentColor, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isTerms ? 'Paridhan Marketplace Terms' : 'Data Privacy & Protection (DPDP Act 2023)',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isTerms
                            ? 'Welcome to Paridhan ("Wear Local. Support Local."). By using our mobile or web application to browse, negotiate, purchase, or deliver clothing, you agree to comply with our platform policies.\n\n'
                              '1. Real-Time Bargaining: Offers submitted through the bargaining module are binding upon acceptance by the boutique or seller. All offers must respect the minimum floor price set by the seller.\n\n'
                              '2. Hyperlocal Order Fulfillment: Delivery routes and schedules are optimized based on your location. Independent delivery partners collect and remit Cash on Delivery (COD) funds.\n\n'
                              '3. Marketplace Liability: Paridhan connects verified independent boutiques with consumers and provides split-settlement technology via Razorpay Route.\n\n'
                              '4. Dispute Resolution: Complaints and return requests must be filed within 48 hours of delivery receipt through the in-app Returns center.'
                            : 'Paridhan is committed to the protection of your personal and location data under India\'s Digital Personal Data Protection Act, 2023 (DPDP).\n\n'
                              '1. Location Information: We collect your device\'s geographical coordinates exclusively to find fashion shops within your immediate radius and track active deliveries.\n\n'
                              '2. Identity & Contact: Name, phone number, and email address are used to verify accounts, notify you of bargain counters, and send OTPs.\n\n'
                              '3. Payment Information: Card, UPI, and bank details are processed directly by RBI-regulated payment partners (Razorpay). Paridhan never stores raw payment card numbers.\n\n'
                              '4. Your Rights: You have the right to review your data, request corrections, or request deletion of your account and personal history directly in the Settings page.',
                        style: const TextStyle(fontSize: 14, height: 1.6, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (authState.isAuthenticated && !authState.user!.hasAcceptedTerms) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppTheme.borderSubtle)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await ref.read(authProvider.notifier).acceptTerms();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Thank you! Terms accepted.')),
                            );
                            context.pop();
                          }
                        },
                        child: const Text('I Accept the Terms & Policies'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
