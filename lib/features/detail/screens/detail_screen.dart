import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voyage_app/core/theme/app_theme.dart';
import 'package:voyage_app/features/favoris/services/favoris_service.dart';
import 'package:voyage_app/features/voyage/screens/create_voyage_screen.dart';

class DetailScreen extends StatefulWidget {
  final Map<String, dynamic> ville;

  const DetailScreen({super.key, required this.ville});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;
  
  List<Map<String, dynamic>> _activites = [];
  List<Map<String, dynamic>> _hotels = [];
  List<Map<String, dynamic>> _restaurants = [];
  
  bool _loading = true;
  bool _isFavoris = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final idVille = widget.ville['id'];
    try {
      final activites = await _supabase.from('activites').select().eq('id_ville', idVille);
      final hotels = await _supabase.from('hotels').select().eq('id_ville', idVille);
      final restaurants = await _supabase.from('restaurants').select().eq('id_ville', idVille);
      final favoris = await FavorisService.estFavoris(idVille.toString());

      if (mounted) {
        setState(() {
          _activites = List<Map<String, dynamic>>.from(activites);
          _hotels = List<Map<String, dynamic>>.from(hotels);
          _restaurants = List<Map<String, dynamic>>.from(restaurants);
          _isFavoris = favoris;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFavoris() async {
    final ville = widget.ville;
    final newStatus = !_isFavoris;
    setState(() => _isFavoris = newStatus);
    
    try {
      if (newStatus) {
        await FavorisService.ajouterFavoris(ville['id'].toString(), ville['nom'] ?? '');
      } else {
        await FavorisService.supprimerFavoris(ville['id'].toString());
      }
    } catch (e) {
      if (mounted) setState(() => _isFavoris = !newStatus); // Rollback
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkNavy, // Super Premium Base Color
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.limeGreen))
          : Stack(
              children: [
                CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildHeroHeader(),
                    
                    // Main Info Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            // Info Glass Pills
                            Row(
                              children: [
                                _buildGlassPill('🌡️', '${widget.ville['temperature'] ?? 'N/A'}'),
                                const SizedBox(width: 8),
                                _buildGlassPill('💰', '${widget.ville['niveau_budget'] ?? 'N/A'}'),
                                const SizedBox(width: 8),
                                _buildGlassPill('🌍', '${widget.ville['pays']?['continent'] ?? ''}'),
                              ],
                            ),
                            const SizedBox(height: 32),
                            
                            // About Text
                            const Text(
                              'À propos',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.ville['description'] ?? '',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white.withOpacity(0.7),
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 28),
                            
                            // Horizonal Info Cards
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              clipBehavior: Clip.none,
                              child: Row(
                                children: [
                                  _buildQuickInfoCard('🗣️', 'Langue', widget.ville['pays']?['langue'] ?? 'N/A'),
                                  const SizedBox(width: 12),
                                  _buildQuickInfoCard('💱', 'Monnaie', widget.ville['pays']?['monnaie'] ?? 'N/A'),
                                  const SizedBox(width: 12),
                                  _buildQuickInfoCard('☀️', 'Climat', widget.ville['pays']?['climat'] ?? 'N/A'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),
                            
                            // Custom Animated Tabs
                            _buildCustomTabs(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    
                    // Dynamic Content SliverList
                    SliverPadding(
                      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 100),
                      sliver: _buildCurrentTabList(),
                    ),
                  ],
                ),
                
                // Floating Action Button to Add to Trip
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).padding.bottom + 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppTheme.darkNavy,
                          AppTheme.darkNavy.withOpacity(0.95),
                          AppTheme.darkNavy.withOpacity(0),
                        ],
                        stops: const [0.3, 0.7, 1.0],
                      ),
                    ),
                    child: _InteractiveButton(
                      label: 'Ajouter à mon voyage',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateVoyageScreen(
                              initialVilleId: widget.ville['id'].toString(),
                            ),
                          ),
                        );
                      },
                    ),
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
    final ville = widget.ville;
    return SliverAppBar(
      expandedHeight: 460,
      pinned: true,
      backgroundColor: AppTheme.darkNavy,
      elevation: 0,
      stretch: true,
      leading: Center(
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
        ),
      ),
      actions: [
        Center(
          child: GestureDetector(
            onTap: _toggleFavoris,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  margin: const EdgeInsets.only(right: 20),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                    child: Icon(
                      _isFavoris ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      key: ValueKey<bool>(_isFavoris),
                      color: _isFavoris ? Colors.redAccent : Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        )
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Image with Parallax scaling handled natively by FlexibleSpaceBar
            Hero(
              tag: 'ville_${ville['id']}',
              child: CachedNetworkImage(
                imageUrl: ville['image_url'] ?? '',
                fit: BoxFit.cover,
                memCacheWidth: 800,
                placeholder: (context, url) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppTheme.darkNavyLight, AppTheme.darkNavy],
                    ),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: AppTheme.limeGreen, strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppTheme.darkNavy,
                  child: const Icon(Icons.error_outline, color: Colors.white24, size: 40),
                ),
              ),
            ),
            
            // Ultra Premium Gradient Fade
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4), // Top for buttons
                    Colors.transparent,           
                    AppTheme.darkNavy.withOpacity(0.6), 
                    AppTheme.darkNavy,            // Seamless transition to bottom colors
                  ],
                  stops: const [0.0, 0.3, 0.6, 1.0],
                ),
              ),
            ),
            
            // Text Content mapped to bottom
            Positioned(
              bottom: 20,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ville['nom'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, color: AppTheme.limeGreen.withOpacity(0.8), size: 18),
                      const SizedBox(width: 4),
                      Text(
                        ville['pays']?['nom'] ?? '',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.orangeAccent, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${ville['popularite'] ?? ''}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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
  // INFO PILLS & COMPONENTS
  // ─────────────────────────────────────────────
  Widget _buildGlassPill(String emoji, String value) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickInfoCard(String emoji, String label, String value) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF162544).withOpacity(0.6), // Dark premium card
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TABS & LISTS
  // ─────────────────────────────────────────────
  Widget _buildCustomTabs() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: AppTheme.limeGreen,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppTheme.limeGreen.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: const Color(0xFF0F1B2D),
        unselectedLabelColor: Colors.white.withOpacity(0.5),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        tabs: const [
          Tab(text: 'Activités'),
          Tab(text: 'Hôtels'),
          Tab(text: 'Restos'),
        ],
      ),
    );
  }

  Widget _buildCurrentTabList() {
    final index = _tabController.index;
    if (index == 0) return _buildActivitesSliver();
    if (index == 1) return _buildHotelsSliver();
    return _buildRestaurantsSliver();
  }

  Widget _buildActivitesSliver() {
    if (_activites.isEmpty) return SliverToBoxAdapter(child: _buildEmpty('Aucune activité'));
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          final a = _activites[i];
          return _InteractiveItemCard(
            emoji: '🎯',
            titre: a['nom'] ?? '',
            info: '${a['duree'] ?? ''} • ${a['prix'] != null ? '${a['prix']}€' : 'Gratuit'}',
            badge: a['categorie'] ?? '',
          );
        },
        childCount: _activites.length,
      ),
    );
  }

  Widget _buildHotelsSliver() {
    if (_hotels.isEmpty) return SliverToBoxAdapter(child: _buildEmpty('Aucun hôtel'));
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          final h = _hotels[i];
          return _InteractiveItemCard(
            emoji: '🏨',
            titre: h['nom'] ?? '',
            info: '${h['prix'] != null ? '${h['prix']}€/nuit' : 'N/A'}',
            badge: h['etoiles'] != null ? '${h['etoiles']} ⭐' : '',
          );
        },
        childCount: _hotels.length,
      ),
    );
  }

  Widget _buildRestaurantsSliver() {
    if (_restaurants.isEmpty) return SliverToBoxAdapter(child: _buildEmpty('Aucun restaurant'));
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          final r = _restaurants[i];
          return _InteractiveItemCard(
            emoji: '🍽️',
            titre: r['nom'] ?? '',
            info: '${r['prix_moyen'] != null ? '${r['prix_moyen']}€ moy.' : 'N/A'}',
            badge: r['type_cuisine'] ?? '',
          );
        },
        childCount: _restaurants.length,
      ),
    );
  }

  Widget _buildEmpty(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.search_rounded, color: Colors.white24, size: 48),
            const SizedBox(height: 16),
            Text(msg, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// INTERACTIVE ITEM CARD
// ─────────────────────────────────────────────
class _InteractiveItemCard extends StatefulWidget {
  final String emoji;
  final String titre;
  final String info;
  final String badge;

  const _InteractiveItemCard({
    required this.emoji,
    required this.titre,
    required this.info,
    required this.badge,
  });

  @override
  State<_InteractiveItemCard> createState() => _InteractiveItemCardState();
}

class _InteractiveItemCardState extends State<_InteractiveItemCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF162544).withOpacity(0.5), // Deep tinted card
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.03)),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(widget.emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.titre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.info,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.badge.isNotEmpty) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.limeGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.limeGreen.withOpacity(0.2)),
                  ),
                  child: Text(
                    widget.badge,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.limeGreen,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractiveButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _InteractiveButton({required this.label, required this.onTap});

  @override
  State<_InteractiveButton> createState() => _InteractiveButtonState();
}

class _InteractiveButtonState extends State<_InteractiveButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.limeGreen,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppTheme.limeGreen.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.airplanemode_active_rounded, color: Color(0xFF0F1B2D), size: 20),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Color(0xFF0F1B2D),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
