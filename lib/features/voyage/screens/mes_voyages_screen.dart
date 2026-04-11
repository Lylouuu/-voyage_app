import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voyage_app/core/theme/app_theme.dart';
import 'package:voyage_app/features/voyage/screens/create_voyage_screen.dart';
import 'package:voyage_app/features/voyage/screens/AvisForm.dart';

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
          .select('*, plan_villes(villes(id,nom, image_url, pays(nom)))')
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
    await _supabase.from('plans_voyage').delete().eq('id', id);
    _loadVoyages();
  }

  Future<void> _updateStatut(String id, String statut) async {
    await _supabase
        .from('plans_voyage')
        .update({'statut': statut})
        .eq('id', id);
    _loadVoyages();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Statut changé en $statut'),
        backgroundColor: AppTheme.primary,
      ),
    );
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
      case 'effectué':
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
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '🗺️ Mes voyages',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tous vos itinéraires',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),

                  const SizedBox(height: 16),

                  // Statistiques
                  Row(
                    children: [
                      _buildStatBadge('${_voyages.length}', 'Total'),
                      const SizedBox(width: 10),
                      _buildStatBadge(
                        '${_voyages.where((v) => v['statut'] == 'en cours').length}',
                        'En cours',
                      ),
                      const SizedBox(width: 10),
                      _buildStatBadge(
                        '${_voyages.where((v) => v['statut'] == 'effectué').length}',
                        'Effectués',
                      ),
                      const SizedBox(width: 10),
                      _buildStatBadge(
                        '${_voyages.where((v) => v['statut'] == 'annulé').length}',
                        'Annulés',
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
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre + statut
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  voyage['titre'] ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.dark,
                  ),
                ),
                Text(
                  voyage['statut'] ?? '',
                  style: TextStyle(
                    color: _statutColor(voyage['statut']),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (ville != null)
              Text(
                '${ville['nom']} — ${ville['pays']?['nom'] ?? ''}',
                style: const TextStyle(fontSize: 13, color: AppTheme.muted),
              ),

            const SizedBox(height: 8),
            Text(
              '${_formatDate(voyage['date_debut'])} → ${_formatDate(voyage['date_fin'])} • $jours jours',
              style: const TextStyle(fontSize: 12, color: AppTheme.muted),
            ),

            const SizedBox(height: 12),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        _updateStatut(voyage['id'].toString(), 'effectué'),
                    child: const Text('✅ Effectué'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        _updateStatut(voyage['id'].toString(), 'annulé'),
                    child: const Text('❌ Annuler'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _deleteVoyage(voyage['id'].toString()),
                    child: const Text('🗑️ Supprimer'),
                  ),
                ),
              ],
            ),

            if (voyage['statut'] == 'effectué' && ville != null) ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => Padding(
                      padding: const EdgeInsets.all(20),
                      child: AvisForm(villeId: ville['id'].toString()),
                    ),
                  );
                },
                child: const Text('📝 Donner mon avis'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
