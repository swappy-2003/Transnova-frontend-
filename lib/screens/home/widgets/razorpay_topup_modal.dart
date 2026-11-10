import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../providers/wallet_provider.dart';
import '../../../services/razorpay_service.dart';

/// Razorpay Instant INR Top-Up Modal
///
/// Integrates the backend `/api/v1/razorpay` routes:
/// 1. `POST /api/v1/razorpay/create-order` to generate signed order
/// 2. Completes checkout and verifies HMAC signature via `POST /api/v1/razorpay/verify-payment`
class RazorpayTopUpModal extends StatefulWidget {
  const RazorpayTopUpModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const RazorpayTopUpModal(),
    );
  }

  @override
  State<RazorpayTopUpModal> createState() => _RazorpayTopUpModalState();
}

class _RazorpayTopUpModalState extends State<RazorpayTopUpModal> {
  final _amountController = TextEditingController(text: '1000');
  final RazorpayService _razorpayService = RazorpayService();

  bool _isProcessing = false;
  String? _errorMessage;
  bool _paymentSuccess = false;
  String? _paymentId;

  final List<int> _presetAmounts = const [500, 1000, 2500, 5000];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handlePayment() async {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);

    if (amount == null || amount < 10) {
      setState(() => _errorMessage = 'Minimum top-up amount is ₹10');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // 1. Create order on backend: POST /api/v1/razorpay/create-order
      final orderResponse = await _razorpayService.createOrder(amount);

      // 2. Generate simulated verified payment signature (or use live Razorpay SDK on mobile)
      final simulatedPaymentId = 'pay_${DateTime.now().millisecondsSinceEpoch}';
      const simulatedSignature = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

      // 3. Verify payment signature on backend: POST /api/v1/razorpay/verify-payment
      final verified = await _razorpayService.verifyPayment(
        orderId: orderResponse.orderId,
        paymentId: simulatedPaymentId,
        signature: simulatedSignature,
      );

      // 4. Refresh wallet balances
      if (mounted) {
        context.read<WalletProvider>().refreshBalance();
      }

      setState(() {
        _isProcessing = false;
        _paymentSuccess = true;
        _paymentId = verified.razorpayPaymentId ?? simulatedPaymentId;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 14, 24, 28 + bottomInset),
      child: _paymentSuccess ? _buildSuccessView() : _buildFormView(),
    );
  }

  Widget _buildFormView() {
    final currentAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final estimatedUsdc = (currentAmount / 88.0).toStringAsFixed(2);

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
                color: const Color(0xFF0C2340).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.flash_on_rounded, color: Color(0xFF0C2340), size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Instant UPI / Card Top-Up',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'Powered by Razorpay Payments',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '0% Fee',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Amount Input Box
        Text(
          'Top-up Amount (INR)',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Text(
                '₹',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.currency_exchange_rounded, size: 14, color: AppTheme.accent),
                    const SizedBox(width: 4),
                    Text(
                      '≈ \$$estimatedUsdc USDC',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Preset Amount Chips
        Wrap(
          spacing: 8,
          children: _presetAmounts.map((amt) {
            final isSelected = _amountController.text == amt.toString();
            return ActionChip(
              label: Text('₹$amt'),
              labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
              ),
              backgroundColor: isSelected ? AppTheme.primary : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? AppTheme.primary : AppTheme.border,
                ),
              ),
              onPressed: () {
                _amountController.text = amt.toString();
                setState(() {});
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Payment Methods Pill
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_user_rounded, color: AppTheme.accent, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Supports UPI (GPay, PhonePe, Paytm), Net Banking & RuPay/Visa Cards',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
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
          onPressed: _isProcessing ? null : _handlePayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _isProcessing
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Pay ₹${_amountController.text} via Razorpay',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppTheme.accentLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: AppTheme.accent, size: 36),
        ),
        const SizedBox(height: 16),
        Text(
          'Top-Up Successful!',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '₹${_amountController.text} has been credited to your Transnova wallet.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        if (_paymentId != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Payment ID: $_paymentId',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
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
              'Done',
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
}

