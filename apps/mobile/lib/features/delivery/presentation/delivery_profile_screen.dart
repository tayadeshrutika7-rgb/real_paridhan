import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/delivery_profile_model.dart';
import 'delivery_controller.dart';

class DeliveryProfileScreen extends ConsumerStatefulWidget {
  const DeliveryProfileScreen({super.key});

  @override
  ConsumerState<DeliveryProfileScreen> createState() => _DeliveryProfileScreenState();
}

class _DeliveryProfileScreenState extends ConsumerState<DeliveryProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _vehicleTypeController;
  late TextEditingController _vehicleNumberController;
  late TextEditingController _dlNumberController;
  late TextEditingController _dlUrlController;
  late TextEditingController _bankNameController;
  late TextEditingController _accountNumberController;
  late TextEditingController _ifscController;
  late TextEditingController _accountHolderController;
  late TextEditingController _upiController;
  late TextEditingController _aadhaarNumberController;
  late TextEditingController _aadhaarUrlController;

  bool _initialized = false;
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final state = ref.read(deliveryProvider);
      final p = state.profile ?? const DeliveryProfileModel(id: '00000000-0000-0000-0000-000000000003');

      _nameController = TextEditingController(text: p.fullName);
      _phoneController = TextEditingController(text: p.phone);
      _vehicleTypeController = TextEditingController(text: p.vehicleType);
      _vehicleNumberController = TextEditingController(text: p.vehicleNumber);
      _dlNumberController = TextEditingController(text: p.drivingLicenseNumber);
      _dlUrlController = TextEditingController(text: p.drivingLicenseUrl);
      _bankNameController = TextEditingController(text: p.bankName);
      _accountNumberController = TextEditingController(text: p.bankAccountNumber);
      _ifscController = TextEditingController(text: p.bankIfsc);
      _accountHolderController = TextEditingController(text: p.bankAccountName);
      _upiController = TextEditingController(text: p.upiId);
      _aadhaarNumberController = TextEditingController(text: p.aadhaarNumber);
      _aadhaarUrlController = TextEditingController(text: p.aadhaarUrl);

      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _vehicleTypeController.dispose();
    _vehicleNumberController.dispose();
    _dlNumberController.dispose();
    _dlUrlController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _accountHolderController.dispose();
    _upiController.dispose();
    _aadhaarNumberController.dispose();
    _aadhaarUrlController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveAndSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final currentProfile = ref.read(deliveryProvider).profile ??
        const DeliveryProfileModel(id: '00000000-0000-0000-0000-000000000003');

    final updated = currentProfile.copyWith(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      vehicleType: _vehicleTypeController.text.trim(),
      vehicleNumber: _vehicleNumberController.text.trim().toUpperCase(),
      drivingLicenseNumber: _dlNumberController.text.trim().toUpperCase(),
      drivingLicenseUrl: _dlUrlController.text.trim(),
      bankName: _bankNameController.text.trim(),
      bankAccountNumber: _accountNumberController.text.trim(),
      bankIfsc: _ifscController.text.trim().toUpperCase(),
      bankAccountName: _accountHolderController.text.trim(),
      upiId: _upiController.text.trim(),
      aadhaarNumber: _aadhaarNumberController.text.trim(),
      aadhaarUrl: _aadhaarUrlController.text.trim(),
      verificationStatus: 'pending', // Resubmission puts profile in pending for Admin
    );

    final success = await ref.read(deliveryProvider.notifier).saveProfileAndKyc(updated);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('KYC Submitted! Super Admin review in progress. You will be able to accept orders once approved.'),
            backgroundColor: AppTheme.primaryColor,
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit KYC details. Please check your network and retry.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deliveryProvider);
    final p = state.profile ?? const DeliveryProfileModel(id: '00000000-0000-0000-0000-000000000003');
    final isVerified = p.isVerified;
    final isPending = p.isPending;
    final isRejected = p.isRejected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rider Profile & KYC'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Status Banner Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isVerified
                      ? const Color(0xFFDCFCE7)
                      : isPending
                          ? const Color(0xFFFEF3C7)
                          : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isVerified
                        ? const Color(0xFF86EFAC)
                        : isPending
                            ? const Color(0xFFFDE68A)
                            : const Color(0xFFFCA5A5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isVerified
                          ? Icons.verified_rounded
                          : isPending
                              ? Icons.hourglass_top_rounded
                              : Icons.cancel_rounded,
                      color: isVerified
                          ? AppTheme.successColor
                          : isPending
                              ? const Color(0xFFB45309)
                              : AppTheme.errorColor,
                      size: 28,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isVerified
                                ? 'KYC Verified & Active'
                                : isPending
                                    ? 'KYC Verification Pending Review'
                                    : 'KYC Verification Rejected',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isVerified
                                  ? AppTheme.successColor
                                  : isPending
                                      ? const Color(0xFFB45309)
                                      : AppTheme.errorColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isVerified
                                ? 'Your profile, vehicle, and bank details are approved. You can accept live delivery trips.'
                                : isPending
                                    ? 'Admin verification is required before you can go online or accept orders.'
                                    : 'Rejection reason: ${p.rejectionReason ?? "Please check and update your details"}.',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. Personal & Vehicle Details Card
              _buildSectionCard(
                title: 'Personal & Vehicle Details',
                icon: Icons.person_pin_rounded,
                iconColor: AppTheme.primaryColor,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name (as on Aadhaar)',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your full name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter phone number' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _vehicleTypeController,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle Type',
                      hintText: 'e.g. Motorcycle (Hero Splendor Plus) or EV Scooter',
                      prefixIcon: Icon(Icons.two_wheeler_outlined),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter vehicle type' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _vehicleNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle Registration Number',
                      hintText: 'e.g. RJ 14 JP 4421',
                      prefixIcon: Icon(Icons.pin_outlined),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter vehicle registration' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _dlNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Driving License Number',
                      hintText: 'e.g. RJ14 20210049281',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter DL number' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _dlUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Driving License Photo URL / Document Link',
                      hintText: 'https://...',
                      prefixIcon: Icon(Icons.link_outlined),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 3. Bank Account & UPI Details Card
              _buildSectionCard(
                title: 'Bank Account & UPI Details',
                icon: Icons.account_balance_outlined,
                iconColor: AppTheme.successColor,
                children: [
                  TextFormField(
                    controller: _accountHolderController,
                    decoration: const InputDecoration(
                      labelText: 'Account Holder Name',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter account holder name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bankNameController,
                    decoration: const InputDecoration(
                      labelText: 'Bank Name & Branch',
                      hintText: 'e.g. HDFC Bank, Johari Bazaar',
                      prefixIcon: Icon(Icons.account_balance),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter bank name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _accountNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Bank Account Number',
                      prefixIcon: Icon(Icons.credit_card_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter account number' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _ifscController,
                    decoration: const InputDecoration(
                      labelText: 'IFSC Code',
                      hintText: 'e.g. HDFC0001234',
                      prefixIcon: Icon(Icons.numbers_outlined),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter IFSC code' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _upiController,
                    decoration: const InputDecoration(
                      labelText: 'Instant Payout UPI ID',
                      hintText: 'e.g. rider@okhdfcbank or 9829033333@upi',
                      prefixIcon: Icon(Icons.qr_code_scanner_outlined),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter UPI ID' : null,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 4. Aadhaar Details Card
              _buildSectionCard(
                title: 'Aadhaar Verification',
                icon: Icons.fingerprint_rounded,
                iconColor: Colors.deepOrange,
                children: [
                  TextFormField(
                    controller: _aadhaarNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Aadhaar Number (12 Digits)',
                      hintText: '12-digit Aadhaar number',
                      prefixIcon: Icon(Icons.fingerprint),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 12,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Please enter Aadhaar number';
                      if (v.trim().length != 12) return 'Aadhaar must be 12 digits';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _aadhaarUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Aadhaar Photo / Doc Link',
                      hintText: 'https://... link to Aadhaar card image',
                      prefixIcon: Icon(Icons.photo_outlined),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Save & Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _handleSaveAndSubmit,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.cloud_upload_outlined),
                  label: Text(
                    _isSaving ? 'Submitting to Admin...' : 'Save & Submit KYC for Admin Verification',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              const Center(
                child: Text(
                  '🔒 Strictly encrypted. Admin verifies bank and identity before granting order access.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}
