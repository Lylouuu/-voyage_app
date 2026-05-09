import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voyage_app/core/theme/app_theme.dart';
import 'package:voyage_app/features/voyage/screens/AvisForm.dart';
import 'package:voyage_app/features/voyage/screens/itineraire_screen.dart';
import 'package:voyage_app/features/profile/screens/profile_screen.dart';
import 'package:voyage_app/features/recommandations/screens/recommandations_screen.dart';
import 'package:voyage_app/features/search/screens/search_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MesVoyagesScreen extends StatefulWidget {
  const MesVoyagesScreen({super.key});

  @override
  State<MesVoyagesScreen> createState() => _MesVoyagesScreenState();
}

class _MesVoyagesScreenState extends State<MesVoyagesScreen> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _voyages = [];
  bool _loading = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOutQuart));

    _loadVoyages();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadVoyages() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      final voyages = await _supabase
          .from('plans_voyage')
          .select('*, plan_villes(villes(id,nom, image_url, pays(nom)))')
          .eq('id_user', user.id)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _voyages = List<Map<String, dynamic>>.from(voyages);
          _loading = false;
        });
        _fadeController.forward();
      }
    } catch (e) {
      debugPrint('Erreur chargement voyages: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatut(String id, String statut) async {
    await _supabase
        .from('plans_voyage')
        .update({'statut': statut})
        .eq('id', id);
    _loadVoyages();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Statut défini sur $statut'),
        backgroundColor: AppTheme.limeGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deleteVoyage(String id) async {
    await _supabase.from('plans_voyage').delete().eq('id', id);
    _loadVoyages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FF),
      bottomNavigationBar: _buildBottomNav(),
      body: Stack(
        children: [
          // Background Gradient clair
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
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.limeGreen,
                          ),
                        )
                      : _voyages.isEmpty
                          ? _buildEmptyState()
                          : FadeTransition(
                              opacity: _fadeAnimation,
                              child: SlideTransition(
                                position: _slideAnimation,
                                child: ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: _voyages.length,
                                  itemBuilder: (context, i) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 24),
                                      child: _VoyageCard(
                                        voyage: _voyages[i],
                                        onStatusChange: (status) => _updateStatut(_voyages[i]['id'].toString(), status),
                                        onDelete: () => _deleteVoyage(_voyages[i]['id'].toString()),
                                      ),
                                    );
                                  },
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Color(0xFF4A6580),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Mes voyages',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A192F),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tous vos itinéraires et souvenirs',
            style: TextStyle(fontSize: 14, color: Color(0xFF4A6580)),
          ),
          const SizedBox(height: 20),
          // Stats Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildStatBadge('${_voyages.length}', 'Total', const Color(0xFF4DB6E8)),
                const SizedBox(width: 10),
                _buildStatBadge(
                  '${_voyages.where((v) => v['statut'] == 'en cours').length}',
                  'En cours',
                  Colors.orangeAccent,
                ),
                const SizedBox(width: 10),
                _buildStatBadge(
                  '${_voyages.where((v) => v['statut'] == 'effectué').length}',
                  'Effectués',
                  const Color(0xFF4DB6E8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String value, String label, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF4A6580)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.luggage_outlined, size: 64, color: const Color(0xFF4DB6E8).withOpacity(0.4)),
          const SizedBox(height: 16),
          const Text('Aucun voyage trouvé', style: TextStyle(color: Color(0xFF0A192F), fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Vos futurs voyages apparaîtront ici', style: TextStyle(color: Color(0xFF4A6580))),
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
    // Current screen is always Mes Voyages (index 3)
    final isActive = 3 == index;
    return GestureDetector(
      onTap: () {
        if (isActive) return;
        if (index == 0) {
          // Go back to Home
          Navigator.pop(context);
        } else if (index == 1) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
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
}

// ─────────────────────────────────────────────
// VOYAGE CARD WIDGET
// ─────────────────────────────────────────────
class _VoyageCard extends StatefulWidget {
  final Map<String, dynamic> voyage;
  final Function(String) onStatusChange;
  final VoidCallback onDelete;

  const _VoyageCard({
    required this.voyage,
    required this.onStatusChange,
    required this.onDelete,
  });

  @override
  State<_VoyageCard> createState() => _VoyageCardState();
}

class _VoyageCardState extends State<_VoyageCard> {
  bool _isPressed = false;

  Color _statutColor(String? statut) {
    switch (statut) {
      case 'en cours':
        return Colors.orangeAccent;
      case 'effectué':
        return AppTheme.limeGreen;
      case 'annulé':
        return Colors.redAccent;
      default:
        return Colors.white70;
    }
  }

  String _formatDate(String? date) {
    if (date == null) return 'N/A';
    final d = DateTime.parse(date);
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  int _nombreJours(String? debut, String? fin) {
    if (debut == null || fin == null) return 0;
    return DateTime.parse(fin).difference(DateTime.parse(debut)).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final planVilles = widget.voyage['plan_villes'] as List? ?? [];
    final ville = planVilles.isNotEmpty
        ? planVilles[0]['villes'] as Map<String, dynamic>?
        : null;
    final jours = _nombreJours(widget.voyage['date_debut'], widget.voyage['date_fin']);
    final imageUrl = ville?['image_url'];
    final statusColor = _statutColor(widget.voyage['statut']);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Background Image
                if (imageUrl != null && imageUrl.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.white.withOpacity(0.05),
                      child: const Center(
                        child: CircularProgressIndicator(color: AppTheme.limeGreen, strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(color: Colors.white.withOpacity(0.1)),
                  )
                else
                  Container(color: Colors.white.withOpacity(0.1)),

                // 2. Dark Gradient Overlay (Bottom)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.0),
                        Colors.black.withOpacity(0.5),
                        Colors.black.withOpacity(0.9),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),

                // 3. Status Badge (Top Left)
                Positioned(
                  top: 16,
                  left: 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor.withOpacity(0.5)),
                        ),
                        child: Text(
                          (widget.voyage['statut'] ?? '').toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 4. Secondary Actions (Top Right)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Row(
                    children: [
                      if (widget.voyage['statut'] != 'effectué')
                        _buildActionIcon(
                          icon: Icons.check_circle_outline_rounded,
                          color: AppTheme.limeGreen,
                          onTap: () => widget.onStatusChange('effectué'),
                        ),
                      if (widget.voyage['statut'] != 'effectué')
                        const SizedBox(width: 8),
                      if (widget.voyage['statut'] != 'annulé' && widget.voyage['statut'] != 'effectué')
                        _buildActionIcon(
                          icon: Icons.cancel_outlined,
                          color: Colors.orangeAccent,
                          onTap: () => widget.onStatusChange('annulé'),
                        ),
                      if (widget.voyage['statut'] != 'annulé' && widget.voyage['statut'] != 'effectué')
                        const SizedBox(width: 8),
                      _buildActionIcon(
                        icon: Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                        onTap: widget.onDelete,
                      ),
                    ],
                  ),
                ),

                // 5. Card Content (Bottom)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.voyage['titre'] ?? '',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (ville != null)
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded, color: AppTheme.limeGreen.withOpacity(0.8), size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${ville['nom']} — ${ville['pays']?['nom'] ?? ''}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 6),
                      Text(
                        '${_formatDate(widget.voyage['date_debut'])} → ${_formatDate(widget.voyage['date_fin'])} • $jours jours',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 14),
                      
                      // 6. Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ItineraireScreen(voyage: widget.voyage),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4DB6E8),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4DB6E8).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Voir l\'itinéraire',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (widget.voyage['statut'] == 'effectué' && ville != null) ...[
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                        child: Container(
                                          color: const Color(0xFF162544).withOpacity(0.9),
                                          padding: const EdgeInsets.all(20),
                                          child: AvisForm(villeId: ville['id'].toString()),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                                    ),
                                    child: const Icon(Icons.rate_review_outlined, color: Colors.white, size: 20),
                                  ),
                                ),
                              ),
                            ),
                          ],
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

  Widget _buildActionIcon({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
        ),
      ),
    );
  }
}
