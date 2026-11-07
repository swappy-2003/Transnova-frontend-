import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/wallet_provider.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showEditServerDialog(BuildContext context) {
    final textController = TextEditingController(text: ApiConfig.baseUrl);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          'API Server URL',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: 'e.g. http://localhost:5001',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => nav.pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ApiConfig.setBaseUrl(textController.text.trim());
              nav.pop();
              scaffoldMessenger.showSnackBar(
                SnackBar(content: Text('API URL updated to: ${ApiConfig.baseUrl}')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required String label,
    required String value,
    bool canCopy = false,
    BuildContext? context,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (canCopy && context != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$label copied')),
                      );
                    },
                    child: const Icon(Icons.copy, size: 16, color: AppTheme.primary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final walletProvider = context.watch<WalletProvider>();
    final txProvider = context.read<TransactionProvider>();
    final user = authProvider.user;
    final wallet = walletProvider.wallet;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Section
              _buildSectionHeader('User Account'),
              _buildInfoTile(
                label: 'Name',
                value: user?.displayName.isNotEmpty == true ? user!.displayName : 'Not set',
              ),
              _buildInfoTile(
                label: 'Email',
                value: user?.email ?? 'Unknown',
              ),
              _buildInfoTile(
                label: 'Firebase UID',
                value: user?.firebaseUid ?? '',
                canCopy: true,
                context: context,
              ),

              const SizedBox(height: 16),
              // Circle Wallet Section
              _buildSectionHeader('Circle Developer-Controlled Wallet'),
              _buildInfoTile(
                label: 'Blockchain',
                value: wallet?.blockchain ?? 'MATIC-AMOY',
              ),
              _buildInfoTile(
                label: 'Account Type',
                value: wallet?.accountType ?? 'SCA (Smart Contract)',
              ),
              _buildInfoTile(
                label: 'Circle Wallet ID',
                value: wallet?.effectiveWalletId ?? 'None',
                canCopy: true,
                context: context,
              ),
              _buildInfoTile(
                label: 'Circle Address',
                value: wallet?.effectiveAddress ?? 'None',
                canCopy: true,
                context: context,
              ),

              const SizedBox(height: 16),
              // Server Config
              _buildSectionHeader('Backend Environment'),
              GestureDetector(
                onTap: () => _showEditServerDialog(context),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.dns_rounded, size: 20, color: AppTheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Backend Server URL',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ApiConfig.baseUrl,
                              style: GoogleFonts.sourceCodePro(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.edit_outlined, size: 18, color: AppTheme.textMuted),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 36),
              // Logout button
              ElevatedButton.icon(
                onPressed: () async {
                  final nav = Navigator.of(context);
                  await authProvider.logout();
                  walletProvider.clear();
                  txProvider.clear();

                  nav.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error.withValues(alpha: 0.15),
                  foregroundColor: AppTheme.error,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppTheme.error),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
