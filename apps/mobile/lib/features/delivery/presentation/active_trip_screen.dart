import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/map_navigation_launcher.dart';
import '../domain/delivery_task_model.dart';
import 'delivery_controller.dart';

class ActiveTripScreen extends ConsumerStatefulWidget {
  final String orderId;

  const ActiveTripScreen({super.key, required this.orderId});

  @override
  ConsumerState<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends ConsumerState<ActiveTripScreen> {
  final _otpController = TextEditingController();
  bool _isSubmitting = false;
  String? _otpError;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _handlePickup(DeliveryTaskModel trip) async {
    final success = await ref.read(deliveryProvider.notifier).confirmStorePickup(trip.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Package picked up! Proceed to customer location.'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  void _showOtpSheet(DeliveryTaskModel trip) {
    _otpController.clear();
    setState(() => _otpError = null);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.verified_outlined, color: AppTheme.primaryColor),
                    SizedBox(width: 8),
                    Text(
                      'Customer Handover OTP',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Ask the customer for their 4-digit Delivery PIN shown on their order tracking screen.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),

                if (trip.isCod) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.payments, color: Colors.amber, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Cash on Delivery (COD)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                'Collect ₹${trip.codCashToCollect.toStringAsFixed(2)} in Cash before handing over package.',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 4,
                  autofocus: true,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 16,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '••••',
                    errorText: _otpError,
                    filled: true,
                    fillColor: AppTheme.surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                      borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                    ),
                  ),
                  onChanged: (val) {
                    if (_otpError != null) {
                      setModalState(() => _otpError = null);
                    }
                  },
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            final code = _otpController.text.trim();
                            if (code.length != 4) {
                              setModalState(() => _otpError = 'Please enter all 4 digits');
                              return;
                            }

                            setState(() => _isSubmitting = true);
                            setModalState(() => _isSubmitting = true);

                            final success = await ref
                                .read(deliveryProvider.notifier)
                                .verifyCustomerOtp(
                                  taskId: trip.id,
                                  orderId: trip.orderId,
                                  otp: code,
                                  isCod: trip.isCod,
                                  codAmount: trip.codCashToCollect,
                                );

                            setState(() => _isSubmitting = false);

                            if (success && mounted) {
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                              }
                              _showSuccessDialog(trip);
                            } else {
                              setModalState(() {
                                _isSubmitting = false;
                                _otpError = 'Incorrect PIN. Check customer app.';
                              });
                            }
                          },
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(_isSubmitting ? 'Verifying...' : 'Complete Delivery'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSuccessDialog(DeliveryTaskModel trip) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.successColor,
              child: Icon(Icons.check, color: Colors.white, size: 36),
            ),
            SizedBox(height: 12),
            Text('Trip Completed! 🎉', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You earned ₹${trip.deliveryPayout.toStringAsFixed(2)} for this delivery.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            if (trip.isCod) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('COD Collected:', style: TextStyle(fontSize: 12)),
                    Text(
                      '₹${trip.codCashToCollect.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/');
              },
              child: const Text('Back to Radar'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deliveryState = ref.watch(deliveryProvider);
    final trip = deliveryState.activeTrip;

    if (trip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Active Delivery')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, size: 64, color: AppTheme.successColor),
              const SizedBox(height: 16),
              const Text('No active trip in progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Go to Duty Radar'),
              ),
            ],
          ),
        ),
      );
    }

    final isPickedUp = trip.status == DeliveryTaskStatus.pickedUp || trip.status == DeliveryTaskStatus.inTransit;

    return Scaffold(
      appBar: AppBar(
        title: Text(trip.orderNumber),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '₹${trip.deliveryPayout.toStringAsFixed(0)} Payout',
                  style: const TextStyle(
                    color: AppTheme.accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Progression Stepper
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _StepCircle(
                        number: '1',
                        label: 'Pickup',
                        isActive: !isPickedUp,
                        isDone: isPickedUp,
                      ),
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isPickedUp ? AppTheme.successColor : Colors.grey.shade300,
                        ),
                      ),
                      _StepCircle(
                        number: '2',
                        label: 'Deliver',
                        isActive: isPickedUp,
                        isDone: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isPickedUp
                        ? 'Heading to Customer Location (${trip.distanceToCustomerKm} km)'
                        : 'Heading to Boutique Store (${trip.distanceToShopKm} km)',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // On-The-Way Order Along Current Path
            if (deliveryState.onTheWayOrder != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.alt_route, size: 13, color: Color(0xFFF59E0B)),
                              SizedBox(width: 4),
                              Text(
                                'ON-THE-WAY ORDER FOUND',
                                style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '+₹${deliveryState.onTheWayOrder!.extraEarnings.toStringAsFixed(0)} Extra',
                          style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      deliveryState.onTheWayOrder!.routeCorridor,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Detour only +${deliveryState.onTheWayOrder!.detourDistanceKm} km • ${deliveryState.onTheWayOrder!.packageLoadSummary}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final extraTask = deliveryState.onTheWayOrder!.tasks.firstWhere(
                            (t) => t.id != trip.id,
                            orElse: () => deliveryState.onTheWayOrder!.tasks.last,
                          );
                          ref.read(deliveryProvider.notifier).acceptIncomingTask(extraTask.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added ${extraTask.orderNumber} to your current route (+₹${extraTask.deliveryPayout.toStringAsFixed(0)})!'),
                              backgroundColor: AppTheme.successColor,
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_shopping_cart, size: 16),
                        label: const Text('Stack Order to Current Route'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Section 1: Pickup Boutique Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.store, color: AppTheme.primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Step 1: Boutique Pickup',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: !isPickedUp ? AppTheme.primaryColor : AppTheme.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        if (isPickedUp)
                          const Chip(
                            label: Text('Picked Up', style: TextStyle(fontSize: 10, color: Colors.white)),
                            backgroundColor: AppTheme.successColor,
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(trip.shopName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(trip.shopAddress, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            MapNavigationLauncher.makePhoneCall(trip.shopPhone, context: context);
                          },
                          icon: const Icon(Icons.call, size: 16),
                          label: const Text('Call Shop'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            MapNavigationLauncher.openGoogleMaps(
                              latitude: trip.shopLat,
                              longitude: trip.shopLng,
                              destinationName: trip.shopName,
                              address: trip.shopAddress,
                              context: context,
                            );
                          },
                          icon: const Icon(Icons.directions, size: 16),
                          label: const Text('Directions (Google Maps)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                    if (!isPickedUp) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _handlePickup(trip),
                          icon: const Icon(Icons.inventory_2_outlined),
                          label: const Text('Confirm Package Picked Up'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Section 2: Drop-off Customer Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: AppTheme.accentColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Step 2: Customer Delivery',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isPickedUp ? AppTheme.accentColor : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(trip.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(trip.dropAddress, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    if (trip.landmark != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.flag_outlined, size: 14, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text('Near ${trip.landmark}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            MapNavigationLauncher.makePhoneCall(trip.customerPhone, context: context);
                          },
                          icon: const Icon(Icons.call, size: 16),
                          label: const Text('Call Customer'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            MapNavigationLauncher.openGoogleMaps(
                              originLatitude: trip.shopLat,
                              originLongitude: trip.shopLng,
                              originName: trip.shopName,
                              latitude: trip.dropLat,
                              longitude: trip.dropLng,
                              destinationName: trip.customerName,
                              address: trip.dropAddress,
                              context: context,
                            );
                          },
                          icon: const Icon(Icons.directions, size: 16),
                          label: const Text('Directions (Shop ➔ Customer)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                    if (isPickedUp) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showOtpSheet(trip),
                          icon: const Icon(Icons.pin_outlined),
                          label: const Text('Enter 4-Digit Handover OTP'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Section 3: Package Items & Order Value
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Package Contents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    ...trip.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('${item.quantity}x ${item.title} (${item.size}, ${item.color})'),
                              ),
                            ],
                          ),
                        )),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Payment Mode:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                        Text(
                          trip.isCod ? 'Cash on Delivery (COD)' : 'Prepaid (Online)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: trip.isCod ? Colors.amber.shade900 : AppTheme.successColor,
                          ),
                        ),
                      ],
                    ),
                    if (trip.isCod) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Cash to Collect:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                          Text(
                            '₹${trip.codCashToCollect.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryColor),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  final String number;
  final String label;
  final bool isActive;
  final bool isDone;

  const _StepCircle({
    required this.number,
    required this.label,
    required this.isActive,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = Colors.grey.shade200;
    Color fg = AppTheme.textSecondary;

    if (isDone) {
      bg = AppTheme.successColor;
      fg = Colors.white;
    } else if (isActive) {
      bg = AppTheme.primaryColor;
      fg = Colors.white;
    }

    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: bg,
          child: isDone
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : Text(number, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: fg)),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive || isDone ? FontWeight.bold : FontWeight.normal,
            color: isActive || isDone ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
