import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';

/// E-Wallet Balance Card
///
/// This widget renders the main floating card on the dashboard:
/// 1. "Total Balance" with privacy eye toggle (hide/show balance).
/// 2. Live "Polygon Amoy" blockchain network indicator badge.
/// 3. Huge formatted USDC balance (e.g. $1,250.00 USDC).
/// 4. Circle Smart Contract Account (SCA) address chip with one-tap copy button.
/// 5. Row of 4 primary action buttons:
///    - Send (Transfer)
///    - Top Up (Buy)
///    - Withdraw (Cash Out)
///    - Receive (QR Code Modal)
class BalanceCard extends StatefulWidget {
  final double usdcBalance;
  final String walletAddress;
  final bool isLoading;
  final VoidCallback onRefresh;
  final VoidCallback onReceive;
  final VoidCallback onSend;
  final VoidCallback onBuy;
  final VoidCallback onCashOut;

  const BalanceCard({
    super.key,
    required this.usdcBalance,
    required this.walletAddress,
    required this.isLoading,
    required this.onRefresh,
    required this.onReceive,
    required this.onSend,
    required this.onBuy,
    required this.onCashOut,
  });

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  // Toggle to hide or show balance for privacy in public spaces
  bool _hideBalance = false;

  /// Helper to shorten EVM addresses: e.g. 0x71C834...392A
  String _formatAddress(String addr) {
    if (addr.isEmpty) return '0x71C8...392A';
    if (addr.length < 12) return addr;
    return '${addr.substring(0, 6)}...${addr.substring(addr.length - 4)}';
  }

  /// Copies full blockchain address to phone clipboard and shows visual toast
  void _copyAddress(BuildContext context) {
    final addr = widget.walletAddress.isNotEmpty
        ? widget.walletAddress
        : '0x71C83492864C62Fdf0159483B892aF829379e492';
    Clipboard.setData(ClipboardData(text: addr));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Smart Account address copied!', style: GoogleFonts.plusJakartaSans()),
          ],
        ),
        backgroundColor: AppTheme.textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Reusable builder for the 4 circular squircle action buttons below the card
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
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
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppTheme.border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top section: Balance + Address chip + Network pill
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Total Balance',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => setState(() => _hideBalance = !_hideBalance),
                          child: Icon(
                            _hideBalance ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 16,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    // Polygon Amoy Status Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppTheme.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Polygon Amoy',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Formatted Amount
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _hideBalance ? '••••••••' : currencyFormatter.format(widget.usdcBalance),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'USDC',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Circle Smart Contract Account Address Chip
                GestureDetector(
                  onTap: () => _copyAddress(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8FA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE8EAF0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shield_outlined, size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          'SCA: ${_formatAddress(widget.walletAddress)}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.copy_rounded, size: 13, color: AppTheme.primary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppTheme.divider),
          // Action Buttons: Send, Top Up, Withdraw, Receive
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Send',
                  color: AppTheme.primary,
                  bgColor: AppTheme.primaryLight,
                  onTap: widget.onSend,
                ),
                _buildActionButton(
                  icon: Icons.add_rounded,
                  label: 'Top Up',
                  color: AppTheme.accent,
                  bgColor: AppTheme.accentLight,
                  onTap: widget.onBuy,
                ),
                _buildActionButton(
                  icon: Icons.account_balance_rounded,
                  label: 'Withdraw',
                  color: AppTheme.warning,
                  bgColor: AppTheme.warningLight,
                  onTap: widget.onCashOut,
                ),
                _buildActionButton(
                  icon: Icons.qr_code_2_rounded,
                  label: 'Receive',
                  color: AppTheme.info,
                  bgColor: AppTheme.infoLight,
                  onTap: widget.onReceive,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
