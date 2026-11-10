import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../models/remittance_model.dart';
import '../../../providers/wallet_provider.dart';
import '../../../services/offramp_service.dart';
import '../../../services/remittance_service.dart';
import '../../../models/offramp_model.dart';

/// Cross-Border Multi-Hop Remittance Modal (Flow 1)
///
/// Integrates backend `/api/v1/remittance` pipeline:
/// Step 1: Initiates on-ramp INR deposit (Transak)
/// Step 2: Auto-routes USDC through Polygon Amoy SCA
/// Step 3: Off-ramps directly into recipient's US Bank Account (Crossmint ACH)
class RemittanceModal extends StatefulWidget {
  const RemittanceModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const RemittanceModal(),
    );
  }

  @override
  State<RemittanceModal> createState() => _RemittanceModalState();
}

class _RemittanceModalState extends State<RemittanceModal> {
  final _amountController = TextEditingController(text: '5000');
  final _nameController = TextEditingController(text: 'John Smith');
  final _emailController = TextEditingController(text: 'john.smith@example.com');
  final _routingController = TextEditingController(text: '021000021');
  final _accountController = TextEditingController(text: '123456789');
  final _bankNameController = TextEditingController(text: 'Chase Bank');

  final RemittanceService _remittanceService = RemittanceService();
  final OfframpService _offrampService = OfframpService();

  bool _isInitiating = false;
  String? _errorMessage;
  RemittanceModel? _activeRemittance;
  int _activeStep = 0;

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _routingController.dispose();
    _accountController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  Future<void> _startRemittance() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount < 500) {
      setState(() => _errorMessage = 'Minimum remittance amount is ₹500');
      return;
    }

    final walletProvider = context.read<WalletProvider>();
    final walletId = walletProvider.walletId;

    if (walletId.isEmpty) {
      setState(() => _errorMessage = 'Wallet not provisioned yet. Please wait...');
      return;
    }

    setState(() {
      _isInitiating = true;
      _errorMessage = null;
    });

    try {
      // 1. Create or ensure recipient Crossmint offramp payment method exists
      final paymentMethod = await _offrampService.createPaymentMethod(
        beneficiary: Beneficiary(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          address: BeneficiaryAddress(
            street1: '123 Wall Street',
            city: 'New York',
            state: 'NY',
            postalCode: '10005',
            country: 'US',
          ),
        ),
        bankAccount: BankAccount(
          accountType: 'checking',
          routingNumber: _routingController.text.trim(),
          accountNumber: _accountController.text.trim(),
          bankName: _bankNameController.text.trim(),
        ),
      );

      // 2. Initiate end-to-end remittance: POST /api/v1/remittance/initiate
      final result = await _remittanceService.initiateRemittance(
        walletId: walletId,
        senderAmount: amount,
        senderCurrency: 'INR',
        recipientCurrency: 'USD',
        recipientPaymentMethodId: paymentMethod.paymentMethodId,
      );

      final remittance = result['remittance'] as RemittanceModel;

      setState(() {
        _isInitiating = false;
        _activeRemittance = remittance;
        _activeStep = 1;
      });

      // Simulate the progression of the multi-hop stages for demonstration
      _simulatePipelineProgress();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitiating = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _simulatePipelineProgress() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _activeStep = 2);

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _activeStep = 3);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 14, 24, 28 + bottomInset),
      child: _activeRemittance != null ? _buildTrackerView() : _buildFormView(),
    );
  }

  Widget _buildFormView() {
    final inrAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final estimatedUsd = (inrAmount / 87.5).toStringAsFixed(2);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E5EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.public_rounded, color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Global Remittance',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'INR → Polygon USDC → USD Bank Account',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Transfer Amount Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'You Send (INR)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      'Recipient Gets (USD)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          '₹',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 110,
                          child: TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_forward_rounded, color: AppTheme.textMuted, size: 20),
                    Text(
                      '\$$estimatedUsd USD',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.accent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Recipient Bank Account (US ACH)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Beneficiary Full Name',
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _routingController,
            decoration: const InputDecoration(
              labelText: 'US Bank Routing Number (9 digits)',
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _accountController,
            decoration: const InputDecoration(
              labelText: 'Account Number',
              isDense: true,
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.error,
              ),
            ),
          ],

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _isInitiating ? null : _startRemittance,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isInitiating
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Text(
                    'Initiate Remittance Pipeline',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackerView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E5EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.accentLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.sync_alt_rounded, color: AppTheme.accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pipeline Live Status',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'Ref: ${_activeRemittance?.reference ?? "REM-ACTIVE"}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        _buildStepTile(
          stepNumber: 1,
          title: 'Transak On-Ramp (INR)',
          subtitle: 'INR deposited to sender Polygon Smart Account',
          isDone: _activeStep >= 1,
          isCurrent: _activeStep == 0,
        ),
        _buildStepTile(
          stepNumber: 2,
          title: 'Circle USDC Transfer',
          subtitle: 'USDC routed on Polygon Amoy blockchain',
          isDone: _activeStep >= 2,
          isCurrent: _activeStep == 1,
        ),
        _buildStepTile(
          stepNumber: 3,
          title: 'Crossmint Bank Payout (USD)',
          subtitle: 'Direct deposit into recipient ACH US bank account',
          isDone: _activeStep >= 3,
          isCurrent: _activeStep == 2,
          isLast: true,
        ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              _activeStep >= 3 ? 'Done' : 'Close Tracker',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepTile({
    required int stepNumber,
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isCurrent,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isDone
                    ? AppTheme.accent
                    : (isCurrent ? AppTheme.primary : const Color(0xFFE2E5EB)),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                    : Text(
                        '$stepNumber',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isCurrent ? Colors.white : AppTheme.textSecondary,
                        ),
                      ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 38,
                color: isDone ? AppTheme.accent : const Color(0xFFE2E5EB),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDone || isCurrent ? AppTheme.textPrimary : AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
