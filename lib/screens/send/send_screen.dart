import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/app_top_bar.dart';

class SendContact {
  final String name;
  final String address;
  final Color color;

  const SendContact({
    required this.name,
    required this.address,
    required this.color,
  });
}

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
  String _selectedFeeTier = 'medium';

  final List<SendContact> _recentContacts = const [
    SendContact(
      name: 'Alice',
      address: '0x3b8a4f91e320498a129f840938b820194829129f',
      color: Color(0xFFFF7675),
    ),
    SendContact(
      name: 'Bob',
      address: '0x892fa12c98234857b6892e81729482718928a12c',
      color: Color(0xFF74B9FF),
    ),
    SendContact(
      name: 'Charlie',
      address: '0x55d398326f99059ff775485246999027b3197955',
      color: Color(0xFF55EFC4),
    ),
    SendContact(
      name: 'Sarah',
      address: '0x2791bca1f2de4661ed88a30c99a7a9449aa84174',
      color: Color(0xFFA29BFE),
    ),
  ];

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  bool _isEmail(String text) => text.contains('@') && text.contains('.');

  Future<void> _validateRecipientAddress() async {
    final input = _addressController.text.trim();
    if (input.isEmpty) return;

    setState(() {
      _isValidatingAddress = true;
      _isAddressValid = null;
    });

    if (_isEmail(input)) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      final valid = emailRegex.hasMatch(input);
      if (!mounted) return;
      setState(() {
        _isValidatingAddress = false;
        _isAddressValid = valid;
      });
      return;
    }

    final walletProvider = context.read<WalletProvider>();
    final valid = await walletProvider.validateAddress(input);

    if (!mounted) return;
    setState(() {
      _isValidatingAddress = false;
      _isAddressValid = valid;
    });
  }

  Future<void> _pasteAddress() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _addressController.text = data.text!.trim();
      _validateRecipientAddress();
    }
  }

  Future<void> _estimateGasFee() async {
    final input = _addressController.text.trim();
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);

    if (input.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid address/email and amount'),
          backgroundColor: AppTheme.textPrimary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final walletProvider = context.read<WalletProvider>();
    final txProvider = context.read<TransactionProvider>();

    setState(() => _isEstimatingFee = true);

    final isEmail = _isEmail(input);
    await txProvider.estimateFee(
      walletId: walletProvider.walletId,
      destinationAddress: isEmail ? null : input,
      recipientEmail: isEmail ? input : null,
      amount: amount,
    );

    if (!mounted) return;
    setState(() {
      _isEstimatingFee = false;
    });
  }

  Future<void> _executeTransfer({bool simulate = false}) async {
    final address = _addressController.text.trim();
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);

    if (address.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please check address and amount'),
          backgroundColor: AppTheme.textPrimary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final walletProvider = context.read<WalletProvider>();
    final txProvider = context.read<TransactionProvider>();

    try {
      final isEmail = _isEmail(address);
      if (simulate) {
        await txProvider.simulateTransaction(
          type: 'transfer',
          amount: amount,
          asset: 'USDC',
          destinationAddress: address,
        );
      } else {
        await txProvider.sendCircleTransfer(
          walletId: walletProvider.walletId,
          destinationAddress: isEmail ? null : address,
          recipientEmail: isEmail ? address : null,
          amount: amount,
          feeLevel: _selectedFeeTier,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Transfer of \$$amountText USDC submitted successfully!',
                style: GoogleFonts.plusJakartaSans(),
              ),
            ],
          ),
          backgroundColor: AppTheme.accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      _addressController.clear();
      _amountController.clear();
      walletProvider.refreshBalance();

      widget.onTransferSuccess();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// High-Fidelity Transfer Confirmation Modal matching Figma Image 1 & 4
  void _showTransferConfirmation({required bool simulate}) {
    final address = _addressController.text.trim();
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);

    if (address.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please check address and amount'),
          backgroundColor: AppTheme.textPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final isEmail = _isEmail(address);
    final feeLabel = _selectedFeeTier == 'low'
        ? '< \$0.01 (Standard)'
        : (_selectedFeeTier == 'high' ? '~ \$0.02 (Instant)' : '~ \$0.01 (Fast)');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Figma Red Header: Transfer Confirmation with (X)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transfer Confirmation',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(bottomSheetContext),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),

            // Confirmation details
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: Column(
                children: [
                  // Recipient info
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8FB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isEmail ? Icons.email_rounded : Icons.account_balance_wallet_rounded,
                            color: AppTheme.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEmail ? 'Recipient Email' : 'Recipient Address',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                address,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Amount breakdown
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Amount to Send',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        '\$$amountText USDC',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Network Gas Fee',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        feeLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Network',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        'Polygon Amoy',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28, color: AppTheme.divider),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Debit',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '\$$amountText USDC',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Confirm button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(bottomSheetContext);
                      _executeTransfer(simulate: simulate);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          simulate ? 'Confirm Simulation' : 'Confirm & Transfer Now',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeeOption(String tier, String label, String amountGwei, String feeUsd) {
    final isSelected = _selectedFeeTier == tier;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFeeTier = tier),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryLight : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppTheme.primary : AppTheme.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                feeUsd,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                ),
              ),
              Text(
                '$amountGwei Gwei',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final txProvider = context.watch<TransactionProvider>();
    final balance = walletProvider.usdcBalance;
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const AppTopBar(title: 'Transfer', showBackButton: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Balance Indicator Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Available Balance',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            Text(
                              '${currencyFormatter.format(balance)} USDC',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Polygon Amoy',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Recent Contacts (Quick Send from Figma design)
              Text(
                'Recent Recipients',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 84,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _recentContacts.length,
                  itemBuilder: (context, index) {
                    final contact = _recentContacts[index];
                    return GestureDetector(
                      onTap: () {
                        _addressController.text = contact.address;
                        _validateRecipientAddress();
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 18),
                        child: Column(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: contact.color.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: contact.color.withValues(alpha: 0.4), width: 1.5),
                              ),
                              child: Center(
                                child: Text(
                                  contact.name.substring(0, 1),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: contact.color,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              contact.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Recipient Address or Email Input (Flow 2 P2P transfer)
              Text(
                'Recipient Address or Email',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _addressController,
                style: GoogleFonts.jetBrainsMono(fontSize: 13, color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Enter 0x... address or user@email.com',
                  prefixIcon: const Icon(Icons.alternate_email_rounded, color: AppTheme.textMuted, size: 20),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.paste_rounded, color: AppTheme.primary, size: 20),
                        tooltip: 'Paste address or email',
                        onPressed: _pasteAddress,
                      ),
                      if (_isValidatingAddress)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else
                        TextButton(
                          onPressed: _validateRecipientAddress,
                          child: Text(
                            'Check',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
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
                      _isAddressValid! ? Icons.check_circle_rounded : Icons.error_rounded,
                      size: 16,
                      color: _isAddressValid! ? AppTheme.accent : AppTheme.error,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isAddressValid!
                          ? (_isEmail(_addressController.text.trim())
                              ? 'Valid Transnova recipient email'
                              : 'Valid Polygon address')
                          : (_isEmail(_addressController.text.trim())
                              ? 'Invalid email format'
                              : 'Invalid Polygon blockchain address'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _isAddressValid! ? AppTheme.accent : AppTheme.error,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 22),

              // Amount Input
              Text(
                'Amount',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.attach_money_rounded, color: AppTheme.primary, size: 28),
                  hintText: '0.00',
                  suffixIcon: Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: TextButton(
                      onPressed: () => _amountController.text = balance.toStringAsFixed(2),
                      child: Text(
                        'MAX',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Quick Amount Chips
              Row(
                children: [10, 25, 50, 100].map((quickAmount) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () => _amountController.text = quickAmount.toString(),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Text(
                            '\$$quickAmount',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),

              // Gas Fee Estimation & Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Network Gas Speed',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _isEstimatingFee ? null : _estimateGasFee,
                    icon: _isEstimatingFee
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(
                      'Estimate Fee',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildFeeOption('low', 'Standard', '25', '< \$0.01'),
                  const SizedBox(width: 8),
                  _buildFeeOption('medium', 'Fast', '35', '~ \$0.01'),
                  const SizedBox(width: 8),
                  _buildFeeOption('high', 'Instant', '50', '~ \$0.02'),
                ],
              ),
              const SizedBox(height: 32),

              // Confirm Transfer Button
              ElevatedButton(
                onPressed: txProvider.isLoading ? null : () => _showTransferConfirmation(simulate: false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  shadowColor: AppTheme.primary.withValues(alpha: 0.35),
                ),
                child: txProvider.isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.send_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Confirm & Send',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 12),

              // Sandbox simulation button
              OutlinedButton.icon(
                onPressed: txProvider.isLoading ? null : () => _showTransferConfirmation(simulate: true),
                icon: const Icon(Icons.science_outlined, color: AppTheme.textSecondary, size: 18),
                label: Text(
                  'Simulate Instant Transfer (Demo)',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: AppTheme.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
