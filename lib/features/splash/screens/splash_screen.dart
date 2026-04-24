import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voyage_app/main.dart'; // Pour AuthWrapper
import 'package:voyage_app/features/onboarding/screens/welcome_swiper_screen.dart'; // To Swiper

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _subtitleFadeAnim;
  late Animation<double> _progressAnim;
  late Animation<double> _iconMicroAnim;

  // Background colors from previous implementation (kept exactly as requested)
  static const _kNavy = Color(0xFF080D1A);
  
  // Premium accent colors
  static const _kSplashGreen = Color(0xFFC6FF3B);
  static const _kSplashCyan = Color(0xFF00D1FF);

  @override
  void initState() {
    super.initState();
    // Total duration ~2400ms for a premium feel
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // 1. Logo Fade out/in & Scale (600ms)
    // 600 / 2400 = 0.25
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
      ),
    );
    _scaleAnim = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
      ),
    );

    // 2. Subtitle Fade with slight delay (starts at ~360ms, ends ~840ms)
    _subtitleFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.35, curve: Curves.easeOut),
      ),
    );

    // 3. Airplane micro animation (elegant subtle drift over time)
    _iconMicroAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 1.0, curve: Curves.easeOutSine),
      ),
    );

    // 4. Progress bar fill smoothly across the bottom
    _progressAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Navigate on completion
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigate();
      }
    });

    // Start animation immediately
    Future.microtask(() {
      if (mounted) _controller.forward();
    });
  }

  Future<void> _navigate() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('has_seen_onboarding') ?? false;

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) =>
            hasSeen ? const AuthWrapper() : const WelcomeSwiperScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Smooth fade in + slide up transition
          final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOut),
          );
          final slide = Tween<Offset>(
            begin: const Offset(0.0, 0.02),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOut),
          );
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: slide,
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kNavy,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── EXACTLY UNCHANGED Background from previous ────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF04060C),
                  _kNavy,
                  Color(0xFF0D1730),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // Radial Light Center
          Center(
            child: Container(
              height: 400,
              width: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF26D0CE).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
          // ────────────────────────────────────────────────────────────────────

          // ── Premium Animations Layer ────────────────────────────────────────
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  // Center Content (Logo + Subtitle)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated Logo Block
                        Opacity(
                          opacity: _fadeAnim.value,
                          child: Transform.scale(
                            scale: _scaleAnim.value,
                            child: Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                // Subtle Neon Glow around text area
                                Container(
                                  width: 180,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: _kSplashGreen.withValues(alpha: 0.15),
                                        blurRadius: 36,
                                        spreadRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                                // Text Logo with airplane icon
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'NEX',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 46,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2.0,
                                      ),
                                    ),
                                    // Elegant micro-animated airplane
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Transform.translate(
                                        offset: Offset(
                                          _iconMicroAnim.value * 4.0, // slight slide right
                                          -_iconMicroAnim.value * 2.0, // slight slide up
                                        ),
                                        child: Transform.rotate(
                                          angle: 0.04 * _iconMicroAnim.value, // microscopic tilt
                                          child: const Icon(
                                            Icons.airplanemode_active_rounded,
                                            color: _kSplashGreen,
                                            size: 40,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Text(
                                      'RIP',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 46,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 14),
                        
                        // Fading Premium Subtitle
                        Opacity(
                          opacity: _subtitleFadeAnim.value,
                          child: Text(
                            'Your next trip starts here',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75), // 75% opacity as requested
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Loading line (2-3px gradient)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: _progressAnim.value,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_kSplashGreen, _kSplashCyan],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _kSplashGreen.withValues(alpha: 0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
