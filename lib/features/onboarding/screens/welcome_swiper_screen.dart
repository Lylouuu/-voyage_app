import 'package:flutter/material.dart';
import 'package:voyage_app/main.dart'; // Pour AuthWrapper

class WelcomeSwiperScreen extends StatefulWidget {
  const WelcomeSwiperScreen({super.key});

  @override
  State<WelcomeSwiperScreen> createState() => _WelcomeSwiperScreenState();
}

class _WelcomeSwiperScreenState extends State<WelcomeSwiperScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Optionnel: on peut forcer le chargement en RAM des images quand l'écran démarre
    // pour garantir 0 délai lors du Swipe
    precacheImage(const AssetImage("assets/images/onboarding1.jpg"), context);
    precacheImage(const AssetImage("assets/images/onboarding2.jpg"), context);
    precacheImage(const AssetImage("assets/images/onboarding3.jpg"), context);
  }

  // Données de l'onboarding configurées explicitement pour VOS fichiers locaux
  final List<Map<String, dynamic>> _pages = [
    {
      "title": "Discover Your\nNext Journey",
      "subtitle": "Explore the world's most beautiful destinations curated just for you.",
      "media": "assets/images/onboarding1.jpg", 
      "titleSize": 38.0,
      "alignment": Alignment.center, // Bateaux centrés
    },
    {
      "title": "Smart AI\nRecommendations",
      "subtitle": "Get personalized travel packages based on your unique preferences.",
      "media": "assets/images/onboarding2.jpg", 
      "titleSize": 32.0,
      "alignment": Alignment.center, // Centré ou légèrement vers le bas. Les girafes au centre
    },
    {
      "title": "Plan Your\nTrip Easily",
      "subtitle": "Plan and manage your entire trip seamlessly in one place.",
      "media": "assets/images/onboarding3.jpg", 
      "titleSize": 38.0,
      // Le sphinx est très à gauche sur l'image paysage, on aligne donc le visuel sur la gauche !
      "alignment": Alignment.centerLeft, 
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNextTap() {
    if (_currentPage == _pages.length - 1) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, __, ___) => const AuthWrapper(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color nightBlue = Color(0xFF131936);

    return Scaffold(
      backgroundColor: nightBlue,
      body: Stack(
        children: [
          // Le Swiper (PageView)
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              final page = _pages[index];
              
              // Alignement spécifique par image :
              // - Girafes (index 1) : remonter pour ne pas couper les têtes
              // - Pyramides (index 2) : image paysage, centrer le sujet
              Alignment imgAlignment;
              if (index == 1) {
                imgAlignment = const Alignment(0, -0.3); // Girafes : montre les têtes
              } else if (index == 2) {
                imgAlignment = Alignment.center; // Nouvelle image portrait : centré
              } else {
                imgAlignment = Alignment.center;
              }

              return Stack(
                fit: StackFit.expand,
                children: [
                  // Images déjà compressées (1080px) -> chargement rapide et fluide
                  Image.asset(
                    page["media"]!,
                    fit: BoxFit.cover,
                    alignment: imgAlignment,
                    gaplessPlayback: true,
                  ),
                  
                  // Couche de dégradé sombre (Overlay)
                  // Pour la 2ème slide, le dégradé est inversé (sombre en haut) 
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: index == 1 ? Alignment.bottomCenter : Alignment.topCenter,
                        end: index == 1 ? Alignment.topCenter : Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                          nightBlue.withOpacity(0.95),
                        ],
                        stops: const [0.4, 0.75, 1.0],
                      ),
                    ),
                  ),

                  // Texte superposé
                  // Pour la 2ème slide : en haut. Pour les autres : en bas.
                  Positioned(
                    top: index == 1 ? 80 : null,
                    bottom: index == 1 ? null : (index == 0 ? 120 : 150),
                    left: 30,
                    right: 30,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          page["title"]!,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: page["titleSize"], 
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page["subtitle"]!,
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
              );
            },
          ),
          
          // Contrôles en bas (Indicateurs de page + Bouton)
          Positioned(
            bottom: 40,
            left: 30,
            right: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 8),
                      height: 8,
                      width: _currentPage == index ? 28 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? const Color(0xFFC4E538) : Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _onNextTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.fastOutSlowIn,
                    height: 60,
                    width: _currentPage == _pages.length - 1 ? 160 : 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC4E538),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC4E538).withOpacity(0.5),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _currentPage == _pages.length - 1
                          ? const Text(
                              "Commencer",
                              style: TextStyle(
                                color: Color(0xFF131936),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : const Icon(
                              Icons.arrow_forward_rounded,
                              color: Color(0xFF131936),
                              size: 24,
                            ),
                    ),
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
