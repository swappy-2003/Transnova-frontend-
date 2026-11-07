import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../models/transaction_model.dart';
import '../../providers/transaction_provider.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  String _selectedFilter = 'all';

  void _showTransactionDetails(TransactionModel tx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Transaction Details',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              _buildDetailRow('Reference', tx.reference, canCopy: true),
              _buildDetailRow('Type', tx.type.toUpperCase()),
              _buildDetailRow('Amount', '${NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(tx.amount)} ${tx.asset}'),
              _buildDetailRow('Status', tx.status.toUpperCase(), isStatus: true, statusValue: tx.status),
              if (tx.circleTxHash != null && tx.circleTxHash!.isNotEmpty)
                _buildDetailRow('Polygon Tx Hash', tx.circleTxHash!, canCopy: true, isExplorerLink: true),
              if (tx.transakOrderId != null)
                _buildDetailRow('Transak Order ID', tx.transakOrderId!, canCopy: true),
              if (tx.crossmintOrderId != null)
                _buildDetailRow('Crossmint Order ID', tx.crossmintOrderId!, canCopy: true),
              if (tx.createdAt != null)
                _buildDetailRow('Date', DateFormat('yyyy-MM-dd HH:mm:ss').format(tx.createdAt!)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool canCopy = false,
    bool isStatus = false,
    String? statusValue,
    bool isExplorerLink = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isStatus
                          ? (statusValue == 'completed' ? AppTheme.accent : AppTheme.warning)
                          : Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (canCopy)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16, color: AppTheme.primary),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$label copied to clipboard')),
                      );
                    },
                  ),
                if (isExplorerLink)
                  IconButton(
                    icon: const Icon(Icons.open_in_new, size: 16, color: AppTheme.accent),
                    onPressed: () async {
                      final url = Uri.parse('https://amoy.polygonscan.com/tx/$value');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    final filteredTransactions = txProvider.transactions.where((tx) {
      if (_selectedFilter == 'transfers') return tx.type == 'wallet_transfer';
      if (_selectedFilter == 'payin') return tx.type == 'payin';
      if (_selectedFilter == 'offramp') return tx.type == 'offramp';
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity History'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  {'id': 'all', 'label': 'All Transactions'},
                  {'id': 'transfers', 'label': 'Circle Transfers'},
                  {'id': 'payin', 'label': 'On-ramp / Payin'},
                  {'id': 'offramp', 'label': 'Off-ramp / Cash Out'},
                ].map((f) {
                  final isSelected = _selectedFilter == f['id'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(f['label']!),
                      labelStyle: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                      ),
                      backgroundColor: AppTheme.surface,
                      selectedColor: AppTheme.primary,
                      checkmarkColor: Colors.white,
                      side: BorderSide(
                        color: isSelected ? AppTheme.primary : AppTheme.border,
                      ),
                      onSelected: (_) {
                        setState(() => _selectedFilter = f['id']!);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(color: AppTheme.border, height: 1),
            // List
            Expanded(
              child: RefreshIndicator(
                color: AppTheme.primary,
                onRefresh: () => txProvider.fetchTransactions(),
                child: filteredTransactions.isEmpty
                    ? ListView(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 80),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.history, size: 48, color: AppTheme.textMuted),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No transactions match filter',
                                    style: GoogleFonts.inter(fontSize: 15, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredTransactions.length,
                        itemBuilder: (ctx, i) {
                          final tx = filteredTransactions[i];
                          final isCredit = tx.type == 'payin';

                          return GestureDetector(
                            onTap: () => _showTransactionDetails(tx),
                            child: Container(
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
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: (isCredit ? AppTheme.accent : AppTheme.primary).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isCredit
                                          ? Icons.south_west_rounded
                                          : (tx.type == 'offramp'
                                              ? Icons.account_balance_rounded
                                              : Icons.north_east_rounded),
                                      color: isCredit ? AppTheme.accent : AppTheme.primary,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tx.type.replaceAll('_', ' ').toUpperCase(),
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          tx.createdAt != null
                                              ? DateFormat('yyyy-MM-dd HH:mm').format(tx.createdAt!)
                                              : tx.reference,
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
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: isCredit ? AppTheme.accent : Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        tx.status.toUpperCase(),
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: tx.isCompleted
                                              ? AppTheme.accent
                                              : (tx.isFailed ? AppTheme.error : AppTheme.warning),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
