import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/fee_estimate_model.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/wallet_provider.dart';

class SendScreen extends StatefulWidget {
  final VoidCallback onTransferSuccess;

  const SendScreen({super.key, required this.onTransferSuccess});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();

  bool _isValidatingAddress = false;
  bool? _isAddressValid;
  bool _isEstimatingFee = false;
  FeeEstimateModel? _feeEstimate;

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _validateRecipientAddress() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) return;

    setState(() {
      _isValidatingAddress = true;
      _isAddressValid = null;
    });

    final walletProvider = context.read<WalletProvider>();
    final valid = await walletProvider.validateAddress(address);

    if (!mounted) return;
    setState(() {
      _isValidatingAddress = false;
      _isAddressValid = valid;
    });
  }

  Future<void> _estimateGasFee() async {
    final address = _addressController.text.trim();
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);

    if (address.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid address and amount')),
      );
      return;
    }

    final walletProvider = context.read<WalletProvider>();
    final txProvider = context.read<TransactionProvider>();

    setState(() => _isEstimatingFee = true);

    final estimate = await txProvider.estimateFee(
      walletId: walletProvider.walletId,
      destinationAddress: address,
      amount: amount,
    );

    if (!mounted) return;
    setState(() {
      _isEstimatingFee = false;
      _feeEstimate = estimate;
    });

    if (estimate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(txProvider.errorMessage ?? 'Fee estimation failed'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _executeTransfer({bool simulate = false}) async {
    final address = _addressController.text.trim();
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);

    if (address.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please check address and amount')),
      );
      return;
    }

    final walletProvider = context.read<WalletProvider>();
    final txProvider = context.read<TransactionProvider>();

    try {
      if (simulate) {
        await txProvider.simulateTransaction(
          type: 'wallet_transfer',
          amount: amount,
          destinationAddress: address,
        );
      } else {
        await txProvider.sendCircleTransfer(
          walletId: walletProvider.walletId,
          destinationAddress: address,
          amount: amount,
        );
      }

      if (!mounted) return;

      // Refresh balance after transfer
      final messenger = ScaffoldMessenger.of(context);
      await walletProvider.refreshBalance();

      messenger.showSnackBar(
        SnackBar(
          content: Text(simulate
              ? 'Simulated USDC transfer completed successfully!'
              : 'Circle USDC transfer initiated on Polygon Amoy!'),
          backgroundColor: AppTheme.accent,
        ),
      );

      _addressController.clear();
      _amountController.clear();
      setState(() {
        _isAddressValid = null;
        _feeEstimate = null;
      });

      widget.onTransferSuccess();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final txProvider = context.watch<TransactionProvider>();
    final balance = walletProvider.usdcBalance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send USDC'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Balance indicator
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available to send:',
                      style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary),
                    ),
                    Text(
                      '${NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(balance)} USDC',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Recipient Address
              Text(
                'Recipient Polygon Address',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _addressController,
                style: GoogleFonts.sourceCodePro(fontSize: 13),
                decoration: InputDecoration(
                  hintText: '0x...',
                  suffixIcon: _isValidatingAddress
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : TextButton(
                          onPressed: _validateRecipientAddress,
                          child: Text(
                            'Validate',
                            style: GoogleFonts.inter(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                ),
                onChanged: (_) {
                  if (_isAddressValid != null) setState(() => _isAddressValid = null);
                },
              ),
              if (_isAddressValid != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      _isAddressValid! ? Icons.check_circle : Icons.error,
                      size: 16,
                      color: _isAddressValid! ? AppTheme.accent : AppTheme.error,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isAddressValid!
                          ? 'Valid Polygon address'
                          : 'Invalid Polygon address',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _isAddressValid! ? AppTheme.accent : AppTheme.error,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              // Amount
              Text(
                'Amount (USDC)',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.attach_money, color: AppTheme.accent),
                  hintText: '0.00',
                  suffixIcon: TextButton(
                    onPressed: () {
                      _amountController.text = balance.toStringAsFixed(2);
                    },
                    child: Text(
                      'MAX',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Quick amount percentage chips
              Row(
                children: [25, 50, 75, 100].map((percent) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          side: const BorderSide(color: AppTheme.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          final calculated = (balance * percent / 100);
                          _amountController.text = calculated.toStringAsFixed(2);
                        },
                        child: Text(
                          '$percent%',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              // Gas fee estimate action
              OutlinedButton.icon(
                onPressed: _isEstimatingFee ? null : _estimateGasFee,
                icon: const Icon(Icons.local_gas_station_rounded, size: 18),
                label: _isEstimatingFee
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Estimate Circle Transfer Fee'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  side: const BorderSide(color: AppTheme.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (_feeEstimate != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Estimated Network Fee:',
                        style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                      Text(
                        _feeEstimate!.displayFee,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              // Primary Transfer Button
              ElevatedButton.icon(
                onPressed: txProvider.isLoading ? null : () => _executeTransfer(simulate: false),
                icon: const Icon(Icons.send_rounded, size: 18),
                label: txProvider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Send via Circle SDK'),
              ),
              const SizedBox(height: 12),
              // Simulate Button
              OutlinedButton.icon(
                onPressed: txProvider.isLoading ? null : () => _executeTransfer(simulate: true),
                icon: const Icon(Icons.science_outlined, size: 18, color: AppTheme.textSecondary),
                label: Text(
                  'Simulate Transfer (Test Sandbox)',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: AppTheme.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
