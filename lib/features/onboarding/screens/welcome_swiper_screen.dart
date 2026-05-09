import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voyage_app/main.dart';
import 'package:voyage_app/core/theme/app_theme.dart';

class WelcomeSwiperScreen extends StatefulWidget {
  const WelcomeSwiperScreen({super.key});

  @override
  State<WelcomeSwiperScreen> createState() => _WelcomeSwiperScreenState();
}

class _WelcomeSwiperScreenState extends State<WelcomeSwiperScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, String>> _onboardingData = [
    {
      'title': 'Explorez le Monde',
      'subtitle':
          'Découvrez les plus beaux endroits de la planète et planifiez votre prochaine aventure.',
      'image': 'assets/images/onboarding1.jpg',
      'tag': 'Destinations',
    },
    {
      'title': 'Préparez votre Voyage',
      'subtitle':
          'Notre IA vous crée un itinéraire sur-mesure, adapté à vos envies et votre budget.',
      'image': 'assets/images/onboarding2.jpg',
      'tag': 'Planification',
    },
    {
      'title': 'Prêt à Partir ?',
      'subtitle':
          'Rejoignez des milliers de voyageurs et vivez une expérience premium dès aujourd\'hui.',
      'image': 'assets/images/onboarding3.jpg',
      'tag': 'Aventure',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
      );
    }
  }

  void _onPageChanged(int index) {
    _fadeController.reset();
    setState(() => _currentPage = index);
    _fadeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkNavy,
      body: Stack(
        children: [
          // ── Background Images PageView
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _onboardingData.length,
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    _onboardingData[index]['image']!,
                    fit: BoxFit.cover,
                  ),
                  // Overlay bleu océan → transparent → bleu océan
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x14B3E5FC), // bleu ciel très doux en haut
                          Colors.transparent,
                          Color(0x8C0E2D4A), // bleu océan semi-transparent
                          Color(0xEB0E2D4A), // bleu océan opaque
                          Color(0xFF0E2D4A), // bleu océan plein
                        ],
                        stops: [0.0, 0.22, 0.52, 0.78, 1.0],
                      ),
                    ),
                  ),
                  // Vignette latérale subtile
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0x260E2D4A),
                          Colors.transparent,
                          Colors.transparent,
                          Color(0x260E2D4A),
                        ],
                        stops: [0.0, 0.15, 0.85, 1.0],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // ── Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tag badge
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.skyBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: AppTheme.skyBlue.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppTheme.skyBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _onboardingData[_currentPage]['tag']!,
                            style: TextStyle(
                              color: AppTheme.skyBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, animation) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.12),
                          end: Offset.zero,
                        ).animate(animation),
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      _onboardingData[_currentPage]['title']!,
                      key: ValueKey('title_$_currentPage'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Subtitle
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: Text(
                      _onboardingData[_currentPage]['subtitle']!,
                      key: ValueKey('sub_$_currentPage'),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.72),
                        fontSize: 15,
                        height: 1.6,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Page indicators + Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Indicateurs de page
                      Row(
                        children: List.generate(
                          _onboardingData.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.only(right: 7),
                            height: 6,
                            width: _currentPage == index ? 28 : 6,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? AppTheme.skyBlue
                                  : Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),

                      // Boutons
                      Row(
                        children: [
                          if (_currentPage < _onboardingData.length - 1)
                            TextButton(
                              onPressed: _completeOnboarding,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              child: Text(
                                'Passer',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.45),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          else
                            const SizedBox.shrink(),

                          const SizedBox(width: 8),

                          // Bouton principal avec dégradé bleu ciel
                          GestureDetector(
                            onTap: () {
                              if (_currentPage < _onboardingData.length - 1) {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeInOut,
                                );
                              } else {
                                _completeOnboarding();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 15,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF4DB6E8), // Bleu ciel
                                    Color(0xFF1A7EC8), // Bleu océan
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4DB6E8)
                                        .withOpacity(0.40),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _currentPage == _onboardingData.length - 1
                                        ? 'Commencer'
                                        : 'Suivant',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
