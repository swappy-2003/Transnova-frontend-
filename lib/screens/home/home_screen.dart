import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/wallet_provider.dart';
import 'widgets/balance_card.dart';
import 'widgets/quick_actions.dart';
import 'widgets/receive_modal.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onNavigateTab;

  const HomeScreen({super.key, required this.onNavigateTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().fetchTransactions();
    });
  }

  Widget _buildRecentTransactionItem(TransactionModel tx) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final isCredit = tx.type == 'payin';

    IconData icon;
    Color iconColor;
    String typeLabel;

    switch (tx.type) {
      case 'payin':
        icon = Icons.south_west_rounded;
        iconColor = AppTheme.accent;
        typeLabel = 'Deposit / On-ramp';
        break;
      case 'offramp':
        icon = Icons.account_balance_rounded;
        iconColor = AppTheme.warning;
        typeLabel = 'Cash Out (ACH)';
        break;
      default:
        icon = Icons.north_east_rounded;
        iconColor = AppTheme.primary;
        typeLabel = 'Circle Transfer';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeLabel,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tx.createdAt != null
                      ? DateFormat('MMM d, h:mm a').format(tx.createdAt!)
                      : 'Recently',
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '-'}${currencyFormatter.format(tx.amount)}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isCredit ? AppTheme.accent : Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: tx.isCompleted
                      ? AppTheme.accent.withValues(alpha: 0.15)
                      : tx.isFailed
                          ? AppTheme.error.withValues(alpha: 0.15)
                          : AppTheme.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tx.status.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: tx.isCompleted
                        ? AppTheme.accent
                        : tx.isFailed
                            ? AppTheme.error
                            : AppTheme.warning,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final walletProvider = context.watch<WalletProvider>();
    final txProvider = context.watch<TransactionProvider>();

    final user = authProvider.user;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: () async {
            await Future.wait([
              walletProvider.refreshBalance(),
              txProvider.fetchTransactions(),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${user?.displayName.isNotEmpty == true ? user!.displayName : "there"} 👋',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          'Transnova Wallet',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.tune, color: AppTheme.textSecondary),
                      onPressed: () => widget.onNavigateTab(4), // Settings
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Balance Card
                BalanceCard(
                  usdcBalance: walletProvider.usdcBalance,
                  walletAddress: walletProvider.address,
                  isLoading: walletProvider.isLoading,
                  onRefresh: () => walletProvider.refreshBalance(),
                  onReceive: () => ReceiveModal.show(context, walletProvider.address),
                ),
                const SizedBox(height: 24),
                // Quick Actions
                QuickActions(
                  onSend: () => widget.onNavigateTab(1),
                  onBuy: () => widget.onNavigateTab(2),
                  onCashOut: () => widget.onNavigateTab(3),
                  onReceive: () => ReceiveModal.show(context, walletProvider.address),
                ),
                const SizedBox(height: 32),
                // Recent activity header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Activity',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    TextButton(
                      onPressed: () => widget.onNavigateTab(4), // Activity
                      child: Text(
                        'See All',
                        style: GoogleFonts.inter(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Transactions
                if (txProvider.isLoading && txProvider.transactions.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (txProvider.transactions.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 40, color: AppTheme.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'No transactions yet',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Deposit USDC with Transak or receive from another wallet to get started.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  )
                else
                  ...txProvider.transactions.take(5).map(_buildRecentTransactionItem),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
