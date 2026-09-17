import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/order_model.dart';
import 'order_controller.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderProvider.notifier).loadOrderDetails(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);
    final order = orderState.activeOrder;

    if (orderState.isLoading && order == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Order not found'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      );
    }

    final currentStep = order.statusStepIndex;

    return Scaffold(
      appBar: AppBar(
        title: Text(order.orderNumber),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, Color(0xFF1E2640)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white24,
                    child: Icon(
                      order.status == OrderStatus.delivered
                          ? Icons.check_circle
                          : Icons.local_shipping_outlined,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.statusLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Estimated Delivery: Within 45-60 mins',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Delivery OTP Card (Required for DPDP and secure delivery handover)
            Card(
              color: const Color(0xFFFEF3C7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFFFDE68A)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline, color: AppTheme.secondaryColor, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Delivery Confirmation OTP',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E)),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Share this code with the delivery partner upon arrival',
                            style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFF59E0B)),
                      ),
                      child: Text(
                        order.deliveryOtp,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Live Stepper
            Text('Order Progress', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _StepTile(
                      icon: Icons.receipt_long,
                      title: 'Order Placed',
                      subtitle: 'We received your order',
                      isCompleted: currentStep >= 0,
                      isCurrent: currentStep == 0,
                    ),
                    _StepConnector(isCompleted: currentStep > 0),
                    _StepTile(
                      icon: Icons.storefront,
                      title: 'Boutique Confirmed',
                      subtitle: 'Artisan boutique is packing your garment',
                      isCompleted: currentStep >= 1,
                      isCurrent: currentStep == 1,
                    ),
                    _StepConnector(isCompleted: currentStep > 1),
                    _StepTile(
                      icon: Icons.inventory_2_outlined,
                      title: 'Ready for Pickup',
                      subtitle: 'Waiting for delivery partner assignment',
                      isCompleted: currentStep >= 2,
                      isCurrent: currentStep == 2,
                    ),
                    _StepConnector(isCompleted: currentStep > 2),
                    _StepTile(
                      icon: Icons.two_wheeler,
                      title: 'Out for Delivery',
                      subtitle: 'Partner is on the way to your address',
                      isCompleted: currentStep >= 3,
                      isCurrent: currentStep == 3,
                    ),
                    _StepConnector(isCompleted: currentStep > 3),
                    _StepTile(
                      icon: Icons.task_alt,
                      title: 'Delivered',
                      subtitle: 'Package handed over with OTP verification',
                      isCompleted: currentStep >= 4,
                      isCurrent: currentStep == 4,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Delivery Partner Info (if assigned)
            if (order.deliveryPartnerName != null) ...[
              Text('Delivery Partner', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.accentLight,
                    child: Icon(Icons.delivery_dining, color: AppTheme.accentColor),
                  ),
                  title: Text(order.deliveryPartnerName!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(order.deliveryPartnerPhone ?? '+91 98765 43210', style: const TextStyle(fontSize: 12)),
                  trailing: IconButton(
                    icon: const Icon(Icons.call, color: AppTheme.successColor),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Calling ${order.deliveryPartnerName}...')),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Delivery Address
            Text('Delivery Address', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, color: AppTheme.accentColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order.deliveryAddress.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(order.deliveryAddress.formattedAddress, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Order Summary & Items
            Text('Items in this Order (${order.items.length})', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ...order.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  item.imageUrl,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 40,
                                    height: 40,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.checkroom, size: 18),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.productTitle, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Text('Qty: ${item.quantity} • ${item.size}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                  ],
                                ),
                              ),
                              Text('₹${item.totalPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        )),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Paid', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('₹${order.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primaryColor)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool isCurrent;

  const _StepTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCompleted
        ? AppTheme.primaryColor
        : isCurrent
            ? AppTheme.accentColor
            : Colors.grey.shade400;

    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color.withValues(alpha: isCompleted || isCurrent ? 0.15 : 0.08),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isCompleted || isCurrent ? AppTheme.textPrimary : AppTheme.textMuted,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: isCompleted || isCurrent ? AppTheme.textSecondary : AppTheme.textMuted),
              ),
            ],
          ),
        ),
        if (isCompleted)
          const Icon(Icons.check_circle, size: 16, color: AppTheme.successColor),
      ],
    );
  }
}

class _StepConnector extends StatelessWidget {
  final bool isCompleted;
  const _StepConnector({required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 15),
      height: 20,
      width: 2,
      color: isCompleted ? AppTheme.primaryColor : Colors.grey.shade300,
    );
  }
}
