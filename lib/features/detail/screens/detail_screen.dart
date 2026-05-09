import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voyage_app/core/theme/app_theme.dart';
import 'package:voyage_app/features/favoris/services/favoris_service.dart';
import 'package:voyage_app/features/voyage/screens/create_voyage_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

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
      backgroundColor: const Color(0xFFF4F9FF), // Fond clair premium
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4DB6E8)))
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
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0A192F),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle(Icons.info_outline_rounded, 'Description'),
                                const SizedBox(height: 12),
                                Text(
                                  widget.ville['description']?.isNotEmpty == true 
                                    ? widget.ville['description'] 
                                    : 'Une destination captivante où se mêlent culture, gastronomie et paysages exceptionnels. Parfait pour une escapade inoubliable.',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF4A6580),
                                    height: 1.5,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                // Rendu épuré : on n'affiche Histoire et Localisation QUE si elles existent dans la DB.
                                // Cela évite le mur de texte ("trop d'écriture").
                                if (widget.ville['histoire']?.isNotEmpty == true) ...[
                                  const SizedBox(height: 24),
                                  _buildSectionTitle(Icons.account_balance_rounded, 'Histoire & Culture'),
                                  const SizedBox(height: 12),
                                  Text(
                                    widget.ville['histoire'],
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF4A6580),
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                                if (widget.ville['localisation']?.isNotEmpty == true) ...[
                                  const SizedBox(height: 24),
                                  _buildSectionTitle(Icons.map_rounded, 'Localisation'),
                                  const SizedBox(height: 12),
                                  Text(
                                    widget.ville['localisation'],
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF4A6580),
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 32),
                            
                            // Photo Gallery Section
                            _buildSectionTitle(Icons.photo_library_rounded, 'Photos'),
                            const SizedBox(height: 16),
                            _buildPhotoGallery(),
                            const SizedBox(height: 32),
                            
                            // Map Section
                            _buildSectionTitle(Icons.map_outlined, 'Carte'),
                            const SizedBox(height: 16),
                            _buildMapSection(),
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
                          const Color(0xFFF4F9FF),
                          const Color(0xFFF4F9FF).withOpacity(0.95),
                          const Color(0xFFF4F9FF).withOpacity(0),
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
            
            // Ultra Premium Gradient Fade (Light Theme Adaptation)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4), // Top for buttons
                    Colors.transparent,           
                    const Color(0xFFF4F9FF).withOpacity(0.6), 
                    const Color(0xFFF4F9FF),            // Seamless transition to bottom colors
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
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
                      color: Color(0xFF0A192F),
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: Color(0xFF4DB6E8), size: 18),
                      const SizedBox(width: 4),
                      Text(
                        ville['pays']?['nom'] ?? '',
                        style: const TextStyle(
                          color: Color(0xFF4A6580),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4DB6E8).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFF4DB6E8), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${ville['popularite'] ?? ''}',
                              style: const TextStyle(
                                color: Color(0xFF0A192F),
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
  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEBF5FB),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF4DB6E8), size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0A192F),
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoGallery() {
    // Si la base de données retourne une liste vide, on met des images par défaut.
    List<dynamic> photos = [];
    if (widget.ville['photos'] != null && widget.ville['photos'] is List && widget.ville['photos'].isNotEmpty) {
      photos = widget.ville['photos'];
    } else {
      photos = [
        'https://images.unsplash.com/photo-1583422409516-15eba534814e?q=80&w=800&auto=format&fit=crop', // Sagrada Familia
        'https://images.unsplash.com/photo-1539037116277-4db20889f2d4?q=80&w=800&auto=format&fit=crop', // Rue Barcelone
        'https://images.unsplash.com/photo-1464790715122-8c558e0a6d10?q=80&w=800&auto=format&fit=crop', // City View
        'https://images.unsplash.com/photo-1562883676-8c7feb83f09b?q=80&w=800&auto=format&fit=crop', // Vue ville 2
      ];
    }

    return SizedBox(
      height: 180, // Légèrement plus grand pour sublimer les photos
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        itemCount: photos.length,
        itemBuilder: (context, index) {
          return Container(
            width: 220,
            margin: EdgeInsets.only(right: 16, left: index == 0 ? 0 : 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4DB6E8).withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CachedNetworkImage(
                imageUrl: photos[index],
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: const Color(0xFFEBF5FB),
                  child: const Center(child: CircularProgressIndicator(color: const Color(0xFF4DB6E8))),
                ),
                errorWidget: (context, url, error) => Container(
                  color: const Color(0xFFEBF5FB),
                  child: const Icon(Icons.image_not_supported, color: Color(0xFF4A6580)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openGoogleMaps(double lat, double lng) async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Impossible d\'ouvrir la carte: $e');
    }
  }

  Widget _buildMapSection() {
    double lat = 41.3851; // Par défaut: Barcelone
    double lng = 2.1734;
    
    if (widget.ville['latitude'] != null && widget.ville['longitude'] != null) {
      lat = double.tryParse(widget.ville['latitude'].toString()) ?? 41.3851;
      lng = double.tryParse(widget.ville['longitude'].toString()) ?? 2.1734;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openGoogleMaps(lat, lng),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4DB6E8).withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
            image: const DecorationImage(
              image: NetworkImage('https://images.unsplash.com/photo-1524661135-423995f22d0b?q=80&w=800&auto=format&fit=crop'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.black.withOpacity(0.3),
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.map_rounded, color: Color(0xFF4DB6E8), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Voir sur Google Maps',
                      style: TextStyle(
                        color: Color(0xFF0A192F),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
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

  Widget _buildGlassPill(String emoji, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEBF5FB), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF4A6580),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfoCard(String emoji, String label, String value) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEBF5FB), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F9FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF4A6580),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0A192F),
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
        color: const Color(0xFFEBF5FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4DB6E8).withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: const Color(0xFF4DB6E8),
        unselectedLabelColor: const Color(0xFF4A6580).withOpacity(0.6),
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
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
          final adresse = a['adresse'] ?? a['localisation'];
          String infoText = '${a['duree'] ?? ''} • ${a['prix'] != null ? '${a['prix']}€' : 'Gratuit'}';
          if (adresse != null && adresse.toString().isNotEmpty) {
            infoText += ' • 📍 $adresse';
          }
          return _InteractiveItemCard(
            titre: a['nom'] ?? '',
            info: infoText,
            badge: a['categorie'] ?? '',
            description: a['description'],
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
            titre: h['nom'] ?? '',
            info: '${h['prix'] != null ? '${h['prix']}€/nuit' : 'N/A'}',
            badge: h['etoiles'] != null ? '${h['etoiles']} ⭐' : '',
            description: h['localisation'] ?? h['adresse'], // Sans texte de remplissage lourd
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
            titre: r['nom'] ?? '',
            info: '${r['prix_moyen'] != null ? '${r['prix_moyen']}€ moy.' : 'N/A'}',
            badge: r['type_cuisine'] ?? '',
            description: r['localisation'] ?? r['adresse'], // Sans texte de remplissage lourd
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
            const Icon(Icons.search_rounded, color: Color(0xFF4DB6E8), size: 48),
            const SizedBox(height: 16),
            Text(msg, style: const TextStyle(color: Color(0xFF4A6580), fontSize: 15, fontWeight: FontWeight.w500)),
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
  final String? emoji;
  final String titre;
  final String info;
  final String badge;
  final String? description;

  const _InteractiveItemCard({
    this.emoji,
    required this.titre,
    required this.info,
    required this.badge,
    this.description,
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEBF5FB), width: 1.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.emoji != null) ...[
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F9FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(widget.emoji!, style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.titre,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0A192F),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.badge.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4DB6E8).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.badge,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF4DB6E8),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.info,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A7EC8),
                      ),
                    ),
                    if (widget.description != null && widget.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.description!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4A6580),
                          height: 1.5,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
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
            gradient: const LinearGradient(
              colors: [Color(0xFF4DB6E8), Color(0xFF1A7EC8)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4DB6E8).withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.airplanemode_active_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
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
