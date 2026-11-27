import 'dart:async';
import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class PromoSlideData {
  final String badge;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const PromoSlideData({
    required this.badge,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

/// IntPay-styled Obsidian & Yellow Rewards Promo Carousel
class PromoBanner extends StatefulWidget {
  final VoidCallback onTransfer;
  final VoidCallback onTopUp;
  final VoidCallback onRemit;

  const PromoBanner({
    super.key,
    required this.onTransfer,
    required this.onTopUp,
    required this.onRemit,
  });

  @override
  State<PromoBanner> createState() => _PromoBannerState();
}

class _PromoBannerState extends State<PromoBanner> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoPlayTimer;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final nextPage = (_currentPage + 1) % 3;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = [
      PromoSlideData(
        badge: '0% Gas Fee',
        icon: Icons.bolt_rounded,
        title: 'Zero Gas Markup',
        subtitle: 'On Polygon Amoy USDC transfers this week',
        onTap: widget.onTransfer,
      ),
      PromoSlideData(
        badge: 'Instant UPI',
        icon: Icons.flash_on_rounded,
        title: 'Instant INR Top-Up',
        subtitle: 'Deposit via UPI & RuPay with Razorpay',
        onTap: widget.onTopUp,
      ),
      PromoSlideData(
        badge: 'Global Remit',
        icon: Icons.public_rounded,
        title: 'INR → USDC → USD Bank',
        subtitle: 'Multi-hop cross-border ACH payouts',
        onTap: widget.onRemit,
      ),
    ];

    return Column(
      children: [
        SizedBox(
          height: 82,
          child: PageView.builder(
            controller: _pageController,
            itemCount: slides.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final slide = slides[index];
              return GestureDetector(
                onTap: slide.onTap,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.brandBlack,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppTheme.rewardYellow,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(slide.icon, color: AppTheme.brandBlack, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    slide.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.uiStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.rewardYellow,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    slide.badge,
                                    style: AppTheme.uiStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.brandBlack,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              slide.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.uiStyle(
                                fontSize: 13,
                                color: AppTheme.darkSurfaceVariantText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppTheme.darkSurfaceVariantText,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(slides.length, (index) {
            final isCurrent = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isCurrent ? 18 : 6,
              height: 5,
              decoration: BoxDecoration(
                color: isCurrent ? AppTheme.brandBlack : AppTheme.border,
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
  }
}
