import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voyage_app/core/theme/app_theme.dart';
import 'package:voyage_app/features/voyage/screens/create_voyage_screen.dart';

class MesVoyagesScreen extends StatefulWidget {
  const MesVoyagesScreen({super.key});

  @override
  State<MesVoyagesScreen> createState() => _MesVoyagesScreenState();
}

class _MesVoyagesScreenState extends State<MesVoyagesScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _voyages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVoyages();
  }

  Future<void> _loadVoyages() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      final voyages = await _supabase
          .from('plans_voyage')
          .select('*, plan_villes(villes(nom, image_url, pays(nom)))')
          .eq('id_user', user.id)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _voyages = List<Map<String, dynamic>>.from(voyages);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement voyages: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteVoyage(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce voyage ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _supabase.from('plans_voyage').delete().eq('id', id);
      _loadVoyages();
    }
  }

  String _formatDate(String? date) {
    if (date == null) return 'N/A';
    final d = DateTime.parse(date);
    return '${d.day}/${d.month}/${d.year}';
  }

  int _nombreJours(String? debut, String? fin) {
    if (debut == null || fin == null) return 0;
    return DateTime.parse(fin).difference(DateTime.parse(debut)).inDays;
  }

  Color _statutColor(String? statut) {
    switch (statut) {
      case 'en cours':
        return const Color(0xFF4CAF50);
      case 'terminé':
        return AppTheme.primary;
      case 'annulé':
        return AppTheme.coral;
      default:
        return AppTheme.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF7C3AED), Color(0xFF0093E9)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🗺️ Mes voyages',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tous vos itinéraires',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CreateVoyageScreen(),
                            ),
                          );
                          if (result == true) _loadVoyages();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Stats
                  Row(
                    children: [
                      _buildStatBadge('${_voyages.length}', 'Voyages créés'),
                      const SizedBox(width: 10),
                      _buildStatBadge(
                        '${_voyages.where((v) => v['statut'] == 'en cours').length}',
                        'En cours',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Liste
          _loading
              ? const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 100),
                    child: Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    ),
                  ),
                )
              : _voyages.isEmpty
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Column(
                      children: [
                        const Text('✈️', style: TextStyle(fontSize: 60)),
                        const SizedBox(height: 16),
                        const Text(
                          'Aucun voyage créé',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.dark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Planifiez votre première aventure !',
                          style: TextStyle(color: AppTheme.muted, fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: ElevatedButton(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CreateVoyageScreen(),
                                ),
                              );
                              if (result == true) _loadVoyages();
                            },
                            child: const Text('+ Créer un voyage'),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _buildVoyageCard(_voyages[i]),
                      childCount: _voyages.length,
                    ),
                  ),
                ),

          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildVoyageCard(Map<String, dynamic> voyage) {
    final planVilles = voyage['plan_villes'] as List? ?? [];
    final ville = planVilles.isNotEmpty
        ? planVilles[0]['villes'] as Map<String, dynamic>?
        : null;
    final jours = _nombreJours(voyage['date_debut'], voyage['date_fin']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Image destination
          if (ville?['image_url'] != null)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
              child: Image.network(
                ville!['image_url'],
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 140,
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  child: const Center(
                    child: Icon(
                      Icons.image_outlined,
                      color: AppTheme.primary,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre + statut
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        voyage['titre'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.dark,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _statutColor(
                          voyage['statut'],
                        ).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        voyage['statut'] ?? '',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _statutColor(voyage['statut']),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Destination
                if (ville != null)
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: AppTheme.muted,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${ville['nom']} — ${ville['pays']?['nom'] ?? ''}',
                        style: TextStyle(fontSize: 13, color: AppTheme.muted),
                      ),
                    ],
                  ),

                const SizedBox(height: 8),

                // Infos
                Row(
                  children: [
                    _buildInfo(
                      Icons.calendar_today,
                      '${_formatDate(voyage['date_debut'])} → ${_formatDate(voyage['date_fin'])}',
                    ),
                    const SizedBox(width: 16),
                    _buildInfo(Icons.schedule, '$jours jours'),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    if (voyage['type_voyage'] != null)
                      _buildInfo(Icons.people_outline, voyage['type_voyage']),
                    const SizedBox(width: 16),
                    if (voyage['budget_total'] != null &&
                        voyage['budget_total'] > 0)
                      _buildInfo(Icons.euro, '${voyage['budget_total']}€'),
                  ],
                ),

                if (voyage['notes'] != null &&
                    voyage['notes'].toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.notes,
                          color: AppTheme.muted,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            voyage['notes'],
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.muted,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _deleteVoyage(voyage['id'].toString()),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.coral,
                          side: BorderSide(color: AppTheme.coral),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('🗑️ Supprimer'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppTheme.muted, size: 14),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: AppTheme.muted)),
      ],
    );
  }
}
