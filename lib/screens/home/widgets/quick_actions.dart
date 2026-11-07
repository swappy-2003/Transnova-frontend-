import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme.dart';

class QuickActions extends StatelessWidget {
  final VoidCallback onSend;
  final VoidCallback onBuy;
  final VoidCallback onCashOut;
  final VoidCallback onReceive;

  const QuickActions({
    super.key,
    required this.onSend,
    required this.onBuy,
    required this.onCashOut,
    required this.onReceive,
  });

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionButton(
          icon: Icons.arrow_upward_rounded,
          label: 'Send',
          color: AppTheme.primary,
          onTap: onSend,
        ),
        _buildActionButton(
          icon: Icons.add_circle_outline_rounded,
          label: 'Buy',
          color: AppTheme.accent,
          onTap: onBuy,
        ),
        _buildActionButton(
          icon: Icons.account_balance_rounded,
          label: 'Cash Out',
          color: const Color(0xFFF59E0B),
          onTap: onCashOut,
        ),
        _buildActionButton(
          icon: Icons.qr_code_2_rounded,
          label: 'Receive',
          color: const Color(0xFF38BDF8),
          onTap: onReceive,
        ),
      ],
    );
  }
}
