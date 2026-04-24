import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voyage_app/core/theme/app_theme.dart';
import 'package:voyage_app/features/detail/screens/detail_screen.dart';
import 'package:voyage_app/features/profile/screens/profile_screen.dart';
import 'package:voyage_app/features/search/screens/search_screen.dart';
import 'package:voyage_app/features/voyage/screens/create_voyage_screen.dart';
import 'package:voyage_app/features/voyage/screens/mes_voyages_screen.dart';
import 'package:voyage_app/features/recommandations/screens/recommandations_screen.dart';
import 'package:voyage_app/features/favoris/services/favoris_service.dart';
import 'package:voyage_app/features/favoris/screens/favoris_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  String _nom = '';
  List<Map<String, dynamic>> _villes = [];
  bool _loading = true;
  int _currentIndex = 0;

  // Carousel controllers
  late PageController _destPageController;
  int _currentDestPage = 0;

  // Tinder swipe state
  int _currentCardIndex = 0;
  Offset _cardOffset = Offset.zero;
  double _cardAngle = 0;
  bool _isSwiping = false;

  // Continent filter
  String _selectedContinent = 'Tous';
  final List<Map<String, String>> _continents = [
    {'emoji': '🌍', 'label': 'Tous'},
    {'emoji': '🌍', 'label': 'Afrique'},
    {'emoji': '🌏', 'label': 'Asie'},
    {'emoji': '🌎', 'label': 'Amérique'},
    {'emoji': '🌐', 'label': 'Europe'},
    {'emoji': '🏝️', 'label': 'Océanie'},
  ];

  // Favoris
  List<String> _favorisIds = [];

  // Animation
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _destPageController = PageController(viewportFraction: 0.65, initialPage: 0);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _loadData();
  }

  @override
  void dispose() {
    _destPageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      final userData = await _supabase
          .from('utilisateurs')
          .select('nom')
          .eq('id', user.id)
          .single();
      final villes = await _supabase
          .from('villes')
          .select('*, pays(nom, continent, langue, monnaie, climat)')
          .order('popularite', ascending: false);
      final favIds = await FavorisService.getFavorisIds();
      if (mounted) {
        setState(() {
          _nom = userData['nom'] ?? '';
          _villes = List<Map<String, dynamic>>.from(villes);
          _favorisIds = favIds;
          _loading = false;
        });
        _fadeController.forward();
      }
    }
  }

  Future<void> _signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> _toggleFavoris(Map<String, dynamic> ville) async {
    final id = ville['id'].toString();
    final nom = ville['nom'] ?? '';
    if (_favorisIds.contains(id)) {
      await FavorisService.supprimerFavoris(id);
      setState(() => _favorisIds.remove(id));
    } else {
      await FavorisService.ajouterFavoris(id, nom);
      setState(() => _favorisIds.add(id));
    }
  }

  List<Map<String, dynamic>> get _filteredVilles {
    if (_selectedContinent == 'Tous') return _villes;
    return _villes.where((v) {
      final continent = v['pays']?['continent'] ?? '';
      return continent.toLowerCase().contains(_selectedContinent.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkNavy,
      body: _currentIndex == 4
          ? const ProfileScreen()
          : _loading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const CircularProgressIndicator(
                          color: AppTheme.limeGreen,
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Chargement...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    // Background gradient
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF0F1B2D),
                            Color(0xFF0A1628),
                            Color(0xFF0D1F3C),
                          ],
                        ),
                      ),
                    ),
                    // Content
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: RefreshIndicator(
                        color: AppTheme.limeGreen,
                        backgroundColor: AppTheme.darkNavyLight,
                        onRefresh: _loadData,
                        child: CustomScrollView(
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            _buildHeader(),
                            _buildSearchBar(),
                            _buildRecommandations(),
                            _buildCreateVoyageCTA(),
                            _buildDestinationsSection(),
                            const SliverToBoxAdapter(child: SizedBox(height: 100)),
                          ],
                        ),
                      ),
                    ),
                    // Bottom nav
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _buildBottomNav(),
                    ),
                  ],
                ),
    );
  }

  // ─────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────
  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: avatar + notification
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Avatar
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.limeGreen.withOpacity(0.8),
                        AppTheme.primary.withOpacity(0.6),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _nom.isNotEmpty ? _nom[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Notification + logout
                Row(
                  children: [
                    _buildGlassIconButton(
                      icon: Icons.notifications_none_rounded,
                      onTap: () {},
                    ),
                    const SizedBox(width: 10),
                    _buildGlassIconButton(
                      icon: Icons.logout_rounded,
                      onTap: _signOut,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),
            // Title
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                  fontFamily: 'Poppins',
                ),
                children: [
                  const TextSpan(text: 'Discover Your Next\n'),
                  const TextSpan(text: 'Journey '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.limeGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'with AI',
                        style: TextStyle(
                          color: Color(0xFF0F1B2D),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                  TextSpan(
                    text: ', $_nom',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassIconButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SEARCH BAR (Glassmorphism)
  // ─────────────────────────────────────────────
  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.5), size: 22),
                    const SizedBox(width: 12),
                    Text(
                      'Rechercher une destination...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.tune_rounded, color: Colors.white.withOpacity(0.4), size: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TINDER-STYLE STACKED CARDS
  // ─────────────────────────────────────────────
  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _cardOffset += details.delta;
      _cardAngle = _cardOffset.dx * 0.0015;
    });
  }

  void _onPanEnd(DragEndDetails details, List<Map<String, dynamic>> cards) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (_cardOffset.dx.abs() > screenWidth * 0.3) {
      // Swipe away
      final direction = _cardOffset.dx > 0 ? 1.0 : -1.0;
      setState(() => _isSwiping = true);
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _currentCardIndex = (_currentCardIndex + 1) % cards.length;
            _cardOffset = Offset.zero;
            _cardAngle = 0;
            _isSwiping = false;
          });
        }
      });
      setState(() {
        _cardOffset = Offset(direction * screenWidth * 1.5, _cardOffset.dy);
        _cardAngle = direction * 0.4;
      });
    } else {
      // Snap back
      setState(() {
        _cardOffset = Offset.zero;
        _cardAngle = 0;
      });
    }
  }

  Widget _buildRecommandations() {
    final top = _villes.take(5).toList();
    if (top.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '⭐ Recommandées pour vous',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Voir tout',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.limeGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Stacked cards
          SizedBox(
            height: 380,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Back cards (show 2 behind)
                for (int i = 2; i >= 0; i--)
                  if (i > 0)
                    _buildStackedBackCard(top, i),
                // Front card (swipeable)
                _buildSwipeableFrontCard(top),
              ],
            ),
          ),
          // Card counter
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(top.length, (i) {
                  final isActive = (_currentCardIndex % top.length) == i;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.limeGreen
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStackedBackCard(List<Map<String, dynamic>> cards, int stackIndex) {
    final cardIdx = (_currentCardIndex + stackIndex) % cards.length;
    final ville = cards[cardIdx];
    final scale = 1.0 - (stackIndex * 0.06);
    final yOffset = -(stackIndex * 16.0);

    return Positioned(
      top: 0,
      left: 24,
      right: 24,
      bottom: 0,
      child: Transform.translate(
        offset: Offset(0, yOffset),
        child: Transform.scale(
          scale: scale,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: 1.0 - (stackIndex * 0.2),
            child: _buildTinderCard(ville, interactive: false),
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeableFrontCard(List<Map<String, dynamic>> cards) {
    final cardIdx = _currentCardIndex % cards.length;
    final ville = cards[cardIdx];

    return Positioned(
      top: 0,
      left: 24,
      right: 24,
      bottom: 0,
      child: GestureDetector(
        onPanUpdate: _onPanUpdate,
        onPanEnd: (details) => _onPanEnd(details, cards),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetailScreen(ville: ville)),
          );
        },
        child: AnimatedContainer(
          duration: _isSwiping
              ? const Duration(milliseconds: 200)
              : const Duration(milliseconds: 0),
          curve: Curves.easeOut,
          transform: Matrix4.identity()
            ..translate(_cardOffset.dx, _cardOffset.dy * 0.3)
            ..rotateZ(_cardAngle),
          transformAlignment: Alignment.center,
          child: _buildTinderCard(ville, interactive: true),
        ),
      ),
    );
  }

  Widget _buildTinderCard(Map<String, dynamic> ville, {required bool interactive}) {
    final budget = ville['niveau_budget'] ?? '';
    final budgetColor = budget == 'Faible'
        ? const Color(0xFF4CAF50)
        : budget == 'Élevé'
            ? const Color(0xFFFF6B6B)
            : const Color(0xFFFFD97D);
    final isFav = _favorisIds.contains(ville['id'].toString());

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            CachedNetworkImage(
              imageUrl: ville['image_url'] ?? '',
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: AppTheme.darkNavyLight,
                child: const Center(
                  child: CircularProgressIndicator(color: AppTheme.limeGreen, strokeWidth: 2),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                color: AppTheme.darkNavyLight,
                child: Icon(Icons.image_outlined, color: Colors.white.withOpacity(0.3), size: 48),
              ),
            ),
            // Dark gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.05),
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.88),
                  ],
                  stops: const [0.0, 0.2, 0.55, 1.0],
                ),
              ),
            ),
            // Swipe hint overlays (only on front card)
            if (interactive && _cardOffset.dx.abs() > 30)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  color: _cardOffset.dx > 0
                      ? Colors.green.withOpacity((_cardOffset.dx.abs() / 200).clamp(0, 0.3))
                      : Colors.red.withOpacity((_cardOffset.dx.abs() / 200).clamp(0, 0.3)),
                ),
                child: Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 100),
                    opacity: (_cardOffset.dx.abs() / 150).clamp(0, 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _cardOffset.dx > 0 ? Colors.greenAccent : Colors.redAccent,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _cardOffset.dx > 0 ? '❤️ LIKE' : '✕ NOPE',
                        style: TextStyle(
                          color: _cardOffset.dx > 0 ? Colors.greenAccent : Colors.redAccent,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // Top-left: budget tag
            Positioned(
              top: 18,
              left: 18,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: budgetColor.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: budgetColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      budget,
                      style: TextStyle(
                        color: budgetColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Top-right: heart
            Positioned(
              top: 18,
              right: 18,
              child: GestureDetector(
                onTap: () => _toggleFavoris(ville),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isFav
                            ? AppTheme.coral.withOpacity(0.35)
                            : Colors.black.withOpacity(0.25),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isFav
                              ? AppTheme.coral.withOpacity(0.6)
                              : Colors.white.withOpacity(0.15),
                        ),
                      ),
                      child: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? AppTheme.coral : Colors.white.withOpacity(0.9),
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Bottom info
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ville['nom'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.white.withOpacity(0.7), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        ville['pays']?['nom'] ?? '',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.star_rounded, color: Color(0xFFFFD97D), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${ville['popularite'] ?? ''}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // CTA CARD — "Créer mon voyage"
  // ─────────────────────────────────────────────
  Widget _buildCreateVoyageCTA() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateVoyageScreen()),
            );
          },
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A3A5C),
                  Color(0xFF0D2240),
                  Color(0xFF162544),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D2240).withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
              ),
            ),
            child: Stack(
              children: [
                // Decorative circles
                Positioned(
                  right: -30,
                  top: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.limeGreen.withOpacity(0.06),
                    ),
                  ),
                ),
                Positioned(
                  right: 30,
                  bottom: -20,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primary.withOpacity(0.06),
                    ),
                  ),
                ),
                // Plane icon
                Positioned(
                  right: 20,
                  top: 20,
                  child: Icon(
                    Icons.flight_takeoff_rounded,
                    color: Colors.white.withOpacity(0.07),
                    size: 80,
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Planifiez votre',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Prochaine Aventure ✈️',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      // Button
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.limeGreen,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.limeGreen.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded, color: Color(0xFF0F1B2D), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Créer mon voyage',
                              style: TextStyle(
                                color: Color(0xFF0F1B2D),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
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
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // DESTINATIONS SECTION (Filter + Carousel)
  // ─────────────────────────────────────────────
  Widget _buildDestinationsSection() {
    final filtered = _filteredVilles;
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 28, 24, 16),
            child: Text(
              '🌍 Toutes les destinations',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          // Continent filters
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _continents.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (_, i) {
                final c = _continents[i];
                final isSelected = _selectedContinent == c['label'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedContinent = c['label']!;
                      _destPageController = PageController(viewportFraction: 0.65, initialPage: 0);
                      _currentDestPage = 0;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.limeGreen
                          : Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.limeGreen
                            : Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(c['emoji']!, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          c['label']!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFF0F1B2D)
                                : Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Destination carousel
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.explore_off_rounded, color: Colors.white.withOpacity(0.2), size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Aucune destination trouvée',
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 320,
              child: PageView.builder(
                controller: _destPageController,
                itemCount: filtered.length,
                onPageChanged: (i) => setState(() => _currentDestPage = i),
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: _destPageController,
                    builder: (context, child) {
                      double value = 1.0;
                      double parallaxOffset = 0.0;
                      if (_destPageController.position.haveDimensions) {
                        double pageOffset = (_destPageController.page ?? 0) - index;
                        value = (1 - (pageOffset.abs() * 0.22)).clamp(0.0, 1.0);
                        parallaxOffset = pageOffset * -30;
                      }
                      return Center(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: value < 0.9 ? 0.5 : 1.0,
                          child: Transform.scale(
                            scale: Curves.easeOut.transform(value),
                            child: _buildDestCard(filtered[index], parallaxOffset),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          // Page indicator
          if (filtered.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    filtered.length > 10 ? 10 : filtered.length,
                    (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _currentDestPage == i ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _currentDestPage == i
                              ? AppTheme.limeGreen
                              : Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDestCard(Map<String, dynamic> ville, double parallaxOffset) {
    final budget = ville['niveau_budget'] ?? '';
    final budgetColor = budget == 'Faible'
        ? const Color(0xFF4CAF50)
        : budget == 'Élevé'
            ? const Color(0xFFFF6B6B)
            : const Color(0xFFFFD97D);
    final budgetLabel = budget == 'Élevé'
        ? '💎 Élevé'
        : budget == 'Moyen'
            ? '💰 Moyen'
            : '🪙 Faible';
    final isFav = _favorisIds.contains(ville['id'].toString());

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image with parallax
            Transform.translate(
              offset: Offset(parallaxOffset, 0),
              child: CachedNetworkImage(
                imageUrl: ville['image_url'] ?? '',
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (_, __) => Container(
                  color: AppTheme.darkNavyLight,
                  child: const Center(
                    child: CircularProgressIndicator(color: AppTheme.limeGreen, strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppTheme.darkNavyLight,
                  child: Icon(Icons.image_outlined, color: Colors.white.withOpacity(0.3), size: 40),
                ),
              ),
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.9),
                  ],
                  stops: const [0.0, 0.35, 0.65, 1.0],
                ),
              ),
            ),
            // Heart top-right
            Positioned(
              top: 14,
              right: 14,
              child: GestureDetector(
                onTap: () => _toggleFavoris(ville),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isFav
                            ? AppTheme.coral.withOpacity(0.3)
                            : Colors.black.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isFav
                              ? AppTheme.coral.withOpacity(0.5)
                              : Colors.white.withOpacity(0.15),
                        ),
                      ),
                      child: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? AppTheme.coral : Colors.white.withOpacity(0.8),
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Star rating top-left
            Positioned(
              top: 14,
              left: 14,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFFD97D), size: 14),
                        const SizedBox(width: 3),
                        Text(
                          '${ville['popularite'] ?? ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Bottom info
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ville['nom'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.white.withOpacity(0.6), size: 12),
                      const SizedBox(width: 3),
                      Text(
                        ville['pays']?['nom'] ?? '',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Budget badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: budgetColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: budgetColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          budgetLabel,
                          style: TextStyle(
                            color: budgetColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      // Explore button
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => DetailScreen(ville: ville)),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.limeGreen,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.limeGreen.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Explore',
                                style: TextStyle(
                                  color: Color(0xFF0F1B2D),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_rounded, color: Color(0xFF0F1B2D), size: 14),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BOTTOM NAVIGATION BAR (Custom)
  // ─────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 8, top: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            index: 0,
            icon: Icons.home_rounded,
            activeIcon: Icons.home_rounded,
            label: 'Home',
          ),
          _buildNavItem(
            index: 1,
            icon: Icons.explore_outlined,
            activeIcon: Icons.explore,
            label: 'Explorer',
          ),
          _buildNavItem(
            index: 2,
            icon: Icons.favorite_border_rounded,
            activeIcon: Icons.favorite_rounded,
            label: 'Favoris',
          ),
          _buildNavAIButton(),
          _buildNavItem(
            index: 3,
            icon: Icons.luggage_outlined,
            activeIcon: Icons.luggage,
            label: 'Mes Voyages',
          ),
          _buildNavItem(
            index: 4,
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 1) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
        } else if (index == 2) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const FavorisScreen())).then((_) => _loadData());
        } else if (index == 3) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const MesVoyagesScreen()));
        } else if (index == 4) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
        } else {
          setState(() => _currentIndex = index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.limeGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive ? const Color(0xFF0F1B2D) : Colors.white.withOpacity(0.4),
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.limeGreen : Colors.white.withOpacity(0.35),
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavAIButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RecommandationsScreen()),
        );
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF7C3AED),
              Color(0xFF9F5AFF),
              Color(0xFFB47AFF),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.auto_awesome,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// AnimatedBuilder helper (listens to Listenable)
// ─────────────────────────────────────────────
class AnimatedBuilder extends StatelessWidget {
  final Listenable animation;
  final Widget Function(BuildContext, Widget?) builder;

  const AnimatedBuilder({super.key, required this.animation, required this.builder});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder_(animation: animation, builder: builder);
  }
}

class AnimatedBuilder_ extends StatefulWidget {
  final Listenable animation;
  final Widget Function(BuildContext, Widget?) builder;

  const AnimatedBuilder_({super.key, required this.animation, required this.builder});

  @override
  State<AnimatedBuilder_> createState() => _AnimatedBuilder_State();
}

class _AnimatedBuilder_State extends State<AnimatedBuilder_> {
  @override
  void initState() {
    super.initState();
    widget.animation.addListener(_handleChange);
  }

  @override
  void dispose() {
    widget.animation.removeListener(_handleChange);
    super.dispose();
  }

  void _handleChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, null);
  }
}
