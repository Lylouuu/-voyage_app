import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voyage_app/core/theme/app_theme.dart';
import 'package:voyage_app/features/favoris/services/favoris_service.dart';

class DetailScreen extends StatefulWidget {
  final Map<String, dynamic> ville;

  const DetailScreen({super.key, required this.ville});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with SingleTickerProviderStateMixin {
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
      final activites = await _supabase
          .from('activites')
          .select()
          .eq('id_ville', idVille);
      final hotels = await _supabase
          .from('hotels')
          .select()
          .eq('id_ville', idVille);
      final restaurants = await _supabase
          .from('restaurants')
          .select()
          .eq('id_ville', idVille);
      
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

  @override
  Widget build(BuildContext context) {
    final ville = widget.ville;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  backgroundColor: AppTheme.primary,
                  leading: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                  actions: [
                    GestureDetector(
                      onTap: () async {
                        final newStatus = !_isFavoris;
                        setState(() => _isFavoris = newStatus);
                        try {
                          if (newStatus) {
                            await FavorisService.ajouterFavoris(ville['id'].toString(), ville['nom'] ?? '');
                          } else {
                            await FavorisService.supprimerFavoris(ville['id'].toString());
                          }
                        } catch (e) {
                          // Rollback on error
                          if (mounted) setState(() => _isFavoris = !newStatus);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _isFavoris ? Icons.favorite : Icons.favorite_outline,
                          color: _isFavoris ? AppTheme.coral : Colors.white,
                        ),
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      children: [
                        CachedNetworkImage(
                          imageUrl: ville['image_url'] ?? '',
                          height: 300,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: AppTheme.primary.withOpacity(0.2),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppTheme.primary.withOpacity(0.2),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          left: 20,
                          right: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ville['nom'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: Colors.white70,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    ville['pays']?['nom'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Icon(
                                    Icons.star,
                                    color: Color(0xFFFFD97D),
                                    size: 16,
                                  ),
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
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildBadge(
                              '🌡️ ${ville['temperature'] ?? 'N/A'}',
                              AppTheme.primary,
                            ),
                            const SizedBox(width: 8),
                            _buildBadge(
                              '💰 ${ville['niveau_budget'] ?? 'N/A'}',
                              AppTheme.coral,
                            ),
                            const SizedBox(width: 8),
                            _buildBadge(
                              '🌍 ${ville['pays']?['continent'] ?? ''}',
                              const Color(0xFF7C3AED),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'À propos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.dark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ville['description'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.muted,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildInfoItem(
                                '🗣️',
                                'Langue',
                                ville['pays']?['langue'] ?? 'N/A',
                              ),
                              _buildInfoItem(
                                '💱',
                                'Monnaie',
                                ville['pays']?['monnaie'] ?? 'N/A',
                              ),
                              _buildInfoItem(
                                '☀️',
                                'Climat',
                                ville['pays']?['climat'] ?? 'N/A',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicator: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            labelColor: Colors.white,
                            unselectedLabelColor: AppTheme.muted,
                            labelStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            dividerColor: Colors.transparent,
                            tabs: const [
                              Tab(text: '🎯 Activités'),
                              Tab(text: '🏨 Hôtels'),
                              Tab(text: '🍽️ Restos'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 300,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildActivitesList(),
                        _buildHotelsList(),
                        _buildRestaurantsList(),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Text(
                        '✈️ Ajouter à mon voyage',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoItem(String emoji, String label, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: AppTheme.muted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.dark,
          ),
        ),
      ],
    );
  }

  Widget _buildActivitesList() {
    if (_activites.isEmpty) return _buildEmpty('Aucune activité disponible');
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _activites.length,
      itemBuilder: (_, i) {
        final a = _activites[i];
        return _buildItemCard(
          emoji: '🎯',
          nom: a['nom'] ?? '',
          detail:
              '${a['duree'] ?? ''} · ${a['prix'] != null ? '${a['prix']}€' : 'Gratuit'}',
          categorie: a['categorie'] ?? '',
        );
      },
    );
  }

  Widget _buildHotelsList() {
    if (_hotels.isEmpty) return _buildEmpty('Aucun hôtel disponible');
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _hotels.length,
      itemBuilder: (_, i) {
        final h = _hotels[i];
        return _buildItemCard(
          emoji: '🏨',
          nom: h['nom'] ?? '',
          detail:
              '${h['etoiles'] ?? ''} ⭐ · ${h['prix'] != null ? '${h['prix']}€/nuit' : 'N/A'}',
          categorie: '',
        );
      },
    );
  }

  Widget _buildRestaurantsList() {
    if (_restaurants.isEmpty) return _buildEmpty('Aucun restaurant disponible');
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _restaurants.length,
      itemBuilder: (_, i) {
        final r = _restaurants[i];
        return _buildItemCard(
          emoji: '🍽️',
          nom: r['nom'] ?? '',
          detail:
              '${r['type_cuisine'] ?? ''} · ${r['prix_moyen'] != null ? '${r['prix_moyen']}€ moy.' : 'N/A'}',
          categorie: '',
        );
      },
    );
  }

  Widget _buildItemCard({
    required String emoji,
    required String nom,
    required String detail,
    required String categorie,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10, top: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nom,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.dark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: TextStyle(fontSize: 12, color: AppTheme.muted),
                ),
              ],
            ),
          ),
          if (categorie.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                categorie,
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 10),
          Text(msg, style: TextStyle(color: AppTheme.muted, fontSize: 14)),
        ],
      ),
    );
  }
}
