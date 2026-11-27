import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import 'razorpay_topup_modal.dart';
import 'remittance_modal.dart';

class ServiceItem {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String? badge;
  final VoidCallback onTap;

  const ServiceItem({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    this.badge,
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
        content: Text(
          '$serviceName will be available in the next release!',
          style: AppTheme.uiStyle(color: Colors.white),
        ),
        backgroundColor: AppTheme.brandBlack,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
        iconColor: AppTheme.brandBlack,
        bgColor: AppTheme.primaryLight,
        onTap: onTransfer,
      ),
      ServiceItem(
        title: 'Top Up',
        icon: Icons.account_balance_wallet_outlined,
        iconColor: AppTheme.brandBlack,
        bgColor: AppTheme.surfaceLow,
        onTap: onTopUp,
      ),
      ServiceItem(
        title: 'UPI TopUp',
        icon: Icons.flash_on_rounded,
        iconColor: AppTheme.brandBlack,
        bgColor: AppTheme.rewardYellowSoft,
        badge: 'INR',
        onTap: onRazorpay ?? () => RazorpayTopUpModal.show(context),
      ),
      ServiceItem(
        title: 'Remittance',
        icon: Icons.public_rounded,
        iconColor: AppTheme.primaryDark,
        bgColor: AppTheme.surfaceHigh,
        onTap: onRemittance ?? () => RemittanceModal.show(context),
      ),
      ServiceItem(
        title: 'Withdraw',
        icon: Icons.account_balance_outlined,
        iconColor: AppTheme.brandBlack,
        bgColor: AppTheme.surfaceLow,
        onTap: onWithdraw,
      ),
      ServiceItem(
        title: 'QR Pay',
        icon: Icons.qr_code_2_rounded,
        iconColor: AppTheme.brandBlack,
        bgColor: AppTheme.surfaceLow,
        onTap: onScan,
      ),
      ServiceItem(
        title: 'Electricity',
        icon: Icons.bolt_rounded,
        iconColor: AppTheme.textSecondary,
        bgColor: AppTheme.surfaceLow,
        onTap: () => _showComingSoon(context, 'Electricity Bill'),
      ),
      ServiceItem(
        title: 'More',
        icon: Icons.grid_view_rounded,
        iconColor: AppTheme.textSecondary,
        bgColor: AppTheme.surfaceLow,
        onTap: () => _showComingSoon(context, 'DeFi Services'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Services',
          style: AppTheme.uiStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: services.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 0.88,
            crossAxisSpacing: 8,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final item = services[index];
            return InkWell(
              onTap: item.onTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: item.bgColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Icon(item.icon, color: item.iconColor, size: 20),
                        ),
                        if (item.badge != null)
                          Positioned(
                            right: -6,
                            bottom: -2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppTheme.brandBlack,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                item.badge!,
                                style: AppTheme.uiStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
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
          },
        ),
      ],
    );
  }
}
