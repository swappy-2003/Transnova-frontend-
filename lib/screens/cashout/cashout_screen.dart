import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/offramp_model.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../services/offramp_service.dart';

class CashoutScreen extends StatefulWidget {
  final VoidCallback onCashoutSuccess;

  const CashoutScreen({super.key, required this.onCashoutSuccess});

  @override
  State<CashoutScreen> createState() => _CashoutScreenState();
}

class _CashoutScreenState extends State<CashoutScreen> {
  final _nameController = TextEditingController(text: 'Alex Rivera');
  final _emailController = TextEditingController(text: 'alex@transnova.com');
  final _streetController = TextEditingController(text: '123 Market St');
  final _cityController = TextEditingController(text: 'San Francisco');
  final _stateController = TextEditingController(text: 'CA');
  final _zipController = TextEditingController(text: '94105');

  final _routingController = TextEditingController(text: '121000358');
  final _accountController = TextEditingController(text: '1234567890');
  final _bankNameController = TextEditingController(text: 'Wells Fargo');
  final _amountController = TextEditingController(text: '50.00');

  String _accountType = 'checking';
  String? _paymentMethodId;
  bool _isLoading = false;

  final OfframpService _offrampService = OfframpService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _routingController.dispose();
    _accountController.dispose();
    _bankNameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _linkBankAccount() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _routingController.text.trim().isEmpty ||
        _accountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in beneficiary and bank details')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final beneficiary = Beneficiary(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        address: BeneficiaryAddress(
          street1: _streetController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          postalCode: _zipController.text.trim(),
        ),
      );

      final bankAccount = BankAccount(
        accountType: _accountType,
        routingNumber: _routingController.text.trim(),
        accountNumber: _accountController.text.trim(),
        bankName: _bankNameController.text.trim(),
      );

      final result = await _offrampService.createPaymentMethod(
        beneficiary: beneficiary,
        bankAccount: bankAccount,
      );

      setState(() {
        _paymentMethodId = result.paymentMethodId;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bank account linked! ID: ${result.paymentMethodId}'),
          backgroundColor: AppTheme.accent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to link bank: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _executeCashout({bool simulate = false}) async {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid cashout amount')),
      );
      return;
    }

    final walletProvider = context.read<WalletProvider>();
    final txProvider = context.read<TransactionProvider>();

    setState(() => _isLoading = true);

    try {
      if (simulate) {
        await txProvider.simulateTransaction(
          type: 'offramp',
          amount: amount,
          asset: 'USDC',
        );
      } else {
        if (_paymentMethodId == null) {
          await _linkBankAccount();
          if (_paymentMethodId == null) return;
        }

        await _offrampService.createOfframpOrder(
          payerAddress: walletProvider.address,
          paymentMethodId: _paymentMethodId!,
          amount: amount,
        );
      }

      await walletProvider.refreshBalance();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(simulate
              ? 'Simulated cash-out of \$$amount to bank completed!'
              : 'Crossmint ACH cash-out order submitted!'),
          backgroundColor: AppTheme.accent,
        ),
      );

      widget.onCashoutSuccess();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Off-ramp error: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final balance = walletProvider.usdcBalance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash Out to Bank (ACH)'),
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
                    colors: [const Color(0xFFF59E0B).withValues(alpha: 0.2), AppTheme.surface],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.account_balance, color: Color(0xFFF59E0B), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Powered by Crossmint Off-ramp',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Withdraw your Polygon USDC directly into your US checking or savings bank account.',
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
              const SizedBox(height: 24),
              // Cashout Amount
              Text(
                'Withdrawal Amount (USDC)',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.attach_money, color: AppTheme.warning),
                  hintText: '50.00',
                  helperText: 'Available balance: \$${balance.toStringAsFixed(2)} USDC',
                ),
              ),
              const SizedBox(height: 24),
              // Bank Details Accordion / Form
              Text(
                'US Bank Account Details',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Account Holder Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Beneficiary Email'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _routingController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Routing Number (9 digits)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _accountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Account Number'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _bankNameController,
                      decoration: const InputDecoration(labelText: 'Bank Name'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _accountType,
                      dropdownColor: AppTheme.surface,
                      decoration: const InputDecoration(labelText: 'Account Type'),
                      items: const [
                        DropdownMenuItem(value: 'checking', child: Text('Checking')),
                        DropdownMenuItem(value: 'savings', child: Text('Savings')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _accountType = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _streetController,
                      decoration: const InputDecoration(labelText: 'Street Address'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _cityController,
                      decoration: const InputDecoration(labelText: 'City'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 60,
                    child: TextField(
                      controller: _stateController,
                      decoration: const InputDecoration(labelText: 'State'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Cashout Buttons
              ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _executeCashout(simulate: false),
                icon: const Icon(Icons.account_balance, size: 18),
                label: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Execute Crossmint Bank Cash-Out'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : () => _executeCashout(simulate: true),
                icon: const Icon(Icons.flash_on, size: 18, color: AppTheme.warning),
                label: Text(
                  'Simulated Cash-Out (Sandbox Demo)',
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
