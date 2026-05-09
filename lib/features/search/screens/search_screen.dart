import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voyage_app/core/theme/app_theme.dart';
import 'package:voyage_app/features/detail/screens/detail_screen.dart';
import 'package:voyage_app/features/favoris/services/favoris_service.dart';
import 'package:voyage_app/features/profile/screens/profile_screen.dart';
import 'package:voyage_app/features/voyage/screens/mes_voyages_screen.dart';
import 'package:voyage_app/features/recommandations/screens/recommandations_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _searchFocusNode = FocusNode();

  List<Map<String, dynamic>> _results = [];
  List<Map<String, dynamic>> _allVilles = [];
  bool _loading = false;
  String _selectedBudget = '';
  String _selectedContinent = '';
  List<String> _favorisIds = [];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _searchFocusNode.addListener(() => setState(() {}));
    _loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final villes = await _supabase
        .from('villes')
        .select('*, pays(nom, continent, langue, monnaie, climat)')
        .order('popularite', ascending: false);
    final favIds = await FavorisService.getFavorisIds();
    if (mounted) {
      setState(() {
        _allVilles = List<Map<String, dynamic>>.from(villes);
        _results = _allVilles;
        _favorisIds = favIds;
        _loading = false;
      });
      _fadeController.forward();
    }
  }

  void _filter() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _results = _allVilles.where((v) {
        final matchQ =
            q.isEmpty ||
            (v['nom'] ?? '').toLowerCase().contains(q) ||
            (v['pays']?['nom'] ?? '').toLowerCase().contains(q);
        final matchB =
            _selectedBudget.isEmpty || v['niveau_budget'] == _selectedBudget;
        final matchC =
            _selectedContinent.isEmpty ||
            v['pays']?['continent'] == _selectedContinent;
        return matchQ && matchB && matchC;
      }).toList();
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FF),
      resizeToAvoidBottomInset: false, // Prevents bottom overflow with keyboard
      bottomNavigationBar: _buildBottomNav(),
      body: Stack(
        children: [
          // Background clair
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF4F9FF),
                  Color(0xFFEBF5FB),
                  Color(0xFFF0F8FF),
                ],
              ),
            ),
          ),
          // Content
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeroHeader()),
                SliverToBoxAdapter(child: _buildFilters()),
                SliverToBoxAdapter(child: _buildResultsCount()),
                if (_loading)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const CircularProgressIndicator(
                              color: AppTheme.limeGreen,
                              strokeWidth: 2.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Chargement des destinations...',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_results.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(),
                  )
                else
                  SliverFadeTransition(
                    opacity: _fadeAnimation,
                    sliver: SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      sliver: SliverList.builder(
                        itemCount: _results.length,
                        itemBuilder: (_, i) => _buildResultCard(_results[i], i),
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

  // ─────────────────────────────────────────────
  // HERO IMAGE HEADER with floating search bar
  // ─────────────────────────────────────────────
  Widget _buildHeroHeader() {
    return SizedBox(
      height: 290,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Background image with rounded bottom ──
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  Image.asset(
                    'assets/images/explore_bg.jpg',
                    fit: BoxFit.cover,
                  ),
                  // Dark gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.25),
                          Colors.black.withOpacity(0.1),
                          Colors.black.withOpacity(0.45),
                          Colors.black.withOpacity(0.78),
                        ],
                        stops: const [0.0, 0.3, 0.6, 1.0],
                      ),
                    ),
                  ),
                  // ── Top row: back button + optional icon ──
                  Positioned(
                    top: 12,
                    left: 20,
                    right: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back button
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Globe icon right
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white.withOpacity(0.15)),
                              ),
                              child: const Icon(
                                Icons.public_rounded,
                                color: AppTheme.limeGreen,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ── Title + subtitle in lower-left area of image ──
                  Positioned(
                    bottom: 60, // Shifted up since image now fills entire height
                    left: 24,
                    right: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Explorer',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Trouvez votre prochaine aventure',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── Floating search bar at bottom edge ──
          Positioned(
            bottom: 0,
            left: 24,
            right: 24,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: _searchFocusNode.hasFocus
                    ? [
                        BoxShadow(
                          color: AppTheme.limeGreen.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: _searchFocusNode.hasFocus
                          ? Colors.white.withOpacity(0.12)
                          : Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: _searchFocusNode.hasFocus
                            ? AppTheme.limeGreen.withOpacity(0.6)
                            : Colors.white.withOpacity(0.2),
                        width: _searchFocusNode.hasFocus ? 1.5 : 1.0,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: (_) => _filter(),
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ville, pays...',
                        filled: true,
                        fillColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Colors.white.withOpacity(_searchFocusNode.hasFocus ? 0.9 : 0.6),
                          size: 22,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: Colors.white.withOpacity(0.6),
                                  size: 20,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _filter();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BOTTOM NAVIGATION BAR
  // ─────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 8, top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: const Color(0xFF4DB6E8).withOpacity(0.10)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
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
    // Current screen is always Explorer (index 1)
    final isActive = 1 == index;
    return GestureDetector(
      onTap: () {
        if (isActive) return;
        if (index == 0) {
          // Go back to Home
          Navigator.pop(context);
        } else if (index == 3) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MesVoyagesScreen()));
        } else if (index == 4) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
        }
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? const Color(0xFF4DB6E8) : const Color(0xFF4A6580).withOpacity(0.45),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? const Color(0xFF4DB6E8) : const Color(0xFF4A6580).withOpacity(0.45),
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isActive ? 4 : 0,
              height: isActive ? 4 : 0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? const Color(0xFF4DB6E8) : Colors.transparent,
              ),
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
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF4DB6E8), Color(0xFF1A7EC8)]),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4DB6E8).withOpacity(0.4),
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

  // ─────────────────────────────────────────────
  // FILTERS
  // ─────────────────────────────────────────────
  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Budget filter
          Padding(
            padding: const EdgeInsets.only(left: 24, bottom: 10),
            child: const Text(
              '💰 Budget',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A6580),
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              physics: const BouncingScrollPhysics(),
              children: ['', 'Faible', 'Moyen', 'Élevé'].map((b) {
                final selected = _selectedBudget == b;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedBudget = b);
                      _filter();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF4DB6E8)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF4DB6E8)
                              : const Color(0xFF4DB6E8).withOpacity(0.2),
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF4DB6E8).withOpacity(0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [],
                      ),
                      child: Text(
                        b.isEmpty ? 'Tous' : b,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : const Color(0xFF4A6580),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          // Continent filter
          Padding(
            padding: const EdgeInsets.only(left: 24, bottom: 10),
            child: const Text(
              '🌍 Continent',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A6580),
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              physics: const BouncingScrollPhysics(),
              children: ['', 'Afrique', 'Asie', 'Europe', 'Amérique', 'Océanie'].map((c) {
                final selected = _selectedContinent == c;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedContinent = c);
                      _filter();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF4DB6E8)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF4DB6E8)
                              : const Color(0xFF4DB6E8).withOpacity(0.2),
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF4DB6E8).withOpacity(0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [],
                      ),
                      child: Text(
                        c.isEmpty ? 'Tous' : c,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : const Color(0xFF4A6580),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // RESULTS COUNT
  // ─────────────────────────────────────────────
  Widget _buildResultsCount() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF4A6580),
                fontFamily: 'Poppins',
              ),
              children: [
                TextSpan(
                  text: '${_results.length}',
                  style: const TextStyle(
                    color: Color(0xFF4DB6E8),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                TextSpan(
                  text: ' destination${_results.length > 1 ? 's' : ''} trouvée${_results.length > 1 ? 's' : ''}',
                ),
              ],
            ),
          ),
          // Sort icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEBF5FB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.sort_rounded,
              color: Color(0xFF4A6580),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // EMPTY STATE
  // ─────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.explore_off_rounded,
              color: Colors.white.withOpacity(0.15),
              size: 56,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Aucune destination trouvée',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez de modifier vos filtres',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedBudget = '';
                _selectedContinent = '';
                _searchController.clear();
              });
              _filter();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.limeGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.limeGreen.withOpacity(0.3)),
              ),
              child: const Text(
                'Réinitialiser les filtres',
                style: TextStyle(
                  color: AppTheme.limeGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // RESULT CARD (Premium full-image style)
  // ─────────────────────────────────────────────
  Widget _buildResultCard(Map<String, dynamic> ville, int index) {
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

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 80).clamp(0, 400)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetailScreen(ville: ville)),
          );
        },
        child: Container(
          height: 200,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Full image background
                CachedNetworkImage(
                  imageUrl: ville['image_url'] ?? '',
                  fit: BoxFit.cover,
                  memCacheWidth: 400, // Optimize memory
                  placeholder: (_, __) => Container(
                    color: AppTheme.darkNavyLight,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.limeGreen,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: AppTheme.darkNavyLight,
                    child: Icon(
                      Icons.image_outlined,
                      color: Colors.white.withOpacity(0.2),
                      size: 40,
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
                        Colors.black.withOpacity(0.05),
                        Colors.transparent,
                        Colors.black.withOpacity(0.4),
                        Colors.black.withOpacity(0.9),
                      ],
                      stops: const [0.0, 0.25, 0.6, 1.0],
                    ),
                  ),
                ),
                // Top-left: star rating
                Positioned(
                  top: 16,
                  left: 16,
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
                            const SizedBox(width: 4),
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
                // Top-right: heart icon
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: () => _toggleFavoris(ville),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: isFav
                                ? AppTheme.coral.withOpacity(0.3)
                                : Colors.black.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isFav
                                  ? AppTheme.coral.withOpacity(0.5)
                                  : Colors.white.withOpacity(0.12),
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
                // Bottom content
                Positioned(
                  bottom: 18,
                  left: 18,
                  right: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ville['nom'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.white.withOpacity(0.6), size: 13),
                          const SizedBox(width: 4),
                          Text(
                            '${ville['pays']?['nom'] ?? ''} · ${ville['pays']?['continent'] ?? ''}',
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
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
                                MaterialPageRoute(
                                  builder: (_) => DetailScreen(ville: ville),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Color(0xFF0F1B2D),
                                    size: 14,
                                  ),
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
        ),
      ),
    );
  }
}
