import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voyage_app/core/theme/app_theme.dart';

class ItineraireScreen extends StatefulWidget {
  final Map<String, dynamic> voyage;

  const ItineraireScreen({super.key, required this.voyage});

  @override
  State<ItineraireScreen> createState() => _ItineraireScreenState();
}

class _ItineraireScreenState extends State<ItineraireScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _itineraire = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _genererItineraire();
  }

  Future<void> _genererItineraire() async {
    setState(() => _loading = true);
    try {
      final user = _supabase.auth.currentUser!;
      final idPlan = widget.voyage['id'].toString();

      // Vérifier si un itinéraire existe déjà
      final existing = await _supabase
          .from('itineraire_jours')
          .select('*, activites(id, nom, categorie, prix, duree)')
          .eq('id_plan', idPlan)
          .order('jour');

      if (existing.isNotEmpty) {
        // Charger l'itinéraire existant
        final Map<int, List<Map<String, dynamic>>> parJour = {};
        for (final row in existing) {
          final jour = row['jour'] as int;
          parJour[jour] ??= [];
          if (row['activites'] != null) {
            parJour[jour]!.add({
              ...Map<String, dynamic>.from(row['activites']),
              'slot': row['slot'],
            });
          }
        }

        final dateDebut = DateTime.parse(widget.voyage['date_debut']);
        final itineraire = parJour.entries.map((e) {
          return {
            'jour': e.key,
            'date': dateDebut.add(Duration(days: e.key - 1)),
            'ville': '',
            'activites': e.value,
          };
        }).toList();

        itineraire.sort((a, b) =>
            (a['jour'] as int).compareTo(b['jour'] as int));

        if (mounted) {
          setState(() {
            _itineraire = itineraire;
            _loading = false;
          });
        }
        return;
      }

      // Générer un nouvel itinéraire
      final prefs = await _supabase
          .from('preferences')
          .select()
          .eq('id_user', user.id)
          .maybeSingle();

      final centresInteret =
          List<String>.from(prefs?['centres_interet'] ?? []);

      final planVilles = await _supabase
          .from('plan_villes')
          .select('villes(id, nom, activites(id, nom, categorie, prix, duree))')
          .eq('id_plan', idPlan);

      if (planVilles.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final ville = planVilles[0]['villes'] as Map<String, dynamic>;
      final activites =
          List<Map<String, dynamic>>.from(ville['activites'] ?? []);

      final dateDebut = DateTime.parse(widget.voyage['date_debut']);
      final dateFin = DateTime.parse(widget.voyage['date_fin']);
      final nbJours = dateFin.difference(dateDebut).inDays;

      // Trier selon centres d'intérêt
      activites.sort((a, b) {
        final aMatch = centresInteret.any((c) =>
            (a['categorie'] ?? '').toLowerCase().contains(c.toLowerCase()));
        final bMatch = centresInteret.any((c) =>
            (b['categorie'] ?? '').toLowerCase().contains(c.toLowerCase()));
        if (aMatch && !bMatch) return -1;
        if (!aMatch && bMatch) return 1;
        return 0;
      });

      final List<Map<String, dynamic>> itineraire = [];
      final List<Map<String, dynamic>> rowsToInsert = [];
      final slots = ['🌅 Matin', '🌞 Après-midi', '🌙 Soir'];
      int activiteIndex = 0;

      for (int jour = 1; jour <= nbJours; jour++) {
        final date = dateDebut.add(Duration(days: jour - 1));
        final List<Map<String, dynamic>> activitesJour = [];

        for (int slot = 0;
            slot < 2 && activiteIndex < activites.length;
            slot++) {
          final activite = activites[activiteIndex];
          activitesJour.add({
            ...activite,
            'slot': slots[slot],
          });

          rowsToInsert.add({
            'id_plan': idPlan,
            'jour': jour,
            'date': date.toIso8601String().split('T')[0],
            'id_activite': activite['id'].toString(),
            'slot': slots[slot],
          });

          activiteIndex++;
        }

        if (activitesJour.isEmpty && activites.isNotEmpty) {
          final activite = activites[jour % activites.length];
          activitesJour.add({...activite, 'slot': slots[0]});
          rowsToInsert.add({
            'id_plan': idPlan,
            'jour': jour,
            'date': date.toIso8601String().split('T')[0],
            'id_activite': activite['id'].toString(),
            'slot': slots[0],
          });
        }

        itineraire.add({
          'jour': jour,
          'date': date,
          'ville': ville['nom'],
          'activites': activitesJour,
        });
      }

      // Sauvegarder dans la BDD
      if (rowsToInsert.isNotEmpty) {
        await _supabase.from('itineraire_jours').insert(rowsToInsert);
      }

      if (mounted) {
        setState(() {
          _itineraire = itineraire;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur itinéraire: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDate(DateTime date) {
    const jours = [
      'Lundi', 'Mardi', 'Mercredi', 'Jeudi',
      'Vendredi', 'Samedi', 'Dimanche'
    ];
    const mois = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
      'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return '${jours[date.weekday - 1]} ${date.day} ${mois[date.month - 1]}';
  }

  String _emojiCategorie(String? categorie) {
    switch (categorie?.toLowerCase()) {
      case 'culture': return '🏛️';
      case 'nature': return '🌿';
      case 'gastronomie': return '🍜';
      case 'aventure': return '🧗';
      case 'shopping': return '🛍️';
      case 'détente': return '🧘';
      default: return '🎯';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppTheme.primary,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF00C9B1), Color(0xFF7C3AED)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 50, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text('🗓️ Mon itinéraire',
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(
                          widget.voyage['titre'] ?? '',
                          style: const TextStyle(
                              fontSize: 15, color: Colors.white70),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildInfoChip(
                                '📅 ${_itineraire.length} jours'),
                            const SizedBox(width: 8),
                            if (widget.voyage['type_voyage'] != null)
                              _buildInfoChip(
                                  '👥 ${widget.voyage['type_voyage']}'),
                            const SizedBox(width: 8),
                            if (widget.voyage['budget_total'] != null &&
                                widget.voyage['budget_total'] > 0)
                              _buildInfoChip(
                                  '💰 ${widget.voyage['budget_total']}€'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Loading
          if (_loading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 80),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppTheme.primary),
                    SizedBox(height: 16),
                    Text('Génération de votre itinéraire...',
                        style: TextStyle(
                            color: AppTheme.muted, fontSize: 14)),
                  ],
                ),
              ),
            ),

          // Itinéraire
          if (!_loading && _itineraire.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _buildJourCard(_itineraire[i]),
                  childCount: _itineraire.length,
                ),
              ),
            ),

          // Vide
          if (!_loading && _itineraire.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Column(
                  children: [
                    const Text('📭',
                        style: TextStyle(fontSize: 60)),
                    const SizedBox(height: 16),
                    const Text('Aucune activité disponible',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.dark)),
                    const SizedBox(height: 8),
                    Text(
                      'Ajoutez des activités à cette destination',
                      style: TextStyle(
                          color: AppTheme.muted, fontSize: 14),
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

  Widget _buildInfoChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildJourCard(Map<String, dynamic> jour) {
    final activites =
        List<Map<String, dynamic>>.from(jour['activites'] ?? []);
    final date = jour['date'] as DateTime;
    final isWeekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header jour
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: isWeekend
                  ? AppTheme.coral.withValues(alpha: 0.1)
                  : AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isWeekend ? AppTheme.coral : AppTheme.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      'J${jour['jour']}',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jour ${jour['jour']}',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isWeekend
                              ? AppTheme.coral
                              : AppTheme.primary),
                    ),
                    Text(
                      _formatDate(date),
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.muted),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isWeekend
                        ? AppTheme.coral.withValues(alpha: 0.15)
                        : AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    '${activites.length} activité${activites.length > 1 ? 's' : ''}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isWeekend
                            ? AppTheme.coral
                            : AppTheme.primary),
                  ),
                ),
              ],
            ),
          ),

          // Activités du jour
          if (activites.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('🌅', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Text('Journée libre — explorez à votre rythme !',
                      style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.muted,
                          fontStyle: FontStyle.italic)),
                ],
              ),
            )
          else
            ...activites.asMap().entries.map((entry) {
              final i = entry.key;
              final activite = entry.value;
              final isLast = i == activites.length - 1;
              final slots = ['🌅 Matin', '🌞 Après-midi', '🌙 Soir'];
              final slot = slots[i % slots.length];

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Timeline
                        Column(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppTheme.primary
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  _emojiCategorie(activite['categorie']),
                                  style:
                                      const TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                            if (!isLast)
                              Container(
                                width: 2,
                                height: 30,
                                color: AppTheme.primary
                                    .withValues(alpha: 0.2),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(slot,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.muted,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 2),
                              Text(
                                activite['nom'] ?? '',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.dark),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (activite['duree'] != null)
                                    _buildTag(
                                        '⏱️ ${activite['duree']}'),
                                  const SizedBox(width: 6),
                                  if (activite['prix'] != null)
                                    _buildTag(
                                      activite['prix'] == 0
                                          ? '🎉 Gratuit'
                                          : '💶 ${activite['prix']}€',
                                    ),
                                  const SizedBox(width: 6),
                                  if (activite['categorie'] != null)
                                    _buildTag(activite['categorie']),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                        height: 1,
                        color: Colors.grey.shade100,
                        indent: 16,
                        endIndent: 16),
                ],
              );
            }),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10, color: AppTheme.muted)),
    );
  }
}