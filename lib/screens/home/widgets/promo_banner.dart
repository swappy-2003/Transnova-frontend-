import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme.dart';

class PromoSlideData {
  final String tag;
  final IconData tagIcon;
  final Color tagColor;
  final String title;
  final String subtitle;
  final String ctaText;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const PromoSlideData({
    required this.tag,
    required this.tagIcon,
    required this.tagColor,
    required this.title,
    required this.subtitle,
    required this.ctaText,
    required this.gradientColors,
    required this.onTap,
  });
}

/// Interactive Promotional Carousel with Auto-Play & Pagination Dots
///
/// Faithfully reproduces the "Today's Promotions" banner from Figma Image 5
/// with smooth swiping, decorative background elements, and animated indicator dots.
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
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
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
        tag: 'SPECIAL PROMO',
        tagIcon: Icons.local_fire_department_rounded,
        tagColor: const Color(0xFFFFEAA7),
        title: '0% Gas Fee on USDC\nTransfers this Week! 🚀',
        subtitle: 'Instant Polygon Amoy Smart Account transfers.',
        ctaText: 'Send USDC Now',
        gradientColors: const [Color(0xFFFF5252), Color(0xFFFF7675), Color(0xFFFAB1A0)],
        onTap: widget.onTransfer,
      ),
      PromoSlideData(
        tag: 'INSTANT DEPOSITS',
        tagIcon: Icons.flash_on_rounded,
        tagColor: const Color(0xFFFFD166),
        title: 'Instant UPI & RuPay\nTop-Up at Zero Fee ⚡',
        subtitle: 'Powered by Razorpay instant checkout.',
        ctaText: 'Top Up with UPI',
        gradientColors: const [Color(0xFF1E3C72), Color(0xFF2A5298), Color(0xFF4A90E2)],
        onTap: widget.onTopUp,
      ),
      PromoSlideData(
        tag: 'GLOBAL REMIT',
        tagIcon: Icons.public_rounded,
        tagColor: const Color(0xFFA8FF78),
        title: 'Cross-Border Transfers\nDirect to US Bank (ACH) 🌍',
        subtitle: 'Multi-hop pipeline from INR to USD.',
        ctaText: 'Explore Remittance',
        gradientColors: const [Color(0xFF6C5CE7), Color(0xFF8E44AD), Color(0xFFA29BFE)],
        onTap: widget.onRemit,
      ),
    ];

    return Column(
      children: [
        SizedBox(
          height: 172,
          child: PageView.builder(
            controller: _pageController,
            itemCount: slides.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final slide = slides[index];
              return _buildSlideCard(slide);
            },
          ),
        ),
        const SizedBox(height: 10),
        // Pagination dots matching Figma design
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(slides.length, (index) {
            final isCurrent = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isCurrent ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isCurrent ? AppTheme.primary : const Color(0xFFD2D6DC),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSlideCard(PromoSlideData slide) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: slide.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: slide.gradientColors.first.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorative circles
          Positioned(
            right: -25,
            bottom: -35,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 40,
            top: -20,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(slide.tagIcon, color: slide.tagColor, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          slide.tag,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slide.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    slide.subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: slide.onTap,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        slide.ctaText,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: slide.gradientColors.first,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, color: slide.gradientColors.first, size: 13),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
