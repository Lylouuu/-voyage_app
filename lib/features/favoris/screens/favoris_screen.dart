import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:voyage_app/core/theme/app_theme.dart';
import 'package:voyage_app/features/detail/screens/detail_screen.dart';
import 'package:voyage_app/features/favoris/services/favoris_service.dart';

class FavorisScreen extends StatefulWidget {
  const FavorisScreen({super.key});

  @override
  State<FavorisScreen> createState() => _FavorisScreenState();
}

class _FavorisScreenState extends State<FavorisScreen> {
  List<Map<String, dynamic>> _favoris = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFavoris();
  }

  Future<void> _loadFavoris() async {
    if (mounted) setState(() => _loading = true);
    try {
      final data = await FavorisService.getFavoris();
      if (mounted) {
        setState(() {
          _favoris = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _retirerFavoris(String idVille) async {
    try {
      // Optimitistic UI update
      setState(() {
        _favoris.removeWhere((item) => item['villes']?['id']?.toString() == idVille.toString());
      });
      await FavorisService.supprimerFavoris(idVille);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Retiré des favoris'),
            backgroundColor: AppTheme.coral,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      // Rollback on error strategy or simple reload
      _loadFavoris();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkNavy,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0F1B2D),
                  Color(0xFF0A1628),
                  Color(0xFF0D1F3C), // Slight depth
                ],
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildHeader(),
                if (_loading)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: AppTheme.limeGreen),
                    ),
                  )
                else if (_favoris.isEmpty)
                  _buildEmptyState()
                else
                  _buildFavorisList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white.withOpacity(0.9), size: 18),
                    ),
                  ),
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
                      colors: [AppTheme.coral, Color(0xFFFF8A65)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.coral.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mes Favoris',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_favoris.length} destinations enregistrées',
                        style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.favorite_border_rounded, size: 60, color: Colors.white.withOpacity(0.2)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucun favori',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez des destinations pour les\nretrouver facilement ici.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.limeGreen,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.limeGreen.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  'Explorer les destinations',
                  style: TextStyle(
                    color: Color(0xFF0F1B2D),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavorisList() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 40),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final favori = _favoris[index];
            final ville = favori['villes'];
            if (ville == null) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _PremiumDestCardSmall(
                ville: ville,
                onRemove: () => _retirerFavoris(ville['id'].toString()),
              ),
            );
          },
          childCount: _favoris.length,
        ),
      ),
    );
  }
}

// Interactive Premium Card
class _PremiumDestCardSmall extends StatefulWidget {
  final Map<String, dynamic> ville;
  final VoidCallback onRemove;

  const _PremiumDestCardSmall({required this.ville, required this.onRemove});

  @override
  State<_PremiumDestCardSmall> createState() => _PremiumDestCardSmallState();
}

class _PremiumDestCardSmallState extends State<_PremiumDestCardSmall> {
  bool _isHovered = false;

  void _navigateToDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailScreen(ville: widget.ville)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.ville['image_url'] as String?;
    final nom = widget.ville['nom'] ?? 'Inconnu';
    final pays = widget.ville['pays']?['nom'] ?? '';
    final budget = widget.ville['niveau_budget'] ?? 'Moyen';
    final budgetColor = budget == 'Faible'
        ? const Color(0xFF4CAF50)
        : budget == 'Élevé'
            ? const Color(0xFFFF6B6B)
            : const Color(0xFFFFD97D);
            
    final pop = widget.ville['popularite']?.toString() ?? 'N/A';

    return GestureDetector(
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) {
        setState(() => _isHovered = false);
        _navigateToDetail();
      },
      onTapCancel: () => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          height: 130, // Horizontal card
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // Image
              Hero(
                tag: 'fav_dest_${widget.ville['id']}',
                child: Container(
                  width: 120,
                  height: 130,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(22),
                      bottomLeft: Radius.circular(22),
                    ),
                    color: Colors.white.withOpacity(0.1),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(22),
                      bottomLeft: Radius.circular(22),
                    ),
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: AppTheme.limeGreen, strokeWidth: 2)),
                            errorWidget: (_, __, ___) => Icon(Icons.image_outlined, color: Colors.white.withOpacity(0.3)),
                          )
                        : null,
                  ),
                ),
              ),
              
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nom,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.location_on_rounded, color: Colors.white.withOpacity(0.6), size: 12),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        pays,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.6),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Heart Button to remove
                          GestureDetector(
                            onTap: widget.onRemove,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.coral.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.favorite_rounded, color: AppTheme.coral, size: 18),
                            ),
                          ),
                        ],
                      ),
                      
                      // Bottom Row: Budget & Pop
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: budgetColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(color: budgetColor.withOpacity(0.3)),
                            ),
                            child: Text(
                              budget,
                              style: TextStyle(
                                color: budgetColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.star_rounded, color: Color(0xFFFFD97D), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            pop,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
