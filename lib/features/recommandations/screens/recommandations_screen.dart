import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voyage_app/core/theme/app_theme.dart';
import 'package:voyage_app/features/detail/screens/detail_screen.dart';
import 'package:voyage_app/features/profile/screens/profile_screen.dart';
import 'package:voyage_app/features/search/screens/search_screen.dart';
import 'package:voyage_app/features/voyage/screens/mes_voyages_screen.dart';
import 'package:voyage_app/features/favoris/services/favoris_service.dart';

class RecommandationsScreen extends StatefulWidget {
  const RecommandationsScreen({super.key});

  @override
  State<RecommandationsScreen> createState() => _RecommandationsScreenState();
}

class _RecommandationsScreenState extends State<RecommandationsScreen> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _recommandations = [];
  Map<String, dynamic>? _prefs;
  bool _loading = true;

  late AnimationController _animController;
  late Animation<double> _fadeHeader;
  late Animation<double> _fadeInsight;
  late Animation<double> _fadeCards;
  late Animation<Offset> _slideCards;

  @override
  void initState() {
    super.initState();
    
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeHeader = CurvedAnimation(parent: _animController, curve: const Interval(0.0, 0.4, curve: Curves.easeOut));
    _fadeInsight = CurvedAnimation(parent: _animController, curve: const Interval(0.2, 0.6, curve: Curves.easeOut));
    _fadeCards = CurvedAnimation(parent: _animController, curve: const Interval(0.4, 1.0, curve: Curves.easeOut));
    
    _slideCards = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.4, 1.0, curve: Curves.easeOutQuart)),
    );

    _loadAndRecommend();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadAndRecommend() async {
    setState(() => _loading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Charger préférences
      final prefs = await _supabase
          .from('preferences')
          .select()
          .eq('id_user', user.id)
          .maybeSingle();

      if (prefs == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      // Charger toutes les villes
      final villes = await _supabase
          .from('villes')
          .select('*, pays(nom, continent)')
          .order('popularite', ascending: false);

      final villesList = List<Map<String, dynamic>>.from(villes);

      // Charger activités
      final activites = await _supabase
          .from('activites')
          .select('id_ville, categorie');

      final activitesList = List<Map<String, dynamic>>.from(activites);

      final centresInteret = List<String>.from(prefs['centres_interet'] ?? []);
      final budget = prefs['budget'] ?? '';
      final typeVoyage = prefs['type_voyage'] ?? '';

      final Map<String, List<String>> activitesParVille = {};
      for (final a in activitesList) {
        final idVille = a['id_ville'].toString();
        activitesParVille[idVille] ??= [];
        activitesParVille[idVille]!.add(a['categorie'] ?? '');
      }

      final scored = villesList.map((ville) {
        int score = 0;
        final idVille = ville['id'].toString();

        if (ville['niveau_budget'] == budget) score += 3;

        final cats = activitesParVille[idVille] ?? [];
        for (final interet in centresInteret) {
          if (cats.any(
            (c) =>
                c.toLowerCase().contains(interet.toLowerCase()) ||
                interet.toLowerCase().contains(c.toLowerCase()),
          )) {
            score += 2;
          }
        }

        final continent = ville['pays']?['continent'] ?? '';
        if (typeVoyage == 'Solo' && continent == 'Asie') score += 1;
        if (typeVoyage == 'Couple' &&
            (ville['niveau_budget'] == 'Élevé' || ville['niveau_budget'] == 'Moyen')) {
          score += 1;
        }
        if (typeVoyage == 'Famille' && ville['niveau_budget'] == 'Faible') {
          score += 1;
        }

        score += ((ville['popularite'] ?? 0) as num).round();

        // Generer l'insight dynamique de l'IA
        String aiInsight = _generateDynamicInsight(
          villeNom: ville['nom'],
          villeBudget: ville['niveau_budget'] ?? '',
          userBudget: budget,
          typeVoyage: typeVoyage,
        );

        return {...ville, 'score': score, 'ai_insight': aiInsight};
      }).toList();

      scored.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
      final top3 = scored.take(3).toList();

      if (mounted) {
        setState(() {
          _recommandations = top3;
          _prefs = prefs;
          _loading = false;
        });
        _animController.forward();
      }
    } catch (e) {
      debugPrint('Erreur recommandations: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  String _generateDynamicInsight({
    required String villeNom,
    required String villeBudget,
    required String userBudget,
    required String typeVoyage,
  }) {
    if (villeBudget == userBudget && typeVoyage == 'Couple') {
      return '🎯 Idéal pour un repaire romantique dans votre budget.';
    } else if (typeVoyage == 'Famille') {
      return '👨‍👩‍👧‍👦 Parfait pour créer d\'inoubliables souvenirs en famille.';
    } else if (villeBudget == userBudget) {
      return '💸 Une excellente adéquation avec vos restrictions budgétaires.';
    } else {
      return '✨ Une destination populaire qui coche bon nombre de vos critères !';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FF),
      bottomNavigationBar: _buildBottomNav(),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF4F9FF),
                  Color(0xFFEBF5FB),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: _loading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF4DB6E8)),
                        SizedBox(height: 24),
                        Text(
                          'Analyse IA en cours...',
                          style: TextStyle(
                            color: Color(0xFF0A192F),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // HERO HEADER
                      SliverToBoxAdapter(
                        child: FadeTransition(
                          opacity: _fadeHeader,
                          child: _buildHeroHeader(),
                        ),
                      ),
                      
                      // AI INSIGHT EXPLANATION
                      if (_recommandations.isNotEmpty)
                        SliverToBoxAdapter(
                          child: FadeTransition(
                            opacity: _fadeInsight,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                              child: _buildInsightCard(),
                            ),
                          ),
                        ),

                      // RECOMMENDATION CARDS
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return FadeTransition(
                                opacity: _fadeCards,
                                child: SlideTransition(
                                  position: _slideCards,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 24),
                                    child: _PremiumDestCard(
                                      ville: _recommandations[index],
                                      rank: index + 1,
                                    ),
                                  ),
                                ),
                              );
                            },
                            childCount: _recommandations.length,
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
  // HERO HEADER
  // ─────────────────────────────────────────────
  Widget _buildHeroHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF4A6580), size: 18),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4DB6E8), Color(0xFF1A7EC8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4DB6E8).withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recommandations IA',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A192F),
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Destinations choisies pour vous',
                      style: TextStyle(fontSize: 14, color: Color(0xFF4A6580)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_prefs != null) ...[
            const SizedBox(height: 24),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildGlassPref('💰', _prefs!['budget']),
                  const SizedBox(width: 8),
                  _buildGlassPref('👥', _prefs!['type_voyage']),
                  const SizedBox(width: 8),
                  _buildGlassPref('📅', _prefs!['duree_sejour']),
                  ...List<String>.from(_prefs!['centres_interet'] ?? []).map(
                    (i) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _buildGlassPref('✨', i),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGlassPref(String emoji, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4DB6E8).withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Color(0xFF4A6580), fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // AI INSIGHT CARD
  // ─────────────────────────────────────────────
  Widget _buildInsightCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4DB6E8).withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4DB6E8).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.psychology_rounded, color: Color(0xFF4DB6E8), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Analyse terminée',
                  style: TextStyle(
                    color: Color(0xFF0A192F),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Basé sur vos préférences méticuleuses, voici le classement exact des destinations qui correspondent parfaitement à votre profil de voyage.',
                  style: const TextStyle(
                    color: Color(0xFF4A6580),
                    fontSize: 13,
                    height: 1.4,
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
  // BOTTOM NAVIGATION BAR
  // ─────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 8, top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black.withOpacity(0.05))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(index: 0, icon: Icons.home_rounded, activeIcon: Icons.home_rounded, label: 'Home'),
          _buildNavItem(index: 1, icon: Icons.explore_outlined, activeIcon: Icons.explore, label: 'Explorer'),
          _buildNavAIButton(),
          _buildNavItem(index: 3, icon: Icons.luggage_outlined, activeIcon: Icons.luggage, label: 'Mes Voyages'),
          _buildNavItem(index: 4, icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildNavItem({required int index, required IconData icon, required IconData activeIcon, required String label}) {
    // Current screen is Recommandations, middle button. There is no traditional active bottom nav item here.
    return GestureDetector(
      onTap: () {
        if (index == 0) {
          Navigator.pop(context);
        } else if (index == 1) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
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
            Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                icon,
                color: const Color(0xFF4A6580).withOpacity(0.5),
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: const Color(0xFF4A6580).withOpacity(0.5),
                fontSize: 10,
                fontWeight: FontWeight.w500,
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
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4DB6E8), Color(0xFF1A7EC8)],
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFF4DB6E8).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: const Center(
        child: Icon(Icons.auto_awesome, color: Colors.white, size: 26),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PREMIUM DESTINATION CARD (INTERACTIVE)
// ─────────────────────────────────────────────
class _PremiumDestCard extends StatefulWidget {
  final Map<String, dynamic> ville;
  final int rank;

  const _PremiumDestCard({required this.ville, required this.rank});

  @override
  State<_PremiumDestCard> createState() => _PremiumDestCardState();
}

class _PremiumDestCardState extends State<_PremiumDestCard> {
  bool _isHovered = false;
  bool _isFav = false;

  @override
  void initState() {
    super.initState();
    _checkFav();
  }

  Future<void> _checkFav() async {
    final id = widget.ville['id'].toString();
    final isFav = await FavorisService.estFavoris(id);
    if (mounted) setState(() => _isFav = isFav);
  }

  Future<void> _toggleFav() async {
    final id = widget.ville['id'].toString();
    final nom = widget.ville['nom'] ?? '';
    
    setState(() => _isFav = !_isFav);
    try {
      if (_isFav) {
        await FavorisService.ajouterFavoris(id, nom);
      } else {
        await FavorisService.supprimerFavoris(id);
      }
    } catch (_) {
      setState(() => _isFav = !_isFav);
    }
  }

  void _navigateToDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen(ville: widget.ville),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.ville['image_url'] as String?;
    final score = widget.ville['score'] ?? 0;
    final pays = widget.ville['pays']?['nom'] ?? '';
    final continent = widget.ville['pays']?['continent'] ?? '';
    final aiInsight = widget.ville['ai_insight'] ?? 'Une destination idéale.';

    return GestureDetector(
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) {
        setState(() => _isHovered = false);
        _navigateToDetail();
      },
      onTapCancel: () => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          height: 380, // High-end tall card
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Background Image
                if (imageUrl != null && imageUrl.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.white.withOpacity(0.05)),
                    errorWidget: (context, url, error) => Container(color: Colors.white.withOpacity(0.1)),
                  )
                else
                  Container(color: Colors.white.withOpacity(0.05)),

                // 2. Multi-layer Dark Gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.2), // Slight top dim for badges
                        Colors.transparent,           // Clear center
                        Colors.black.withOpacity(0.7), // Bottom text legibility
                        Colors.black.withOpacity(0.95), // Deep bottom for AI insight
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                  ),
                ),

                // 3. Top Badges
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Choice Badge
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Text('${widget.rank == 1 ? '👑' : '🎯'}', style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 6),
                                Text(
                                  'Choix #${widget.rank}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Score Badge (Glowing green)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.limeGreen,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.limeGreen.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.bolt_rounded, color: Color(0xFF0F1B2D), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Score: $score',
                              style: const TextStyle(
                                color: Color(0xFF0F1B2D),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 4. Floating Favorite Icon
                Positioned(
                  top: 70,
                  right: 16,
                  child: GestureDetector(
                    onTap: _toggleFav,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _isFav ? AppTheme.coral.withOpacity(0.35) : Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                            border: Border.all(color: _isFav ? AppTheme.coral.withOpacity(0.6) : Colors.transparent),
                          ),
                          child: Icon(_isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: _isFav ? AppTheme.coral : Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ),
                ),

                // 5. Bottom Content (Title, Info, AI text)
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.ville['nom'] ?? 'Inconnu',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, color: AppTheme.limeGreen.withOpacity(0.8), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '$pays • $continent',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Stat Pills Row
                      Row(
                        children: [
                          _buildStatBadge(Icons.star_rounded, '4.9', Colors.orangeAccent),
                          const SizedBox(width: 8),
                          _buildStatBadge(Icons.attach_money_rounded, widget.ville['niveau_budget'] ?? 'Moyen', Colors.white),
                          const SizedBox(width: 8),
                          _buildStatBadge(Icons.wb_sunny_rounded, '24°C', Colors.white), // Stub for display
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Divider
                      Container(height: 1, width: double.infinity, color: Colors.white.withOpacity(0.1)),
                      const SizedBox(height: 16),
                      
                      // AI Smart Context Text
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.auto_awesome_rounded, color: AppTheme.limeGreen.withOpacity(0.8), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              aiInsight,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.7),
                                fontStyle: FontStyle.italic,
                                height: 1.3,
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

  Widget _buildStatBadge(IconData icon, String label, Color iconColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
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
    );
  }
}
