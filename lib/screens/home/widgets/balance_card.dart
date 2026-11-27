import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';

/// IntPay-styled Global Wallet Hero Card
///
/// Features:
/// - Vibrant IntPay Green (#12B76A) 24px rounded hero surface
/// - Deep Obsidian (#101310) tabular balance & high-contrast CTAs
/// - Privacy eye toggle, Polygon Amoy badge, and copyable SCA address chip
class BalanceCard extends StatefulWidget {
  final double usdcBalance;
  final String walletAddress;
  final bool isLoading;
  final VoidCallback onRefresh;
  final VoidCallback onReceive;
  final VoidCallback? onScan;
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
    this.onScan,
    required this.onSend,
    required this.onBuy,
    required this.onCashOut,
  });

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  bool _hideBalance = false;

  String _formatAddress(String addr) {
    if (addr.isEmpty) return '0x71C8...392A';
    if (addr.length < 12) return addr;
    return '${addr.substring(0, 6)}...${addr.substring(addr.length - 4)}';
  }

  void _copyAddress(BuildContext context) {
    final addr = widget.walletAddress.isNotEmpty
        ? widget.walletAddress
        : '0x71C83492864C62Fdf0159483B892aF829379e492';
    Clipboard.setData(ClipboardData(text: addr));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Smart Account address copied!',
              style: AppTheme.uiStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: AppTheme.brandBlack,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildQuickTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.surfaceLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Icon(icon, color: AppTheme.brandBlack, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.uiStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
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

    return Column(
      children: [
        // Vibrant Green Hero Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: Wallet title + eye toggle & Polygon Amoy dark pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 18,
                        color: AppTheme.brandBlack,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Global Wallet • USDC',
                        style: AppTheme.uiStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.brandBlack,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => setState(() => _hideBalance = !_hideBalance),
                        child: Icon(
                          _hideBalance ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 17,
                          color: AppTheme.brandBlack.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: widget.onRefresh,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.brandBlack,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Polygon Amoy',
                            style: AppTheme.uiStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.north_east_rounded, size: 13, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Hero Balance Figure (Mulish 34px tabular)
              if (_hideBalance)
                Text(
                  '••••••••',
                  style: AppTheme.displayStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.brandBlack,
                  ),
                )
              else
                TweenAnimationBuilder<double>(
                  key: ValueKey(widget.usdcBalance),
                  tween: Tween<double>(begin: 0, end: widget.usdcBalance),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return Text(
                      currencyFormatter.format(value),
                      style: AppTheme.displayStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.brandBlack,
                      ),
                    );
                  },
                ),
              const SizedBox(height: 6),

              // Copyable Smart Account Chip
              GestureDetector(
                onTap: () => _copyAddress(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'SCA: ${_formatAddress(widget.walletAddress)}',
                      style: AppTheme.monoStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.brandBlack.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.copy_rounded,
                      size: 13,
                      color: AppTheme.brandBlack.withValues(alpha: 0.8),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Primary Pill Action Buttons (Send Money & Add Money)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: widget.onSend,
                      icon: const Icon(Icons.send_rounded, size: 17),
                      label: const Text('Send Money'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandBlack,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 44),
                        shape: const StadiumBorder(),
                        textStyle: AppTheme.uiStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: widget.onBuy,
                      icon: const Icon(Icons.add_rounded, size: 19),
                      label: const Text('Add Money'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.brandBlack,
                        minimumSize: const Size(0, 44),
                        shape: const StadiumBorder(),
                        textStyle: AppTheme.uiStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 4 Quick Action Tiles (Send, Top Up, Withdraw, Receive)
        Row(
          children: [
            _buildQuickTile(
              icon: Icons.qr_code_scanner_rounded,
              label: 'Scan QR',
              onTap: widget.onScan ?? widget.onReceive,
            ),
            const SizedBox(width: 8),
            _buildQuickTile(
              icon: Icons.arrow_upward_rounded,
              label: 'Transfer',
              onTap: widget.onSend,
            ),
            const SizedBox(width: 8),
            _buildQuickTile(
              icon: Icons.account_balance_outlined,
              label: 'Cash Out',
              onTap: widget.onCashOut,
            ),
            const SizedBox(width: 8),
            _buildQuickTile(
              icon: Icons.south_west_rounded,
              label: 'Receive',
              onTap: widget.onReceive,
            ),
          ],
        ),
      ],
    );
  }
}
