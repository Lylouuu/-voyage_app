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
  List<Map<String, dynamic>> _activitesDispo = [];
  List<Map<String, dynamic>> _hotelsDispo = [];
  List<Map<String, dynamic>> _restaurantsDispo = [];
  bool _loading = true;

  final Map<String, String> _horaires = {
    '🌅 Matin': '09h00',
    '🌞 Après-midi': '14h00',
    '🌙 Soir': '19h00',
    '🏨 Nuit': '21h00',
  };

  // Index modifiables pour restos et hôtels par jour
  final Map<int, int> _restoIndex = {};
  final Map<int, int> _hotelIndex = {};

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

      final planVilles = await _supabase
          .from('plan_villes')
          .select('villes(id, nom)')
          .eq('id_plan', idPlan);

      if (planVilles.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final ville = planVilles[0]['villes'] as Map<String, dynamic>;
      final idVille = ville['id'].toString();

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

      _activitesDispo = List<Map<String, dynamic>>.from(activites);
      _hotelsDispo = List<Map<String, dynamic>>.from(hotels);
      _restaurantsDispo = List<Map<String, dynamic>>.from(restaurants);

      final existing = await _supabase
          .from('itineraire_jours')
          .select('*, activites(id, nom, categorie, prix, duree)')
          .eq('id_plan', idPlan)
          .order('jour');

      if (existing.isNotEmpty) {
        _chargerExistant(existing);
        return;
      }

      final prefs = await _supabase
          .from('preferences')
          .select()
          .eq('id_user', user.id)
          .maybeSingle();

      final centresInteret =
          List<String>.from(prefs?['centres_interet'] ?? []);

      final actsTriees = List<Map<String, dynamic>>.from(_activitesDispo);
      actsTriees.sort((a, b) {
        final aMatch = centresInteret.any((c) =>
            (a['categorie'] ?? '').toLowerCase().contains(c.toLowerCase()));
        final bMatch = centresInteret.any((c) =>
            (b['categorie'] ?? '').toLowerCase().contains(c.toLowerCase()));
        if (aMatch && !bMatch) return -1;
        if (!aMatch && bMatch) return 1;
        return 0;
      });

      final dateDebut = DateTime.parse(widget.voyage['date_debut']);
      final dateFin = DateTime.parse(widget.voyage['date_fin']);
      final nbJours = dateFin.difference(dateDebut).inDays;

      final List<Map<String, dynamic>> itineraire = [];
      final List<Map<String, dynamic>> rowsToInsert = [];
      int actIndex = 0;

      for (int jour = 1; jour <= nbJours; jour++) {
        final date = dateDebut.add(Duration(days: jour - 1));
        final List<Map<String, dynamic>> items = [];

        _restoIndex[jour] = jour % _restaurantsDispo.length;
        _hotelIndex[jour] = jour % _hotelsDispo.length;

        if (actIndex < actsTriees.length) {
          final act = actsTriees[actIndex];
          items.add({...act, 'slot': '🌅 Matin', 'type': 'activite'});
          rowsToInsert.add({
            'id_plan': idPlan,
            'jour': jour,
            'date': date.toIso8601String().split('T')[0],
            'id_activite': act['id'].toString(),
            'slot': '🌅 Matin',
          });
          actIndex++;
        }

        if (actIndex < actsTriees.length) {
          final act = actsTriees[actIndex];
          items.add({...act, 'slot': '🌞 Après-midi', 'type': 'activite'});
          rowsToInsert.add({
            'id_plan': idPlan,
            'jour': jour,
            'date': date.toIso8601String().split('T')[0],
            'id_activite': act['id'].toString(),
            'slot': '🌞 Après-midi',
          });
          actIndex++;
        }

        if (_restaurantsDispo.isNotEmpty) {
          final resto = _restaurantsDispo[_restoIndex[jour]!];
          items.add({...resto, 'slot': '🌙 Soir', 'type': 'restaurant'});
        }

        if (_hotelsDispo.isNotEmpty) {
          final hotel = _hotelsDispo[_hotelIndex[jour]!];
          items.add({...hotel, 'slot': '🏨 Nuit', 'type': 'hotel'});
        }

        itineraire.add({
          'jour': jour,
          'date': date,
          'ville': ville['nom'],
          'items': items,
        });
      }

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

  void _chargerExistant(List existing) {
    final dateDebut = DateTime.parse(widget.voyage['date_debut']);
    final Map<int, List<Map<String, dynamic>>> parJour = {};

    for (final row in existing) {
      final jour = row['jour'] as int;
      parJour[jour] ??= [];
      if (row['activites'] != null) {
        parJour[jour]!.add({
          ...Map<String, dynamic>.from(row['activites']),
          'slot': row['slot'],
          'type': 'activite',
          'row_id': row['id'],
        });
      }
    }

    for (final entry in parJour.entries) {
      final jour = entry.key;
      final ri = _restoIndex[jour] ?? jour % (_restaurantsDispo.isEmpty ? 1 : _restaurantsDispo.length);
      final hi = _hotelIndex[jour] ?? jour % (_hotelsDispo.isEmpty ? 1 : _hotelsDispo.length);

      if (_restaurantsDispo.isNotEmpty) {
        parJour[jour]!.add({
          ..._restaurantsDispo[ri],
          'slot': '🌙 Soir',
          'type': 'restaurant',
        });
      }
      if (_hotelsDispo.isNotEmpty) {
        parJour[jour]!.add({
          ..._hotelsDispo[hi],
          'slot': '🏨 Nuit',
          'type': 'hotel',
        });
      }
    }

    final itineraire = parJour.entries.map((e) => {
          'jour': e.key,
          'date': dateDebut.add(Duration(days: e.key - 1)),
          'ville': '',
          'items': e.value,
        }).toList();

    itineraire.sort((a, b) => (a['jour'] as int).compareTo(b['jour'] as int));

    if (mounted) {
      setState(() {
        _itineraire = itineraire;
        _loading = false;
      });
    }
  }

  // ── Modifier activité ──────────────────────────────────────
  Future<void> _modifierActivite(
      Map<String, dynamic> jour, Map<String, dynamic> item) async {
    final slot = item['slot'] as String;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildPicker(
        titre: 'Choisir une activité — $slot',
        items: _activitesDispo,
        emoji: (a) => _emojiCategorie(a['categorie']),
        titre2: (a) => a['nom'] ?? '',
        sousTitre: (a) =>
            '${a['duree'] ?? ''} · ${a['prix'] == 0 ? 'Gratuit' : '${a['prix']}€'}',
        couleur: AppTheme.primary,
      ),
    );

    if (result != null) {
      final idPlan = widget.voyage['id'].toString();
      final jourNum = jour['jour'] as int;
      final dateDebut = DateTime.parse(widget.voyage['date_debut']);
      final date = dateDebut.add(Duration(days: jourNum - 1));

      await _supabase
          .from('itineraire_jours')
          .delete()
          .eq('id_plan', idPlan)
          .eq('jour', jourNum)
          .eq('slot', slot);

      await _supabase.from('itineraire_jours').insert({
        'id_plan': idPlan,
        'jour': jourNum,
        'date': date.toIso8601String().split('T')[0],
        'id_activite': result['id'].toString(),
        'slot': slot,
      });

      _showSnack('✅ Activité modifiée !', AppTheme.primary);
      await _recharger();
    }
  }

  // ── Modifier restaurant ────────────────────────────────────
  Future<void> _modifierRestaurant(
      Map<String, dynamic> jour, Map<String, dynamic> item) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildPicker(
        titre: 'Choisir un restaurant',
        items: _restaurantsDispo,
        emoji: (_) => '🍽️',
        titre2: (r) => r['nom'] ?? '',
        sousTitre: (r) =>
            '${r['type_cuisine'] ?? ''} · ${r['prix_moyen'] != null ? '${r['prix_moyen']}€ moy.' : ''}',
        couleur: const Color(0xFFFF6B6B),
      ),
    );

    if (result != null) {
      final jourNum = jour['jour'] as int;
      setState(() {
        _restoIndex[jourNum] = _restaurantsDispo.indexOf(result);
        final items = List<Map<String, dynamic>>.from(
            _itineraire[jourNum - 1]['items']);
        final idx = items.indexWhere((i) => i['type'] == 'restaurant');
        if (idx != -1) {
          items[idx] = {...result, 'slot': '🌙 Soir', 'type': 'restaurant'};
          _itineraire[jourNum - 1]['items'] = items;
        }
      });
      _showSnack('✅ Restaurant modifié !', const Color(0xFFFF6B6B));
    }
  }

  // ── Modifier hôtel ─────────────────────────────────────────
  Future<void> _modifierHotel(
      Map<String, dynamic> jour, Map<String, dynamic> item) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildPicker(
        titre: 'Choisir un hôtel',
        items: _hotelsDispo,
        emoji: (_) => '🏨',
        titre2: (h) => h['nom'] ?? '',
        sousTitre: (h) =>
            '${h['etoiles'] ?? ''} ⭐ · ${h['prix'] != null ? '${h['prix']}€/nuit' : ''}',
        couleur: const Color(0xFF7C3AED),
      ),
    );

    if (result != null) {
      final jourNum = jour['jour'] as int;
      setState(() {
        _hotelIndex[jourNum] = _hotelsDispo.indexOf(result);
        final items = List<Map<String, dynamic>>.from(
            _itineraire[jourNum - 1]['items']);
        final idx = items.indexWhere((i) => i['type'] == 'hotel');
        if (idx != -1) {
          items[idx] = {...result, 'slot': '🏨 Nuit', 'type': 'hotel'};
          _itineraire[jourNum - 1]['items'] = items;
        }
      });
      _showSnack('✅ Hôtel modifié !', const Color(0xFF7C3AED));
    }
  }

  // ── Supprimer activité ─────────────────────────────────────
  Future<void> _supprimerActivite(
      Map<String, dynamic> jour, Map<String, dynamic> item) async {
    final idPlan = widget.voyage['id'].toString();
    final jourNum = jour['jour'] as int;
    final slot = item['slot'] as String;

    await _supabase
        .from('itineraire_jours')
        .delete()
        .eq('id_plan', idPlan)
        .eq('jour', jourNum)
        .eq('slot', slot);

    _showSnack('🗑️ Activité supprimée', AppTheme.coral);
    await _recharger();
  }

  // ── Ajouter activité ───────────────────────────────────────
  Future<void> _ajouterActivite(Map<String, dynamic> jour) async {
    final slotsDispos = ['🌅 Matin', '🌞 Après-midi'];
    final itemsJour = List<Map<String, dynamic>>.from(jour['items'] ?? []);
    final slotsUtilises = itemsJour
        .where((i) => i['type'] == 'activite')
        .map((i) => i['slot'] as String)
        .toList();
    final slotLibre = slotsDispos.firstWhere(
        (s) => !slotsUtilises.contains(s),
        orElse: () => '');

    if (slotLibre.isEmpty) {
      _showSnack('Maximum 2 activités par jour', AppTheme.coral);
      return;
    }

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildPicker(
        titre: 'Ajouter une activité — $slotLibre',
        items: _activitesDispo,
        emoji: (a) => _emojiCategorie(a['categorie']),
        titre2: (a) => a['nom'] ?? '',
        sousTitre: (a) =>
            '${a['duree'] ?? ''} · ${a['prix'] == 0 ? 'Gratuit' : '${a['prix']}€'}',
        couleur: AppTheme.primary,
      ),
    );

    if (result != null) {
      final idPlan = widget.voyage['id'].toString();
      final jourNum = jour['jour'] as int;
      final dateDebut = DateTime.parse(widget.voyage['date_debut']);
      final date = dateDebut.add(Duration(days: jourNum - 1));

      await _supabase.from('itineraire_jours').insert({
        'id_plan': idPlan,
        'jour': jourNum,
        'date': date.toIso8601String().split('T')[0],
        'id_activite': result['id'].toString(),
        'slot': slotLibre,
      });

      _showSnack('✅ Activité ajoutée !', AppTheme.primary);
      await _recharger();
    }
  }

  Future<void> _recharger() async {
    final idPlan = widget.voyage['id'].toString();
    final existing = await _supabase
        .from('itineraire_jours')
        .select('*, activites(id, nom, categorie, prix, duree)')
        .eq('id_plan', idPlan)
        .order('jour');
    _chargerExistant(existing);
  }

  // ── Picker générique ───────────────────────────────────────
  Widget _buildPicker({
    required String titre,
    required List<Map<String, dynamic>> items,
    required String Function(Map<String, dynamic>) emoji,
    required String Function(Map<String, dynamic>) titre2,
    required String Function(Map<String, dynamic>) sousTitre,
    required Color couleur,
  }) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              titre,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dark),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: couleur.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(emoji(item),
                          style: const TextStyle(fontSize: 18)),
                    ),
                  ),
                  title: Text(titre2(item),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.dark)),
                  subtitle: Text(sousTitre(item),
                      style:
                          TextStyle(fontSize: 12, color: AppTheme.muted)),
                  onTap: () => Navigator.pop(context, item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  String _formatDate(DateTime date) {
    const jours = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    const mois = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
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
                child: const Icon(Icons.arrow_back, color: Colors.white),
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
                        Text(widget.voyage['titre'] ?? '',
                            style: const TextStyle(
                                fontSize: 15, color: Colors.white70)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildInfoChip('📅 ${_itineraire.length} jours'),
                            const SizedBox(width: 8),
                            if (widget.voyage['type_voyage'] != null)
                              _buildInfoChip('👥 ${widget.voyage['type_voyage']}'),
                            const SizedBox(width: 8),
                            if (widget.voyage['budget_total'] != null &&
                                widget.voyage['budget_total'] > 0)
                              _buildInfoChip('💰 ${widget.voyage['budget_total']}€'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
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
                    Text('Génération de votre itinéraire...',
                        style: TextStyle(color: AppTheme.muted, fontSize: 14)),
                  ],
                ),
              ),
            ),

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

          if (!_loading && _itineraire.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Column(
                  children: [
                    const Text('📭', style: TextStyle(fontSize: 60)),
                    const SizedBox(height: 16),
                    const Text('Aucune activité disponible',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.dark)),
                    const SizedBox(height: 8),
                    Text('Ajoutez des activités à cette destination',
                        style: TextStyle(color: AppTheme.muted, fontSize: 14)),
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
              fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildJourCard(Map<String, dynamic> jour) {
    final items = List<Map<String, dynamic>>.from(jour['items'] ?? []);
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
                    child: Text('J${jour['jour']}',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Jour ${jour['jour']}',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isWeekend
                                ? AppTheme.coral
                                : AppTheme.primary)),
                    Text(_formatDate(date),
                        style: TextStyle(fontSize: 12, color: AppTheme.muted)),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _ajouterActivite(jour),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.add, color: AppTheme.primary, size: 14),
                        const SizedBox(width: 4),
                        Text('Ajouter',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Items du jour
          ...items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final isLast = i == items.length - 1;
            final type = item['type'] as String? ?? 'activite';
            final slot = item['slot'] as String? ?? '';
            final horaire = _horaires[slot] ?? '';

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: _colorForType(type).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                _emojiForType(type, item['categorie']),
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                          if (!isLast)
                            Container(
                                width: 2,
                                height: 28,
                                color: Colors.grey.shade200),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(slot,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.muted,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _colorForType(type)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: Text(horaire,
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: _colorForType(type),
                                          fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(item['nom'] ?? '',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.dark)),
                            const SizedBox(height: 4),
                            if (type == 'activite')
                              Row(children: [
                                if (item['duree'] != null)
                                  _buildTag('⏱️ ${item['duree']}'),
                                const SizedBox(width: 6),
                                if (item['prix'] != null)
                                  _buildTag(item['prix'] == 0
                                      ? '🎉 Gratuit'
                                      : '💶 ${item['prix']}€'),
                              ]),
                            if (type == 'restaurant')
                              Row(children: [
                                if (item['type_cuisine'] != null)
                                  _buildTag('🍴 ${item['type_cuisine']}'),
                                const SizedBox(width: 6),
                                if (item['prix_moyen'] != null)
                                  _buildTag('💶 ${item['prix_moyen']}€ moy.'),
                              ]),
                            if (type == 'hotel')
                              Row(children: [
                                if (item['etoiles'] != null)
                                  _buildTag('⭐ ${item['etoiles']} étoiles'),
                                const SizedBox(width: 6),
                                if (item['prix'] != null)
                                  _buildTag('💶 ${item['prix']}€/nuit'),
                              ]),
                          ],
                        ),
                      ),

                      // Boutons selon type
                      if (type == 'activite')
                        Row(children: [
                          _actionBtn(Icons.edit_outlined, AppTheme.primary,
                              () => _modifierActivite(jour, item)),
                          const SizedBox(width: 6),
                          _actionBtn(Icons.delete_outline, AppTheme.coral,
                              () => _supprimerActivite(jour, item)),
                        ]),
                      if (type == 'restaurant')
                        _actionBtn(Icons.swap_horiz,
                            const Color(0xFFFF6B6B),
                            () => _modifierRestaurant(jour, item)),
                      if (type == 'hotel')
                        _actionBtn(Icons.swap_horiz,
                            const Color(0xFF7C3AED),
                            () => _modifierHotel(jour, item)),
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

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'restaurant': return const Color(0xFFFF6B6B);
      case 'hotel': return const Color(0xFF7C3AED);
      default: return AppTheme.primary;
    }
  }

  String _emojiForType(String type, String? categorie) {
    if (type == 'restaurant') return '🍽️';
    if (type == 'hotel') return '🏨';
    return _emojiCategorie(categorie);
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