import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/delivery_earnings_model.dart';
import 'delivery_controller.dart';

class DeliveryEarningsScreen extends ConsumerWidget {
  const DeliveryEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveryState = ref.watch(deliveryProvider);
    final earnings = deliveryState.earnings;
    final timeFormat = DateFormat('hh:mm a');
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings & COD Settlement'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Earnings Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Today\'s Net Payout',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      if (earnings.todayPenalties > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            '-₹${earnings.todayPenalties.toStringAsFixed(0)} Penalty',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${earnings.todayNetEarnings.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _EarningsMiniStat(
                        label: 'Base Pay',
                        value: '₹${earnings.todayBaseEarnings.toStringAsFixed(0)}',
                      ),
                      _EarningsMiniStat(
                        label: 'Bonus',
                        value: '₹${earnings.todayDistanceIncentive.toStringAsFixed(0)}',
                      ),
                      _EarningsMiniStat(
                        label: 'Tips',
                        value: '₹${earnings.todayTips.toStringAsFixed(0)}',
                      ),
                      if (earnings.todayPenalties > 0)
                        _EarningsMiniStat(
                          label: 'Penalties',
                          value: '-₹${earnings.todayPenalties.toStringAsFixed(0)}',
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Monthly Salary Ledger Status Card (Credited vs Pending)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: earnings.isSalaryCredited ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: earnings.isSalaryCredited ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            earnings.isSalaryCredited ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
                            color: earnings.isSalaryCredited ? AppTheme.successColor : const Color(0xFFD97706),
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${earnings.monthlySalaryMonth} Salary',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: earnings.isSalaryCredited ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: earnings.isSalaryCredited ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
                          ),
                        ),
                        child: Text(
                          earnings.isSalaryCredited ? 'CREDITED 💰' : 'PENDING ⏳',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: earnings.isSalaryCredited ? const Color(0xFF15803D) : const Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            earnings.isSalaryCredited ? 'Settled Salary Amount' : 'Accrued Monthly Earnings',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${earnings.monthlySalaryAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: earnings.isSalaryCredited ? AppTheme.successColor : const Color(0xFF92400E),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${earnings.todayTripsCount} Trips Tracked',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  if (earnings.isSalaryCredited) ...[
                    if (earnings.monthlySalaryRef != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Text('Transaction UTR / Ref: ', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            Text(
                              earnings.monthlySalaryRef!,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    if (earnings.monthlySalaryMethod != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Text('Disbursed Via: ', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            Text(
                              earnings.monthlySalaryMethod!,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    if (earnings.monthlySalaryPaidAt != null)
                      Row(
                        children: [
                          const Text('Credited Date: ', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          Text(
                            DateFormat('dd MMM yyyy, hh:mm a').format(earnings.monthlySalaryPaidAt!),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                  ] else ...[
                    const Text(
                      'Your per-order earnings are actively computed and credited directly to your verified bank account / UPI at the monthly payout cycle.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // COD Cash Held & Remittance Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: earnings.pendingCodRemittance > 0 ? Colors.amber.shade400 : AppTheme.borderSubtle,
                  width: earnings.pendingCodRemittance > 0 ? 1.5 : 1.0,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.account_balance_wallet, color: Colors.amber, size: 22),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cash on Delivery (COD) Held',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Text(
                                'Physical cash collected from customers',
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: earnings.pendingCodRemittance > 0 ? Colors.amber.shade100 : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            earnings.pendingCodRemittance > 0 ? 'Remittance Due' : 'All Settled',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: earnings.pendingCodRemittance > 0 ? Colors.amber.shade900 : Colors.green.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Three-column breakdown of COD metrics
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Collected', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                              const SizedBox(height: 2),
                              Text('₹${earnings.todayCodCollected.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                            ],
                          ),
                          Container(width: 1, height: 28, color: const Color(0xFFCBD5E1)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Remitted to Admin', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                              const SizedBox(height: 2),
                              Text('₹${earnings.totalCodRemitted.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                            ],
                          ),
                          Container(width: 1, height: 28, color: const Color(0xFFCBD5E1)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Pending with You', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                              const SizedBox(height: 2),
                              Text(
                                '₹${earnings.pendingCodRemittance.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: earnings.pendingCodRemittance > 0 ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    if (earnings.pendingCodRemittance > 0) ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showRemitCashModal(context, ref, earnings),
                          icon: const Icon(Icons.send_to_mobile, size: 18),
                          label: Text(
                            'Payback / Remit Cash to Admin (₹${earnings.pendingCodRemittance.toStringAsFixed(0)})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ] else if (earnings.todayCodCollected > 0) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.check_circle, size: 16, color: Colors.green.shade600),
                          const SizedBox(width: 6),
                          const Text(
                            'All collected cash has been remitted to Admin.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF16A34A), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            if (earnings.todayPenalties > 0) ...[
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.red.shade300, width: 1.2),
                ),
                color: Colors.red.shade50.withValues(alpha: 0.5),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 22),
                          const SizedBox(width: 8),
                          const Text(
                            'Platform Penalties Charged',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const Spacer(),
                          Text(
                            '-₹${earnings.todayPenalties.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Charged for ${earnings.penaltiesCount} emergency cancellation(s) at ₹100 per rejected trip.',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      ...earnings.penalties.map((pen) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pen.orderNumber,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    Text(
                                      '${pen.reason} • ${timeFormat.format(pen.chargedAt)}',
                                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                    ),
                                  ],
                                ),
                                Text(
                                  '-₹${pen.amount.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Key Stats
            Row(
              children: [
                Expanded(
                  child: _SummaryBox(
                    icon: Icons.delivery_dining,
                    label: 'Trips Completed',
                    value: '${earnings.todayTripsCount}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryBox(
                    icon: Icons.route_outlined,
                    label: 'Distance Covered',
                    value: '${earnings.totalDistanceTodayKm.toStringAsFixed(1)} km',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Trip History Section
            Text('Trip History', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),

            if (earnings.trips.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text('No trips completed yet today.', style: TextStyle(color: AppTheme.textSecondary)),
                ),
              )
            else
              ...earnings.trips.map((trip) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(trip.orderNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text(
                                '+₹${trip.payout.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.successColor,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.store, size: 14, color: AppTheme.textMuted),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  trip.shopName,
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: AppTheme.textMuted),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  trip.dropArea,
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${trip.distanceKm} km • ${timeFormat.format(trip.completedAt)}',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                              ),
                              if (trip.isCod)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'COD: ₹${trip.codAmount.toStringAsFixed(0)}',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )),

            const SizedBox(height: 24),

            // COD Remittance History Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('COD Remittance & Admin Payback History', style: Theme.of(context).textTheme.headlineSmall),
                if (earnings.remittances.isNotEmpty)
                  Text(
                    '${earnings.remittances.length} submission(s)',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Audit log of customer cash deposits remitted back to Paridhan Platform Admin.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 12),

            if (earnings.remittances.isEmpty)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.history_toggle_off, color: AppTheme.textMuted, size: 36),
                        SizedBox(height: 8),
                        Text(
                          'No COD remittances submitted yet.',
                          style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Collected cash deposited with Admin will appear here with live verification status.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ...earnings.remittances.map((rem) {
                final isVerified = rem.isVerified;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isVerified ? const Color(0xFFBBF7D0) : const Color(0xFFFEF08A),
                      width: 1.2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isVerified ? Icons.check_circle : Icons.hourglass_top,
                                  size: 18,
                                  color: isVerified ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '₹${rem.amount.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isVerified ? const Color(0xFFDCFCE7) : const Color(0xFFFEF9C3),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isVerified ? 'VERIFIED BY ADMIN' : 'AWAITING ADMIN APPROVAL',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isVerified ? const Color(0xFF166534) : const Color(0xFF854D0E),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.account_balance, size: 13, color: AppTheme.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              rem.paymentMethod,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                            const Spacer(),
                            Text(
                              'Ref: ${rem.reference}',
                              style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                        if (rem.notes != null && rem.notes!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Note: ${rem.notes}',
                            style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF64748B)),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Submitted: ${dateFormat.format(rem.createdAt)} at ${timeFormat.format(rem.createdAt)}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            ),
                            if (rem.isSellerPaid)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0E7FF),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Seller Payback Disbursed',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF3730A3)),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showRemitCashModal(BuildContext context, WidgetRef ref, DeliveryEarningsModel earnings) {
    final amountController = TextEditingController(
      text: earnings.pendingCodRemittance > 0 ? earnings.pendingCodRemittance.toStringAsFixed(0) : '0',
    );
    final refController = TextEditingController(
      text: 'COD-REM-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
    );
    final notesController = TextEditingController(text: 'Jaipur COD Orders Cash Settlement');
    String selectedMethod = 'Admin Primary UPI (admin@paridhan.com)';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.send_to_mobile, color: Colors.amber, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Remit COD Cash to Admin',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              Text(
                                'Deposit collected physical cash into platform escrow',
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(modalContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Cash held banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet, color: Color(0xFFB45309)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Pending Physical Cash Held', style: TextStyle(fontSize: 11, color: Color(0xFF92400E))),
                                Text(
                                  '₹${earnings.pendingCodRemittance.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Amount Field
                    const Text('Remittance Amount (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.currency_rupee, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        hintText: 'Enter amount to remit',
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Payment Method Dropdown
                    const Text('Deposit / Payback Destination', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedMethod,
                      isExpanded: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Admin Primary UPI (admin@paridhan.com)',
                          child: Text('Admin Primary UPI (admin@paridhan.com)', style: TextStyle(fontSize: 13)),
                        ),
                        DropdownMenuItem(
                          value: 'Direct Bank IMPS (Paridhan Escrow)',
                          child: Text('Bank IMPS / NEFT (Escrow A/C 9876001234)', style: TextStyle(fontSize: 13)),
                        ),
                        DropdownMenuItem(
                          value: 'Jaipur HQ Cash Hub Handover',
                          child: Text('Cash Handover at Jaipur HQ (Johari Desk)', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedMethod = val);
                      },
                    ),
                    const SizedBox(height: 14),

                    // Reference Number
                    const Text('Transaction UTR / Handover Receipt Ref', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: refController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.receipt_long, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        hintText: 'e.g. UTR12345678 or PRD-COD-REM-01',
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Notes
                    const Text('Remarks / Order Reference', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.note_alt_outlined, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        hintText: 'Optional notes for platform accountant',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Confirm Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final parsedAmount = double.tryParse(amountController.text.trim()) ?? 0.0;
                          if (parsedAmount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a valid amount to remit.')),
                            );
                            return;
                          }

                          Navigator.pop(modalContext);

                          final success = await ref.read(deliveryProvider.notifier).submitCodRemittance(
                            amount: parsedAmount,
                            paymentMethod: selectedMethod,
                            reference: refController.text.trim(),
                            notes: notesController.text.trim(),
                          );

                          if (context.mounted) {
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✅ COD Cash of ₹${parsedAmount.toStringAsFixed(2)} remitted to Admin! Awaiting verification.'),
                                  backgroundColor: const Color(0xFF16A34A),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to submit remittance. Please try again.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Confirm & Payback to Admin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _EarningsMiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _EarningsMiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryBox({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 22),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
