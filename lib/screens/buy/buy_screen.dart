import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../services/onramp_service.dart';

class BuyScreen extends StatefulWidget {
  final VoidCallback onDepositSuccess;

  const BuyScreen({super.key, required this.onDepositSuccess});

  @override
  State<BuyScreen> createState() => _BuyScreenState();
}

class _BuyScreenState extends State<BuyScreen> {
  final _amountController = TextEditingController(text: '100');
  String _selectedFiat = 'USD';
  bool _isLoading = false;

  final OnrampService _onrampService = OnrampService();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _launchTransakWidget() async {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid fiat amount')),
      );
      return;
    }

    final walletProvider = context.read<WalletProvider>();
    setState(() => _isLoading = true);

    try {
      final order = await _onrampService.createWidgetUrl(
        walletId: walletProvider.walletId,
        fiatAmount: amount,
        fiatCurrency: _selectedFiat,
      );

      final uri = Uri.parse(order.widgetUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not open widget URL: ${order.widgetUrl}';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('On-ramp error: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _simulateDeposit() async {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText) ?? 100.0;

    final txProvider = context.read<TransactionProvider>();
    final walletProvider = context.read<WalletProvider>();

    setState(() => _isLoading = true);

    try {
      await txProvider.simulateTransaction(
        type: 'payin',
        amount: amount,
        asset: 'USDC',
      );

      await walletProvider.refreshBalance();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Simulated deposit of \$$amount USDC credited to wallet!'),
          backgroundColor: AppTheme.accent,
        ),
      );

      widget.onDepositSuccess();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy USDC (On-ramp)'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Partner Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF0284C7).withValues(alpha: 0.25), AppTheme.surface],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.flash_on, color: Color(0xFF38BDF8), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Powered by Transak',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Deposit fiat via Card, Apple Pay, or Wire directly into your Polygon USDC wallet.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Currency & Amount
              Text(
                'You Pay',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedFiat,
                        dropdownColor: AppTheme.surface,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        items: ['USD', 'EUR', 'GBP', 'CAD'].map((curr) {
                          return DropdownMenuItem(value: curr, child: Text(curr));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedFiat = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
                      decoration: const InputDecoration(
                        hintText: '100.00',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Conversion preview
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Estimated USDC received:',
                      style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                    Text(
                      '~${_amountController.text.isNotEmpty ? _amountController.text : "0"} USDC',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Continue button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _launchTransakWidget,
                icon: const Icon(Icons.open_in_new, size: 18),
                label: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Open Transak On-ramp Widget'),
              ),
              const SizedBox(height: 14),
              // Simulation button
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _simulateDeposit,
                icon: const Icon(Icons.savings_outlined, size: 18, color: AppTheme.accent),
                label: Text(
                  'Instant Simulated Deposit (Sandbox)',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
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
