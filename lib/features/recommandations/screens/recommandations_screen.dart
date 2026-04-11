import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voyage_app/core/theme/app_theme.dart';
import 'package:voyage_app/features/detail/screens/detail_screen.dart';

class RecommandationsScreen extends StatefulWidget {
  const RecommandationsScreen({super.key});

  @override
  State<RecommandationsScreen> createState() => _RecommandationsScreenState();
}

class _RecommandationsScreenState extends State<RecommandationsScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _recommandations = [];
  Map<String, dynamic>? _prefs;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAndRecommend();
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

      // Charger activités pour matcher les centres d'intérêt
      final activites = await _supabase
          .from('activites')
          .select('id_ville, categorie');

      final activitesList = List<Map<String, dynamic>>.from(activites);

      // Algorithme de scoring
      final centresInteret = List<String>.from(prefs['centres_interet'] ?? []);
      final budget = prefs['budget'] ?? '';
      final typeVoyage = prefs['type_voyage'] ?? '';

      // Map des catégories d'activités par ville
      final Map<String, List<String>> activitesParVille = {};
      for (final a in activitesList) {
        final idVille = a['id_ville'].toString();
        activitesParVille[idVille] ??= [];
        activitesParVille[idVille]!.add(a['categorie'] ?? '');
      }

      // Calculer le score pour chaque ville
      final scored = villesList.map((ville) {
        int score = 0;
        final idVille = ville['id'].toString();

        // +3 si le budget correspond
        if (ville['niveau_budget'] == budget) score += 3;

        // +2 par centre d'intérêt qui correspond aux activités
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

        // +2 si type de voyage correspond
        final continent = ville['pays']?['continent'] ?? '';
        if (typeVoyage == 'Solo' && continent == 'Asie') score += 1;
        if (typeVoyage == 'Couple' &&
            (ville['niveau_budget'] == 'Élevé' ||
                ville['niveau_budget'] == 'Moyen'))
          score += 1;
        if (typeVoyage == 'Famille' && ville['niveau_budget'] == 'Faible') {
          score += 1;
        }

        // +1 par point de popularité
        score += ((ville['popularite'] ?? 0) as num).round();

        return {...ville, 'score': score};
      }).toList();

      // Trier par score et prendre les 3 premiers
      scored.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
      final top3 = scored.take(3).toList();

      if (mounted) {
        setState(() {
          _recommandations = top3;
          _prefs = prefs;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur recommandations: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF00C9B1), Color(0xFF7C3AED)],
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
                    '🤖 Recommandations IA',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Destinations choisies pour vous',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  if (_prefs != null) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildChip('💰 ${_prefs!['budget']}'),
                        _buildChip('👥 ${_prefs!['type_voyage']}'),
                        _buildChip('📅 ${_prefs!['duree_sejour']}'),
                        ...List<String>.from(
                          _prefs!['centres_interet'] ?? [],
                        ).map((i) => _buildChip('✨ $i')),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          if (_loading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 80),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppTheme.primary),
                    SizedBox(height: 16),
                    Text(
                      'Analyse de votre profil...',
                      style: TextStyle(color: AppTheme.muted, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

          if (!_loading && _recommandations.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Text('🤖', style: TextStyle(fontSize: 24)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Basé sur vos préférences, voici les destinations qui vous correspondent le mieux !',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.dark,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _buildRecoCard(_recommandations[i], i),
                  childCount: _recommandations.length,
                ),
              ),
            ),
          ],

          if (!_loading && _recommandations.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Column(
                  children: [
                    const Text('🔍', style: TextStyle(fontSize: 60)),
                    const SizedBox(height: 16),
                    const Text(
                      'Aucune recommandation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.dark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complétez vos préférences dans votre profil',
                      style: TextStyle(color: AppTheme.muted, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadAndRecommend,
                      child: const Text('🔄 Réessayer'),
                    ),
                  ],
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildRecoCard(Map<String, dynamic> ville, int index) {
    final medals = ['🥇', '🥈', '🥉'];
    final budget = ville['niveau_budget'] ?? '';
    final budgetColor = budget == 'Faible'
        ? const Color(0xFF4CAF50)
        : budget == 'Élevé'
        ? const Color(0xFFFF6B6B)
        : const Color(0xFFFFD97D);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailScreen(ville: ville)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: ville['image_url'] ?? '',
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 160,
                      color: AppTheme.primary.withValues(alpha: 0.15),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 160,
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      child: const Icon(
                        Icons.image_outlined,
                        color: AppTheme.primary,
                        size: 40,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        '${medals[index]} Choix ${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        'Score: ${ville['score']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ville['nom'] ?? '',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.dark,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Color(0xFFFFD97D),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${ville['popularite'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.dark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: AppTheme.muted,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${ville['pays']?['nom'] ?? ''} · ${ville['pays']?['continent'] ?? ''}',
                        style: TextStyle(fontSize: 13, color: AppTheme.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: budgetColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          budget,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: budgetColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          ville['temperature'] ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
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
}
