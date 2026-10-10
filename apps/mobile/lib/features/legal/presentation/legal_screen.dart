import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_state.dart';

enum LegalType {
  terms,
  privacy,
  feeDisclosure,
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
    final String title;
    final String subtitle;
    final String content;

    switch (type) {
      case LegalType.terms:
        title = 'Terms of Service';
        subtitle = 'Paridhan Marketplace Terms';
        content =
            'Welcome to Paridhan ("Wear Local. Support Local."). By using our mobile or web application to browse, negotiate, purchase, or deliver clothing, you agree to comply with our platform policies.\n\n'
            '1. Real-Time Bargaining: Offers submitted through the bargaining module are binding upon acceptance by the boutique or seller. All offers must respect the minimum floor price set by the seller.\n\n'
            '2. Hyperlocal Order Fulfillment: Delivery routes and schedules are optimized based on your location. Independent delivery partners collect and remit Cash on Delivery (COD) funds.\n\n'
            '3. Marketplace Liability: Paridhan connects verified independent boutiques with consumers and provides split-settlement technology via Razorpay Route.\n\n'
            '4. Dispute Resolution: Complaints and return requests must be filed within 48 hours of delivery receipt through the in-app Returns center.';
        break;
      case LegalType.privacy:
        title = 'Data Privacy Policy';
        subtitle = 'Data Privacy & Protection (DPDP Act 2023)';
        content =
            'Paridhan is committed to the protection of your personal and location data under India\'s Digital Personal Data Protection Act, 2023 (DPDP).\n\n'
            '1. Location Information: We collect your device\'s geographical coordinates exclusively to find fashion shops within your immediate radius and track active deliveries.\n\n'
            '2. Identity & Contact: Name, phone number, and email address are used to verify accounts, notify you of bargain counters, and send OTPs.\n\n'
            '3. Payment Information: Card, UPI, and bank details are processed directly by RBI-regulated payment partners (Razorpay). Paridhan never stores raw payment card numbers.\n\n'
            '4. Your Rights: You have the right to review your data, request corrections, or request deletion of your account and personal history directly in the Settings page.';
        break;
      case LegalType.feeDisclosure:
        title = 'Platform Fee & Commission Policy';
        subtitle = 'Transparent Financial Terms & Boutique Settlement Policy';
        content =
            'PARIDHAN TRANSPARENT MARKETPLACE FINANCIAL & COMMISSION DISCLOSURE\n\n'
            '1. Standard Seller Commission (3.0%): Paridhan charges a verified 3.0% marketplace commission exclusively on the merchandise items subtotal for completed orders. This charge covers marketplace hosting, buyer acquisition, PostGIS geolocation matching, AI visual search, and bargaining infrastructure.\n\n'
            '2. Boutique Net Payable (97.0%): 97.0% of the item subtotal is remitted directly to the boutique\'s linked merchant account via Razorpay Route split settlement upon successful customer delivery OTP confirmation.\n\n'
            '3. Customer Platform & Delivery Fees: The customer platform fee (₹10.00) is a consumer convenience charge retained by Paridhan. Delivery fees (₹30–₹49 base) are disbursed directly to independent delivery partners. Boutiques are never charged delivery logistics deductions.\n\n'
            '4. Cancellation & Returns Reconciliation: If an order is cancelled or rejected prior to delivery, ₹0.00 commission is charged and no payout is generated. In case of customer return or refund, platform commission and boutique payout are reversed symmetrically without hidden penalties.\n\n'
            '5. Delivery Partner Penalties: Unexcused emergency delivery cancellations incur a ₹100.00 penalty recorded in delivery partner ledger records.';
        break;
    }

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
                          'Last Updated: October 10, 2026',
                          style: TextStyle(color: AppTheme.accentColor, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        content,
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
