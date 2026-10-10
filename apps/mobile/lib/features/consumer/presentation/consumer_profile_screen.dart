import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/domain/user_profile.dart';
import '../../auth/presentation/auth_state.dart';
import '../domain/address_model.dart';
import 'order_controller.dart';
import 'cart_controller.dart';
import 'wishlist_controller.dart';

class ConsumerProfileScreen extends ConsumerStatefulWidget {
  const ConsumerProfileScreen({super.key});

  @override
  ConsumerState<ConsumerProfileScreen> createState() => _ConsumerProfileScreenState();
}

class _ConsumerProfileScreenState extends ConsumerState<ConsumerProfileScreen> {
  String _selectedLanguage = 'English';

  final List<String> _presetAvatars = [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
    'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
    'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=200',
    'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=200',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      ref.read(orderProvider.notifier).loadAddresses(user?.id ?? '');
    });
  }

  void _showEditProfileDialog(BuildContext context, UserProfile user) {
    final nameCtrl = TextEditingController(text: user.fullName ?? '');
    final phoneCtrl = TextEditingController(text: user.phone ?? '');
    String selectedAvatar = user.avatarUrl ?? _presetAvatars.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Edit Profile Information', style: Theme.of(ctx).textTheme.headlineSmall),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Choose Profile Avatar', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _presetAvatars.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final url = _presetAvatars[i];
                      final isSelected = selectedAvatar == url;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedAvatar = url),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundImage: NetworkImage(url),
                            ),
                            if (isSelected)
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.primaryColor, width: 3),
                                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                ),
                                child: const Icon(Icons.check, color: Colors.white, size: 24),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'e.g. Priya Sharma',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+91 98290 12345',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  initialValue: user.email ?? '',
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Email Address (Verified)',
                    prefixIcon: const Icon(Icons.email_outlined),
                    suffixIcon: const Icon(Icons.verified, color: Colors.green, size: 18),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter your full name')),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    final success = await ref.read(authProvider.notifier).updateProfile(
                          fullName: nameCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          avatarUrl: selectedAvatar,
                        );
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profile updated successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCustomerCareSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.headset_mic_rounded, color: AppTheme.primaryColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Customer Support', style: Theme.of(ctx).textTheme.headlineSmall),
                        const Text('We are here to help you 24x7', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(height: 28),
            _buildContactOption(
              icon: Icons.phone_in_talk,
              color: Colors.green,
              title: 'Call Toll-Free Care',
              subtitle: '1800-266-9900 (9 AM - 9 PM)',
              actionText: 'Call Now',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Calling Paridhan Customer Care: 1800-266-9900')),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildContactOption(
              icon: Icons.chat_bubble_outline,
              color: const Color(0xFF25D366),
              title: 'WhatsApp Instant Support',
              subtitle: '+91 98290 12345 (Amravati Desk)',
              actionText: 'Chat Now',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Connecting to WhatsApp Support (+91 98290 12345)...')),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildContactOption(
              icon: Icons.mail_outline,
              color: AppTheme.accentColor,
              title: 'Email Support Team',
              subtitle: 'support@paridhan.in (Reply in 2 hours)',
              actionText: 'Send Email',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening mail client to support@paridhan.in')),
                );
              },
            ),
            const SizedBox(height: 20),
            const Text('Frequently Asked Questions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 10),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('How does Hyperlocal 90-min delivery work?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              children: const [
                Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text(
                    'When you place an order with a local boutique in Amravati, our nearby delivery fleet picks up the handcrafted garment and delivers it to your doorstep within 90 minutes with live GPS OTP tracking.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('How does Direct Bargaining work?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              children: const [
                Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text(
                    'You can submit counter-offers directly to boutique owners. Once the seller accepts your price, the item is instantly added to your shopping bag with your negotiated deal locked in for 2 hours!',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Can I return or exchange ethnic clothes?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              children: const [
                Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Yes! Paridhan offers instant doorstep try-and-exchange or 48-hour easy returns directly supported by local boutique partners.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(actionText, style: const TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  void _showAddAddressSheet(BuildContext context, String userId) {
    final current = ref.read(orderProvider).selectedAddress;
    final line1Ctrl = TextEditingController(text: current?.addressLine1 ?? '');
    final line2Ctrl = TextEditingController(text: current?.addressLine2 ?? '');
    final cityCtrl = TextEditingController(
      text: (current?.city != null && current!.city.isNotEmpty) ? current.city : 'Amravati',
    );
    final postalCtrl = TextEditingController(
      text: (current?.pincode != null && current!.pincode.isNotEmpty) ? current.pincode : '444601',
    );

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
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Add Delivery Location', style: Theme.of(ctx).textTheme.headlineSmall),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: line1Ctrl,
                decoration: const InputDecoration(
                  labelText: 'House / Flat No., Street, Landmark *',
                  hintText: 'e.g. Near Rajkamal Chowk, Jawahar Gate',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: line2Ctrl,
                decoration: const InputDecoration(
                  labelText: 'Area / Colony / Locality',
                  hintText: 'e.g. Camp Area / Gadge Nagar',
                  prefixIcon: Icon(Icons.map_outlined),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: cityCtrl,
                      decoration: const InputDecoration(
                        labelText: 'City *',
                        prefixIcon: Icon(Icons.location_city),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: postalCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'PIN Code *',
                        prefixIcon: Icon(Icons.pin_drop_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (line1Ctrl.text.trim().isEmpty || postalCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill all required address fields')),
                    );
                    return;
                  }
                  final user = ref.read(authProvider).user;
                  final effectiveUserId = userId.isNotEmpty ? userId : (user?.id ?? 'default');
                  final newAddr = AddressModel(
                    id: current?.id ?? 'addr-${DateTime.now().millisecondsSinceEpoch}',
                    userId: effectiveUserId,
                    fullName: user?.fullName ?? 'Consumer',
                    phone: user?.phone ?? '+91 98290 11111',
                    addressLine1: line1Ctrl.text.trim(),
                    addressLine2: line2Ctrl.text.trim().isNotEmpty ? line2Ctrl.text.trim() : null,
                    city: cityCtrl.text.trim(),
                    state: current?.state ?? 'Maharashtra',
                    pincode: postalCtrl.text.trim(),
                    isDefault: true,
                  );
                  await ref.read(orderProvider.notifier).saveAddress(newAddr);
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Delivery address saved successfully!'), backgroundColor: Colors.green),
                    );
                  }
                },
                child: const Text('Save Delivery Address'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select App Language', style: Theme.of(ctx).textTheme.headlineSmall),
            const SizedBox(height: 16),
            ...['English', 'हिन्दी (Hindi)', 'मराठी (Marathi)'].map((lang) {
              final isSelected = _selectedLanguage == lang.split(' ').first;
              return ListTile(
                leading: const Icon(Icons.language, color: AppTheme.primaryColor),
                title: Text(lang, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primaryColor) : null,
                onTap: () {
                  setState(() => _selectedLanguage = lang.split(' ').first);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Language switched to $lang')),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showReferAndEarnDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.card_giftcard, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Refer & Earn ₹150'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Invite your friends to shop local fashion on Paridhan! When they complete their first order, you both get ₹150 off on handcrafted apparel.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.borderSubtle),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('PARIDHAN150', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 16)),
                  Icon(Icons.copy, size: 18, color: AppTheme.primaryColor),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Referral link copied to clipboard! Share on WhatsApp.')),
              );
            },
            child: const Text('Share Code'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final orderState = ref.watch(orderProvider);
    final cartState = ref.watch(cartProvider);
    final wishlistState = ref.watch(wishlistProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: const Text('My Account', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.favorite_outline_rounded),
                tooltip: 'My Wishlist',
                onPressed: () => context.push('/wishlist'),
              ),
              if (wishlistState.totalItems > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${wishlistState.totalItems}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined),
                tooltip: 'Shopping Bag',
                onPressed: () => context.push('/cart'),
              ),
              if (cartState.totalItems > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${cartState.totalItems}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. User Profile Header Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 34,
                            backgroundColor: AppTheme.accentLight,
                            backgroundImage: user?.avatarUrl != null
                                ? NetworkImage(user!.avatarUrl!)
                                : const NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200'),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: user != null ? () => _showEditProfileDialog(context, user) : null,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    user?.fullName ?? (authState.isGuest ? 'Guest Shopper' : 'Fashion Consumer'),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.verified, color: Colors.blue, size: 16),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              user?.phone ?? '+91 98290 11111',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            ),
                            if (user?.email != null)
                              Text(
                                user!.email!,
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                      if (user != null)
                        IconButton(
                          icon: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                          onPressed: () => _showEditProfileDialog(context, user),
                        )
                      else
                        ElevatedButton(
                          onPressed: () => context.push('/login'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            minimumSize: Size.zero,
                          ),
                          child: const Text('Sign In', style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 2. Quick Action Cards (Help Centre & Refer)
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _showCustomerCareSheet(context),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.borderSubtle),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.headset_mic_outlined, color: AppTheme.primaryColor, size: 28),
                              SizedBox(height: 8),
                              Text('Help Centre', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('24x7 Customer Care', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => _showReferAndEarnDialog(context),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.borderSubtle),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.card_giftcard, color: AppTheme.secondaryColor, size: 28),
                              SizedBox(height: 8),
                              Text('Refer & Earn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('Get ₹150 Discount', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 3. Section: My Activity & Orders
                _buildSectionTitle('My Activity & Shopping'),
                _buildCardGroup([
                  _buildListTile(
                    icon: Icons.inventory_2_outlined,
                    iconColor: AppTheme.primaryColor,
                    title: 'My Orders',
                    subtitle: 'Track live dispatch, view invoices & delivery OTPs',
                    onTap: () => context.push('/orders'),
                  ),
                  _buildDivider(),
                  _buildListTile(
                    icon: Icons.favorite_outline_rounded,
                    iconColor: AppTheme.primaryColor,
                    title: 'My Wishlist',
                    subtitle: wishlistState.totalItems > 0
                        ? '${wishlistState.totalItems} items saved waiting for discount & price drops'
                        : 'Saved items waiting for discounts & deals',
                    trailingBadge: wishlistState.totalItems > 0 ? '${wishlistState.totalItems}' : null,
                    onTap: () => context.push('/wishlist'),
                  ),
                  _buildDivider(),
                  _buildListTile(
                    icon: Icons.local_offer_outlined,
                    iconColor: AppTheme.secondaryColor,
                    title: 'My Bargains',
                    subtitle: 'Active price counter-offers & accepted boutique deals',
                    onTap: () => context.push('/bargains?seller=false'),
                  ),
                  _buildDivider(),
                  _buildListTile(
                    icon: Icons.location_on_outlined,
                    iconColor: Colors.teal,
                    title: 'Saved Delivery Locations',
                    subtitle: orderState.selectedAddress != null && orderState.selectedAddress!.addressLine1.isNotEmpty
                        ? '${orderState.selectedAddress!.addressLine1}, ${orderState.selectedAddress!.city} (${orderState.selectedAddress!.pincode})'
                        : (orderState.selectedAddress != null
                            ? '${orderState.selectedAddress!.city} (${orderState.selectedAddress!.pincode})'
                            : 'Add home or work delivery address in Amravati'),
                    onTap: () {
                      _showAddAddressSheet(context, user?.id ?? '');
                    },
                  ),
                ]),

                const SizedBox(height: 20),

                // 4. Section: Customer Care & App Settings
                _buildSectionTitle('Customer Support & Settings'),
                _buildCardGroup([
                  _buildListTile(
                    icon: Icons.support_agent,
                    iconColor: Colors.blue,
                    title: 'Customer Care & FAQ',
                    subtitle: 'Contact support on Call, WhatsApp or Email',
                    onTap: () => _showCustomerCareSheet(context),
                  ),
                  _buildDivider(),
                  _buildListTile(
                    icon: Icons.translate,
                    iconColor: Colors.purple,
                    title: 'Change Language',
                    subtitle: _selectedLanguage,
                    onTap: () => _showLanguageSelector(context),
                  ),
                  _buildDivider(),
                  _buildListTile(
                    icon: Icons.storefront_outlined,
                    iconColor: AppTheme.accentColor,
                    title: 'Become a Seller / Boutique Partner',
                    subtitle: 'List your Amravati ethnic boutique & reach local buyers',
                    onTap: () => context.push('/seller/shop'),
                  ),
                ]),

                const SizedBox(height: 20),

                // 5. Section: Legal & Account
                _buildSectionTitle('Legal & Account'),
                _buildCardGroup([
                  _buildListTile(
                    icon: Icons.description_outlined,
                    iconColor: Colors.grey.shade700,
                    title: 'Terms of Service',
                    onTap: () => context.push('/legal/terms'),
                  ),
                  _buildDivider(),
                  _buildListTile(
                    icon: Icons.privacy_tip_outlined,
                    iconColor: Colors.grey.shade700,
                    title: 'Privacy Policy',
                    onTap: () => context.push('/legal/privacy'),
                  ),
                  _buildDivider(),
                  if (authState.isGuest || user == null)
                    _buildListTile(
                      icon: Icons.login_rounded,
                      iconColor: AppTheme.primaryColor,
                      title: 'Sign In / Register',
                      titleColor: AppTheme.primaryColor,
                      subtitle: 'Sign in to access your orders, addresses & negotiated deals',
                      onTap: () => context.push('/login'),
                    )
                  else
                    _buildListTile(
                      icon: Icons.logout,
                      iconColor: AppTheme.errorColor,
                      title: 'Sign Out',
                      titleColor: AppTheme.errorColor,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Sign Out'),
                            content: const Text('Are you sure you want to sign out of Paridhan?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  ref.read(authProvider.notifier).signOut();
                                  context.go('/login');
                                },
                                child: const Text('Sign Out'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ]),

                const SizedBox(height: 28),

                // 6. Clean Footer
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: const Text(
                          'Amravati Hyperlocal Fashion • Maharashtra',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Paridhan App Version 1.0.0 (Amravati Edition)',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondary),
      ),
    );
  }

  Widget _buildCardGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 56, endIndent: 16);
  }

  Widget _buildListTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Color? titleColor,
    String? trailingBadge,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: titleColor ?? AppTheme.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingBadge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                trailingBadge,
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          const Icon(Icons.chevron_right, size: 20, color: AppTheme.textSecondary),
        ],
      ),
      onTap: onTap,
    );
  }
}
