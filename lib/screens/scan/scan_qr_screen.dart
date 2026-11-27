import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/wallet_provider.dart';
import '../home/widgets/receive_modal.dart';

/// IntPay-styled Scan & Pay Camera Screen
///
/// Requests device camera permission automatically on Android/iOS,
/// scans Polygon/USDC/email QR codes, and returns the parsed recipient
/// string to pre-fill the Transfer screen.
class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  late final AnimationController _laserController;
  bool _torchOn = false;
  bool _hasPopped = false;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _laserController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  /// Extracts a clean 0x address or email from raw QR payloads like
  /// `ethereum:0x1234...@80002?symbol=USDC` or plain `0x1234...`
  String _parseQrPayload(String raw) {
    var trimmed = raw.trim();
    if (trimmed.toLowerCase().startsWith('ethereum:')) {
      trimmed = trimmed.substring('ethereum:'.length);
    }
    final atIdx = trimmed.indexOf('@');
    // Keep email intact, but strip @chainId from EIP-681 addresses
    if (trimmed.startsWith('0x') && atIdx != -1) {
      trimmed = trimmed.substring(0, atIdx);
    }
    final qIdx = trimmed.indexOf('?');
    if (qIdx != -1) {
      trimmed = trimmed.substring(0, qIdx);
    }
    return trimmed.trim();
  }

  void _handleDetection(BarcodeCapture capture) {
    if (_hasPopped) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.trim().isNotEmpty) {
        _hasPopped = true;
        final parsed = _parseQrPayload(raw);
        Navigator.of(context).pop(parsed);
        break;
      }
    }
  }

  Future<void> _toggleTorch() async {
    try {
      await _scannerController.toggleTorch();
      if (mounted) {
        setState(() => _torchOn = !_torchOn);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Flashlight not available on this device.', style: AppTheme.uiStyle(color: Colors.white)),
          backgroundColor: AppTheme.brandBlack,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showManualEntryDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Enter QR / Wallet Address',
          style: AppTheme.displayStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          style: AppTheme.monoStyle(fontSize: 13),
          decoration: const InputDecoration(
            hintText: '0x... or user@email.com',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.brandBlack,
              minimumSize: const Size(90, 42),
              shape: const StadiumBorder(),
            ),
            child: const Text('Use'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && mounted && !_hasPopped) {
      _hasPopped = true;
      Navigator.of(context).pop(_parseQrPayload(result));
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.read<WalletProvider>();

    return Scaffold(
      backgroundColor: AppTheme.brandBlack,
      body: Stack(
        children: [
          // Live Camera Scanner Feed
          Positioned.fill(
            child: MobileScanner(
              controller: _scannerController,
              onDetect: _handleDetection,
              errorBuilder: (context, error) {
                return Container(
                  color: AppTheme.brandBlack,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFF191C19),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.darkBorder),
                        ),
                        child: const Icon(Icons.videocam_off_rounded, color: AppTheme.rewardYellow, size: 30),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Camera Access Needed',
                        style: AppTheme.displayStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        error.errorDetails?.message ?? 'Allow camera permission to scan Polygon & USDC QR codes.',
                        textAlign: TextAlign.center,
                        style: AppTheme.uiStyle(fontSize: 13, color: AppTheme.darkSurfaceVariantText),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton.icon(
                        onPressed: () => _scannerController.start(),
                        icon: const Icon(Icons.camera_alt_rounded, size: 18),
                        label: const Text('Open Camera'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: AppTheme.brandBlack,
                          minimumSize: const Size(180, 44),
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Dark scrim for crisp UI legibility
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: AppTheme.brandBlack.withValues(alpha: 0.35),
              ),
            ),
          ),

          // Foreground Overlay: Header + Viewfinder + Bottom Dock
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFF191C19),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.darkBorder),
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                      Text(
                        'Scan & Pay',
                        style: AppTheme.uiStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF191C19),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppTheme.darkBorder),
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
                              'Auto-FX',
                              style: AppTheme.uiStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Center QR Viewfinder
                Column(
                  children: [
                    SizedBox(
                      width: 240,
                      height: 240,
                      child: Stack(
                        children: [
                          // 4 Green Corner Brackets
                          _buildCorner(top: 0, left: 0, isTop: true, isLeft: true),
                          _buildCorner(top: 0, right: 0, isTop: true, isLeft: false),
                          _buildCorner(bottom: 0, left: 0, isTop: false, isLeft: true),
                          _buildCorner(bottom: 0, right: 0, isTop: false, isLeft: false),

                          // Animated Laser Line
                          AnimatedBuilder(
                            animation: _laserController,
                            builder: (context, _) {
                              return Positioned(
                                top: 16 + (_laserController.value * 206),
                                left: 14,
                                right: 14,
                                child: Container(
                                  height: 2.5,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary,
                                    borderRadius: BorderRadius.circular(999),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primary.withValues(alpha: 0.7),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Align any Polygon or USDC QR code',
                      style: AppTheme.uiStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.rewardYellow,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt_rounded, size: 16, color: AppTheme.brandBlack),
                          const SizedBox(width: 4),
                          Text(
                            'Instant zero-markup QR transfer',
                            style: AppTheme.uiStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.brandBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Bottom Scanner Controls Dock
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF191C19),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border(top: BorderSide(color: AppTheme.darkBorder)),
                  ),
                  child: Row(
                    children: [
                      _buildDockButton(
                        icon: _torchOn ? Icons.flashlight_off_rounded : Icons.flashlight_on_rounded,
                        label: 'Flashlight',
                        isActive: _torchOn,
                        onTap: _toggleTorch,
                      ),
                      const SizedBox(width: 10),
                      _buildDockButton(
                        icon: Icons.keyboard_rounded,
                        label: 'Enter Code',
                        onTap: _showManualEntryDialog,
                      ),
                      const SizedBox(width: 10),
                      _buildDockButton(
                        icon: Icons.qr_code_rounded,
                        label: 'My Code',
                        onTap: () => ReceiveModal.show(
                          context,
                          wallet.address,
                          wallet.qr?.rawPayload,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required bool isTop,
    required bool isLeft,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? const BorderSide(color: AppTheme.primary, width: 4) : BorderSide.none,
            bottom: !isTop ? const BorderSide(color: AppTheme.primary, width: 4) : BorderSide.none,
            left: isLeft ? const BorderSide(color: AppTheme.primary, width: 4) : BorderSide.none,
            right: !isLeft ? const BorderSide(color: AppTheme.primary, width: 4) : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: isTop && isLeft ? const Radius.circular(18) : Radius.zero,
            topRight: isTop && !isLeft ? const Radius.circular(18) : Radius.zero,
            bottomLeft: !isTop && isLeft ? const Radius.circular(18) : Radius.zero,
            bottomRight: !isTop && !isLeft ? const Radius.circular(18) : Radius.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildDockButton({
    required IconData icon,
    required String label,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.rewardYellow : const Color(0xFF242824),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive ? AppTheme.brandBlack : Colors.white,
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTheme.uiStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isActive ? AppTheme.brandBlack : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
