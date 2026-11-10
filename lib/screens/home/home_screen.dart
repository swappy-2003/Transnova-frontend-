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
import 'widgets/promo_banner.dart';
import 'widgets/razorpay_topup_modal.dart';
import 'widgets/receive_modal.dart';
import 'widgets/remittance_modal.dart';
import 'widgets/services_grid.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onNavigateTab;

  const HomeScreen({super.key, required this.onNavigateTab});

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
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTile(TransactionModel tx) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final isCredit = tx.type == 'payin';

    IconData icon;
    Color iconColor;
    Color bgColor;
    String title;

    switch (tx.type) {
      case 'payin':
        icon = Icons.arrow_downward_rounded;
        iconColor = AppTheme.accent;
        bgColor = AppTheme.accentLight;
        title = tx.description.isNotEmpty ? tx.description : 'USDC Deposit';
        break;
      case 'offramp':
        icon = Icons.account_balance_rounded;
        iconColor = AppTheme.warning;
        bgColor = AppTheme.warningLight;
        title = tx.description.isNotEmpty ? tx.description : 'ACH Bank Cash Out';
        break;
      default:
        icon = Icons.arrow_upward_rounded;
        iconColor = AppTheme.primary;
        bgColor = AppTheme.primaryLight;
        title = tx.description.isNotEmpty ? tx.description : 'Circle Transfer';
    }

    final dateStr = DateFormat('MMM dd, hh:mm a').format(tx.createdAt ?? DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isCredit ? AppTheme.accent : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: tx.isCompleted
                      ? AppTheme.accentLight
                      : tx.isFailed
                          ? const Color(0xFFFFEEEE)
                          : AppTheme.warningLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tx.status.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
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

    // Filter transactions
    var filteredTxs = txProvider.transactions;
    if (_selectedFilter != 'all') {
      filteredTxs = filteredTxs.where((t) => t.type == _selectedFilter).toList();
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async {
          await Future.wait([
            walletProvider.refreshBalance(),
            txProvider.fetchTransactions(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Coral Curved Header with Balance Card
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 54, 20, 110),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF4B4B), Color(0xFFFF5E5E), Color(0xFFFA5252)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                              ),
                              child: const Icon(Icons.person_rounded, color: Colors.white, size: 26),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, ${user?.displayName.isNotEmpty == true ? user!.displayName : "Demo User"} 👋',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                                Text(
                                  'Transnova Wallet',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // Notification Bell with indicator
                            InkWell(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('All notifications are up to date!'),
                                    backgroundColor: AppTheme.textPrimary,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  shape: BoxShape.circle,
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFFD166),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Settings Button
                            InkWell(
                              onTap: () => widget.onNavigateTab(4), // Go to profile/settings
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Overlapping Balance Card
                  Positioned(
                    top: 116,
                    left: 20,
                    right: 20,
                    child: BalanceCard(
                      usdcBalance: walletProvider.usdcBalance,
                      walletAddress: walletProvider.address,
                      isLoading: walletProvider.isLoading,
                      onRefresh: () => walletProvider.refreshBalance(),
                      onReceive: () => ReceiveModal.show(
                        context,
                        walletProvider.address,
                        walletProvider.qr?.rawPayload,
                      ),
                      onSend: () => widget.onNavigateTab(1),
                      onBuy: () => widget.onNavigateTab(2),
                      onCashOut: () => widget.onNavigateTab(3),
                    ),
                  ),
                ],
              ),
              // Space below overlapping card
              const SizedBox(height: 180),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Services 4x2 Grid (from Figma)
                    ServicesGrid(
                      onTransfer: () => widget.onNavigateTab(1),
                      onTopUp: () => widget.onNavigateTab(2),
                      onWithdraw: () => widget.onNavigateTab(3),
                      onScan: () => ReceiveModal.show(
                        context,
                        walletProvider.address,
                        walletProvider.qr?.rawPayload,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Special Promo / High-Fidelity Carousel matching Figma
                    PromoBanner(
                      onTransfer: () => widget.onNavigateTab(1),
                      onTopUp: () => RazorpayTopUpModal.show(context),
                      onRemit: () => RemittanceModal.show(context),
                    ),
                    const SizedBox(height: 28),

                    // Recent Activity Header & Filters
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Activity',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () => widget.onNavigateTab(4), // Activity
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(
                            'See All',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Category Filter Pills
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
                    const SizedBox(height: 14),

                    // Transactions list
                    if (filteredTxs.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.receipt_long_rounded, color: AppTheme.primary, size: 24),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No transactions found',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Deposit USDC or send a transfer to get started.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredTxs.length,
                        itemBuilder: (context, index) => _buildTransactionTile(filteredTxs[index]),
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
