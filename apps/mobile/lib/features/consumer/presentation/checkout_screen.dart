import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_state.dart';
import '../domain/address_model.dart';
import '../domain/order_model.dart';
import 'cart_controller.dart';
import 'order_controller.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        ref.read(orderProvider.notifier).loadAddresses(user.id);
      }
    });
  }

  void _showAddAddressSheet(BuildContext context, String userId) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final line1Ctrl = TextEditingController();
    final line2Ctrl = TextEditingController();
    final landmarkCtrl = TextEditingController();
    final pinCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
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
              Text('Add Delivery Address', style: Theme.of(ctx).textTheme.headlineSmall),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Recipient Full Name *', prefixIcon: Icon(Icons.person_outline)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Contact Phone Number *', prefixIcon: Icon(Icons.phone_outlined)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: line1Ctrl,
                decoration: const InputDecoration(labelText: 'Flat / House No. / Building / Street *', prefixIcon: Icon(Icons.home_outlined)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: line2Ctrl,
                decoration: const InputDecoration(labelText: 'Area / Colony / Sector', prefixIcon: Icon(Icons.location_city_outlined)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: landmarkCtrl,
                      decoration: const InputDecoration(labelText: 'Landmark', prefixIcon: Icon(Icons.near_me_outlined)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: pinCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'PIN Code *', prefixIcon: Icon(Icons.pin_drop_outlined)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty || line1Ctrl.text.isEmpty || pinCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Please fill all required address fields (*)')),
                      );
                      return;
                    }

                    final newAddr = AddressModel(
                      id: 'addr-${DateTime.now().millisecondsSinceEpoch}',
                      userId: userId,
                      fullName: nameCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      addressLine1: line1Ctrl.text.trim(),
                      addressLine2: line2Ctrl.text.trim().isNotEmpty ? line2Ctrl.text.trim() : null,
                      landmark: landmarkCtrl.text.trim(),
                      pincode: pinCtrl.text.trim(),
                      isDefault: true,
                    );

                    await ref.read(orderProvider.notifier).saveAddress(newAddr);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Save & Use Address'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handlePlaceOrder() async {
    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user == null || authState.isGuest) {
      context.push('/login');
      return;
    }

    final cartState = ref.read(cartProvider);
    if (cartState.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your bag is empty.')),
      );
      return;
    }

    const deliveryFee = 49.0;
    const platformFee = 10.0;
    final total = cartState.subtotal + deliveryFee + platformFee;

    final order = await ref.read(orderProvider.notifier).placeOrder(
          consumerId: user.id,
          cartItems: cartState.items,
          subtotal: cartState.subtotal,
          deliveryFee: deliveryFee,
          platformFee: platformFee,
          totalAmount: total,
        );

    if (order != null && mounted) {
      ref.read(cartProvider.notifier).clearCart();
      context.pushReplacement('/order/${order.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final orderState = ref.watch(orderProvider);
    final authState = ref.watch(authProvider);
    final userId = authState.user?.id ?? '';

    const deliveryFee = 49.0;
    const platformFee = 10.0;
    final total = cartState.subtotal + deliveryFee + platformFee;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout Summary'),
      ),
      body: cartState.items.isEmpty
          ? const Center(child: Text('Your shopping bag is empty.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Delivery Address Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Delivery Address', style: Theme.of(context).textTheme.headlineSmall),
                      TextButton.icon(
                        onPressed: () => _showAddAddressSheet(context, userId),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add New'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (orderState.addresses.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Icon(Icons.location_off_outlined, size: 36, color: AppTheme.textMuted),
                            const SizedBox(height: 8),
                            const Text('No saved address found', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: () => _showAddAddressSheet(context, userId),
                              child: const Text('Add Address'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...orderState.addresses.map((addr) {
                      final isSelected = addr.id == orderState.selectedAddress?.id;
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected ? AppTheme.accentColor : AppTheme.borderSubtle,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: InkWell(
                          onTap: () => ref.read(orderProvider.notifier).selectAddress(addr),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                  color: isSelected ? AppTheme.accentColor : AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(addr.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppTheme.surfaceColor,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(addr.phone, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        addr.formattedAddress,
                                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 24),

                  // Payment Method Section
                  Text('Payment Method', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),

                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: orderState.selectedPaymentMethod == PaymentMethod.razorpay
                            ? AppTheme.primaryColor
                            : AppTheme.borderSubtle,
                        width: orderState.selectedPaymentMethod == PaymentMethod.razorpay ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      onTap: () => ref.read(orderProvider.notifier).setPaymentMethod(PaymentMethod.razorpay),
                      leading: const Icon(Icons.payment, color: AppTheme.primaryColor),
                      title: const Text('Online Payment (UPI, Cards, NetBanking)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('Razorpay Route Instant Boutique Split', style: TextStyle(fontSize: 12)),
                      trailing: Icon(
                        orderState.selectedPaymentMethod == PaymentMethod.razorpay
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: orderState.selectedPaymentMethod == PaymentMethod.razorpay
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: orderState.selectedPaymentMethod == PaymentMethod.cod
                            ? AppTheme.primaryColor
                            : AppTheme.borderSubtle,
                        width: orderState.selectedPaymentMethod == PaymentMethod.cod ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      onTap: () => ref.read(orderProvider.notifier).setPaymentMethod(PaymentMethod.cod),
                      leading: const Icon(Icons.money, color: AppTheme.successColor),
                      title: const Text('Cash on Delivery (COD)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('Pay with cash or UPI on delivery', style: TextStyle(fontSize: 12)),
                      trailing: Icon(
                        orderState.selectedPaymentMethod == PaymentMethod.cod
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: orderState.selectedPaymentMethod == PaymentMethod.cod
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Order Items Overview
                  Text('Items in Order (${cartState.totalItems})', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),

                  ...cartState.items.map((item) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item.imageUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.checkroom),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.productTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Text('${item.size} • ${item.color} • Qty: ${item.quantity}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Text('₹${item.totalPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      )),

                  const SizedBox(height: 24),

                  // Bill Breakdown
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Bill Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),
                          _PriceRow(label: 'Item Subtotal', value: '₹${cartState.subtotal.toStringAsFixed(2)}'),
                          const SizedBox(height: 6),
                          const _PriceRow(label: 'Hyperlocal Local Delivery (5-10km)', value: '₹49.00'),
                          const SizedBox(height: 6),
                          const _PriceRow(label: 'Platform & Handling Fee', value: '₹10.00'),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Grand Total', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                              Text(
                                '₹${total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
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
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.borderSubtle)),
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: orderState.isLoading ? null : _handlePlaceOrder,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: orderState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'Place Order • ₹${total.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;

  const _PriceRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
      ],
    );
  }
}
