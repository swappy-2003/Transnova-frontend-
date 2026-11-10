import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme.dart';
import 'razorpay_topup_modal.dart';
import 'remittance_modal.dart';

class ServiceItem {
  final String title;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const ServiceItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });
}

class ServicesGrid extends StatelessWidget {
  final VoidCallback onTransfer;
  final VoidCallback onTopUp;
  final VoidCallback onWithdraw;
  final VoidCallback onScan;
  final VoidCallback? onRazorpay;
  final VoidCallback? onRemittance;

  const ServicesGrid({
    super.key,
    required this.onTransfer,
    required this.onTopUp,
    required this.onWithdraw,
    required this.onScan,
    this.onRazorpay,
    this.onRemittance,
  });

  void _showComingSoon(BuildContext context, String serviceName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$serviceName will be available in the next release!'),
        backgroundColor: AppTheme.textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final services = [
      ServiceItem(
        title: 'Transfer',
        icon: Icons.send_rounded,
        color: AppTheme.primary,
        bgColor: AppTheme.primaryLight,
        onTap: onTransfer,
      ),
      ServiceItem(
        title: 'Top Up',
        icon: Icons.account_balance_wallet_rounded,
        color: AppTheme.accent,
        bgColor: AppTheme.accentLight,
        onTap: onTopUp,
      ),
      ServiceItem(
        title: 'UPI TopUp',
        icon: Icons.flash_on_rounded,
        color: const Color(0xFF0C2340),
        bgColor: const Color(0xFFE8EDF5),
        onTap: onRazorpay ?? () => RazorpayTopUpModal.show(context),
      ),
      ServiceItem(
        title: 'Remittance',
        icon: Icons.public_rounded,
        color: const Color(0xFF6C5CE7),
        bgColor: const Color(0xFFF1F0FD),
        onTap: onRemittance ?? () => RemittanceModal.show(context),
      ),
      ServiceItem(
        title: 'Withdraw',
        icon: Icons.credit_card_rounded,
        color: AppTheme.warning,
        bgColor: AppTheme.warningLight,
        onTap: onWithdraw,
      ),
      ServiceItem(
        title: 'QR Pay',
        icon: Icons.qr_code_scanner_rounded,
        color: AppTheme.info,
        bgColor: AppTheme.infoLight,
        onTap: onScan,
      ),
      ServiceItem(
        title: 'Electricity',
        icon: Icons.bolt_rounded,
        color: const Color(0xFFFD79A8),
        bgColor: const Color(0xFFFFF0F5),
        onTap: () => _showComingSoon(context, 'Electricity Bill'),
      ),
      ServiceItem(
        title: 'More',
        icon: Icons.grid_view_rounded,
        color: const Color(0xFF00CEC9),
        bgColor: const Color(0xFFEBFBFB),
        onTap: () => _showComingSoon(context, 'DeFi Services'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Services',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: services.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 0.85,
            crossAxisSpacing: 10,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final item = services[index];
            return InkWell(
              onTap: item.onTap,
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: item.bgColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: item.color.withValues(alpha: 0.15)),
                    ),
                    child: Icon(item.icon, color: item.color, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

