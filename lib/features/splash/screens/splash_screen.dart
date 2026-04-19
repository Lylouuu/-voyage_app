import 'package:flutter/material.dart';
import 'package:voyage_app/features/onboarding/screens/welcome_swiper_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _planeMovementY;
  late Animation<double> _onboardingSlideUp;
  bool _showOnboarding = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500), // Plus lent pour un effet "tirage"
    );

    // L'avion décolle vers le haut — il part en premier, plus vite
    _planeMovementY = Tween<double>(begin: 0, end: -600).animate(
      CurvedAnimation(
        parent: _controller,
        // L'avion commence dès le début et finit à 70% de l'animation
        curve: const Interval(0.0, 0.7, curve: Curves.easeInCubic),
      ),
    );

    // L'onboarding commence un tout petit peu après l'avion et monte plus doucement
    // Comme si l'avion le TIRE derrière lui
    _onboardingSlideUp = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        // Commence à 5% (léger retard derrière l'avion) et finit à 100%
        curve: const Interval(0.05, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Quand l'animation termine, on remplace proprement la route
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_navigated) {
        _navigated = true;
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: Duration.zero,
            pageBuilder: (_, __, ___) => const WelcomeSwiperScreen(),
          ),
        );
      }
    });

    // Pré-chargement de la première image d'onboarding pendant le temps d'attente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage("assets/images/onboarding1.jpg"), context);
    });

    // Après 1 seconde d'affichage du logo, on lance tout
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() => _showOnboarding = true);
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color nightBlue = Color(0xFF131936);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: nightBlue,
      body: Stack(
        children: [
          // Couche 1 : Le logo NexTrip au centre
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "NEX",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 45,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                    Transform.translate(
                      offset: Offset(0, _planeMovementY.value),
                      child: const Icon(
                        Icons.airplanemode_active,
                        color: Colors.white,
                        size: 47,
                      ),
                    ),
                    const Text(
                      "RIP",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 45,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Couche 2 : Panneau de prévisualisation qui monte derrière l'avion
          // On n'embarque PAS le vrai WelcomeSwiperScreen ici pour éviter les lags
          // On montre juste un panneau avec la 1ère image + le dégradé
          if (_showOnboarding)
            AnimatedBuilder(
              animation: _onboardingSlideUp,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, screenHeight * _onboardingSlideUp.value),
                  child: child,
                );
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // La 1ère image d'onboarding en aperçu
                  Image.asset(
                    "assets/images/onboarding1.jpg",
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    gaplessPlayback: true,
                  ),
                  // Dégradé sombre identique à l'onboarding
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                          nightBlue.withOpacity(0.95),
                        ],
                        stops: const [0.4, 0.75, 1.0],
                      ),
                    ),
                  ),
                  // Le texte de la 1ère slide
                  Positioned(
                    bottom: 120,
                    left: 30,
                    right: 30,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Discover Your\nNext Journey",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Explore the world's most beautiful destinations curated just for you.",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                            height: 1.5,
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
}
