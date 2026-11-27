import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/wallet_provider.dart';
import 'widgets/balance_card.dart';
import 'widgets/promo_banner.dart';
import 'widgets/razorpay_topup_modal.dart';
import 'widgets/receive_modal.dart';
import 'widgets/remittance_modal.dart';
import 'widgets/services_grid.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onNavigateTab;
  final VoidCallback? onScanQr;

  const HomeScreen({
    super.key,
    required this.onNavigateTab,
    this.onScanQr,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().fetchTransactions();
      context.read<WalletProvider>().initWallet();
    });
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.brandBlack : AppTheme.surfaceLow,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppTheme.brandBlack : AppTheme.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.uiStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionRow(TransactionModel tx) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final isCredit = tx.type == 'payin';

    IconData icon;
    Color iconColor;
    Color bgColor;
    String title;

    switch (tx.type) {
      case 'payin':
        icon = Icons.south_west_rounded;
        iconColor = AppTheme.onPrimaryLight;
        bgColor = AppTheme.primaryLight;
        title = tx.description.isNotEmpty ? tx.description : 'USDC Deposit';
        break;
      case 'offramp':
        icon = Icons.account_balance_outlined;
        iconColor = AppTheme.onRewardYellowSoft;
        bgColor = AppTheme.rewardYellowSoft;
        title = tx.description.isNotEmpty ? tx.description : 'ACH Bank Cash Out';
        break;
      default:
        icon = Icons.north_east_rounded;
        iconColor = Colors.white;
        bgColor = AppTheme.brandBlack;
        title = tx.description.isNotEmpty ? tx.description : 'Circle Transfer';
    }

    final dateStr = DateFormat('MMM dd • hh:mm a').format(tx.createdAt ?? DateTime.now());
    final statusColor = tx.isCompleted
        ? AppTheme.primaryLight
        : tx.isFailed
            ? AppTheme.errorLight
            : AppTheme.rewardYellowSoft;
    final statusTextColor = tx.isCompleted
        ? AppTheme.onPrimaryLight
        : tx.isFailed
            ? AppTheme.error
            : AppTheme.onRewardYellowSoft;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.uiStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: AppTheme.uiStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? "+" : "-"}${currencyFormatter.format(tx.amount)}',
                style: AppTheme.displayStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isCredit ? AppTheme.primaryDark : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  tx.status[0].toUpperCase() + tx.status.substring(1),
                  style: AppTheme.uiStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusTextColor,
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
    final displayName = user?.displayName.isNotEmpty == true ? user!.displayName : 'Demo User';
    final initials = displayName.trim().isNotEmpty ? displayName.trim()[0].toUpperCase() : 'T';

    var filteredTxs = txProvider.transactions;
    if (_selectedFilter != 'all') {
      filteredTxs = filteredTxs.where((t) => t.type == _selectedFilter).toList();
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 108),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Clean IntPay Top Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainer,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: AppTheme.displayStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.brandBlack,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Good morning,',
                              style: AppTheme.uiStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            Text(
                              displayName,
                              style: AppTheme.uiStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLow,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppTheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Transnova',
                                style: AppTheme.uiStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'All notifications are up to date!',
                                  style: AppTheme.uiStyle(color: Colors.white),
                                ),
                                backgroundColor: AppTheme.brandBlack,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceLow,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(
                                  Icons.notifications_none_rounded,
                                  color: AppTheme.textPrimary,
                                  size: 20,
                                ),
                                Positioned(
                                  top: 8,
                                  right: 9,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: AppTheme.rewardYellow,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 1.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Green Hero Balance Card + 4 Quick Tiles
                BalanceCard(
                  usdcBalance: walletProvider.usdcBalance,
                  walletAddress: walletProvider.address,
                  isLoading: walletProvider.isLoading,
                  onRefresh: () => walletProvider.refreshBalance(),
                  onReceive: () => ReceiveModal.show(
                    context,
                    walletProvider.address,
                    walletProvider.qr?.rawPayload,
                  ),
                  onScan: widget.onScanQr,
                  onSend: () => widget.onNavigateTab(1),
                  onBuy: () => widget.onNavigateTab(2),
                  onCashOut: () => widget.onNavigateTab(3),
                ),
                const SizedBox(height: 20),

                // Services 4x2 Grid (preserving all original options)
                ServicesGrid(
                  onTransfer: () => widget.onNavigateTab(1),
                  onTopUp: () => widget.onNavigateTab(2),
                  onWithdraw: () => widget.onNavigateTab(3),
                  onScan: widget.onScanQr ??
                      () => ReceiveModal.show(
                            context,
                            walletProvider.address,
                            walletProvider.qr?.rawPayload,
                          ),
                ),
                const SizedBox(height: 18),

                // Obsidian & Yellow Rewards Promo Carousel
                PromoBanner(
                  onTransfer: () => widget.onNavigateTab(1),
                  onTopUp: () => RazorpayTopUpModal.show(context),
                  onRemit: () => RemittanceModal.show(context),
                ),
                const SizedBox(height: 22),

                // Recent Activity Header & Filter Chips
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Activity',
                      style: AppTheme.uiStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => widget.onNavigateTab(4),
                      child: Text(
                        'See all',
                        style: AppTheme.uiStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      _buildFilterChip('Transfers', 'transfer'),
                      _buildFilterChip('Deposits', 'payin'),
                      _buildFilterChip('Cash Out', 'offramp'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                if (filteredTxs.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLow,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: AppTheme.onPrimaryLight,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No transactions yet',
                          style: AppTheme.uiStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Deposit USDC or send a transfer to get started.',
                          style: AppTheme.uiStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLow,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredTxs.length,
                      separatorBuilder: (_, _) => const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppTheme.border,
                      ),
                      itemBuilder: (context, index) => _buildTransactionRow(filteredTxs[index]),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
