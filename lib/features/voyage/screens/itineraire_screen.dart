import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
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
  String? _villeImageUrl;

  final Map<String, String> _horaires = {
    '🌅 Matin': '09h00',
    '🌞 Après-midi': '14h00',
    '🌙 Soir': '19h00',
    '🏨 Nuit': '22h00',
  };

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
          .select('villes(id, nom, image_url)')
          .eq('id_plan', idPlan);

      if (planVilles.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final ville = planVilles[0]['villes'] as Map<String, dynamic>;
      final idVille = ville['id'].toString();
      _villeImageUrl = ville['image_url'];

      final activites = await _supabase.from('activites').select().eq('id_ville', idVille);
      final hotels = await _supabase.from('hotels').select().eq('id_ville', idVille);
      final restaurants = await _supabase.from('restaurants').select().eq('id_ville', idVille);

      _activitesDispo = List<Map<String, dynamic>>.from(activites);
      _hotelsDispo = List<Map<String, dynamic>>.from(hotels);
      _restaurantsDispo = List<Map<String, dynamic>>.from(restaurants);

      final existing = await _supabase
          .from('itineraire_jours')
          .select('*, activites(id, nom, categorie, prix, duree)')
          .eq('id_plan', idPlan)
          .order('jour');

      if (existing.isNotEmpty) {
        _chargerExistant(existing, ville['nom']);
        return;
      }

      final prefs = await _supabase.from('preferences').select().eq('id_user', user.id).maybeSingle();
      final centresInteret = List<String>.from(prefs?['centres_interet'] ?? []);

      final actsTriees = List<Map<String, dynamic>>.from(_activitesDispo);
      actsTriees.sort((a, b) {
        final aMatch = centresInteret.any((c) => (a['categorie'] ?? '').toLowerCase().contains(c.toLowerCase()));
        final bMatch = centresInteret.any((c) => (b['categorie'] ?? '').toLowerCase().contains(c.toLowerCase()));
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

        _restoIndex[jour] = jour % (_restaurantsDispo.isEmpty ? 1 : _restaurantsDispo.length);
        _hotelIndex[jour] = jour % (_hotelsDispo.isEmpty ? 1 : _hotelsDispo.length);

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

  void _chargerExistant(List existing, String? villeName) {
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
          'ville': villeName ?? '',
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

  // ── Database Edits ─────────────────────────────────────────
  Future<void> _modifierActivite(Map<String, dynamic> jour, Map<String, dynamic> item) async {
    final slot = item['slot'] as String;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildPicker(
        titre: 'Activité ($slot)',
        items: _activitesDispo,
        emoji: (a) => _emojiCategorie(a['categorie']),
        titre2: (a) => a['nom'] ?? '',
        sousTitre: (a) => '${a['duree'] ?? ''} · ${a['prix'] == 0 ? 'Gratuit' : '${a['prix']}€'}',
        couleur: const Color(0xFF00E5FF),
      ),
    );

    if (result != null) {
      await _remplacerData(jour, item, result, 'id_activite', slot);
      _showSnack('Activité mise à jour 🌴', const Color(0xFF00E5FF));
    }
  }

  Future<void> _modifierRestaurant(Map<String, dynamic> jour, Map<String, dynamic> item) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildPicker(
        titre: 'Restaurant',
        items: _restaurantsDispo,
        emoji: (_) => '🍽️',
        titre2: (r) => r['nom'] ?? '',
        sousTitre: (r) => '${r['type_cuisine'] ?? ''} · ${r['prix_moyen'] != null ? '${r['prix_moyen']}€ moy.' : ''}',
        couleur: const Color(0xFFFF5252),
      ),
    );

    if (result != null) {
      final jourNum = jour['jour'] as int;
      setState(() {
        _restoIndex[jourNum] = _restaurantsDispo.indexOf(result);
        final items = List<Map<String, dynamic>>.from(_itineraire[jourNum - 1]['items']);
        final idx = items.indexWhere((i) => i['type'] == 'restaurant');
        if (idx != -1) {
          items[idx] = {...result, 'slot': '🌙 Soir', 'type': 'restaurant'};
          _itineraire[jourNum - 1]['items'] = items;
        }
      });
      _showSnack('Restaurant réservé 🍷', const Color(0xFFFF5252));
    }
  }

  Future<void> _modifierHotel(Map<String, dynamic> jour, Map<String, dynamic> item) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildPicker(
        titre: 'Hébergement',
        items: _hotelsDispo,
        emoji: (_) => '🏨',
        titre2: (h) => h['nom'] ?? '',
        sousTitre: (h) => '${h['etoiles'] ?? ''} ⭐ · ${h['prix'] != null ? '${h['prix']}€/nuit' : ''}',
        couleur: const Color(0xFF9080FF),
      ),
    );

    if (result != null) {
      final jourNum = jour['jour'] as int;
      setState(() {
        _hotelIndex[jourNum] = _hotelsDispo.indexOf(result);
        final items = List<Map<String, dynamic>>.from(_itineraire[jourNum - 1]['items']);
        final idx = items.indexWhere((i) => i['type'] == 'hotel');
        if (idx != -1) {
          items[idx] = {...result, 'slot': '🏨 Nuit', 'type': 'hotel'};
          _itineraire[jourNum - 1]['items'] = items;
        }
      });
      _showSnack('Hôtel mis à jour 🏨', const Color(0xFF9080FF));
    }
  }

  Future<void> _remplacerData(Map<String, dynamic> jour, Map<String, dynamic> oldItem, Map<String, dynamic> newItem, String dbFieldId, String slot) async {
    final idPlan = widget.voyage['id'].toString();
    final jourNum = jour['jour'] as int;
    final dateDebut = DateTime.parse(widget.voyage['date_debut']);
    final date = dateDebut.add(Duration(days: jourNum - 1));

    await _supabase.from('itineraire_jours').delete().eq('id_plan', idPlan).eq('jour', jourNum).eq('slot', slot);

    await _supabase.from('itineraire_jours').insert({
      'id_plan': idPlan,
      'jour': jourNum,
      'date': date.toIso8601String().split('T')[0],
      dbFieldId: newItem['id'].toString(),
      'slot': slot,
    });
    await _genererItineraire(); // Re-trigger flow
  }

  Future<void> _supprimerActivite(Map<String, dynamic> jour, Map<String, dynamic> item) async {
    final idPlan = widget.voyage['id'].toString();
    final jourNum = jour['jour'] as int;
    final slot = item['slot'] as String;

    await _supabase.from('itineraire_jours').delete().eq('id_plan', idPlan).eq('jour', jourNum).eq('slot', slot);

    _showSnack('Ligne supprimée ❌', Colors.redAccent);
    await _genererItineraire();
  }

  Future<void> _ajouterActivite(Map<String, dynamic> jour) async {
    final slotsDispos = ['🌅 Matin', '🌞 Après-midi'];
    final itemsJour = List<Map<String, dynamic>>.from(jour['items'] ?? []);
    final slotsUtilises = itemsJour.where((i) => i['type'] == 'activite').map((i) => i['slot'] as String).toList();
    final slotLibre = slotsDispos.firstWhere((s) => !slotsUtilises.contains(s), orElse: () => '');

    if (slotLibre.isEmpty) {
      _showSnack('Planning d\'activités complet !', Colors.orangeAccent);
      return;
    }

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildPicker(
        titre: 'Ajouter — $slotLibre',
        items: _activitesDispo,
        emoji: (a) => _emojiCategorie(a['categorie']),
        titre2: (a) => a['nom'] ?? '',
        sousTitre: (a) => '${a['duree'] ?? ''} · ${a['prix'] == 0 ? 'Gratuit' : '${a['prix']}€'}',
        couleur: AppTheme.limeGreen,
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

      _showSnack('Itinéraire étoffé ! ✨', AppTheme.limeGreen);
      await _genererItineraire();
    }
  }

  // ── Utils ────────────────────────────────────────────────
  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: TextStyle(color: color == AppTheme.limeGreen ? const Color(0xFF0F1B2D) : Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const jours = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    const mois = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${jours[date.weekday - 1]} ${date.day} ${mois[date.month - 1]}';
  }

  String _emojiForType(String type, String? cat) {
    if (type == 'restaurant') return '🍽️';
    if (type == 'hotel') return '🏨';
    return _emojiCategorie(cat);
  }

  Color _colorForSlot(String slot) {
    if (slot.contains('Matin')) return const Color(0xFFFFD97D); // Warm Morning
    if (slot.contains('Après-midi')) return const Color(0xFFFF9F43); // Vibrant Orange Afternoon
    if (slot.contains('Soir')) return const Color(0xFFFF5252); // Red Sunset
    if (slot.contains('Nuit')) return const Color(0xFF9080FF); // Purple Night
    return AppTheme.limeGreen;
  }

  String _emojiCategorie(String? categorie) {
    switch (categorie?.toLowerCase()) {
      case 'culture': return '🏛️';
      case 'nature': return '🌿';
      case 'gastronomie': return '🍜';
      case 'aventure': return '🧗';
      case 'shopping': return '🛍️';
      case 'détente': return '🧘';
      default: return '📍';
    }
  }

  // ── UI BUILD ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkNavy, // Cosmic deep space blue
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.limeGreen))
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildDynamicHeroHeader(),
                
                if (_itineraire.isEmpty)
                  SliverToBoxAdapter(child: _buildEmptyState())
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 60), // Breathing room
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _buildVibrantDayBlock(_itineraire[i]),
                        childCount: _itineraire.length,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildDynamicHeroHeader() {
    return SliverAppBar(
      expandedHeight: 280,
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
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Travel Parallax Hero
            if (_villeImageUrl != null && _villeImageUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: _villeImageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppTheme.darkNavyLight),
                errorWidget: (_, __, ___) => Container(color: AppTheme.darkNavyLight),
              )
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF00C9B1), Color(0xFF7C3AED)]),
                ),
              ),
            
            // Atmospheric gradient overlay bridging the photo to the dark UI
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),  // For upper back button readability
                    Colors.black.withOpacity(0.1),
                    AppTheme.darkNavy.withOpacity(0.8), // Start blending
                    AppTheme.darkNavy,            // Solid bridge
                  ],
                  stops: const [0.0, 0.4, 0.8, 1.0],
                ),
              ),
            ),
            
            // Immersive Typographic Layout
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Itinéraire',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.limeGreen,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.voyage['titre'] ?? 'Mon Voyage',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Vibrant Metadata pills
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildVibrantBadge(
                          icon: Icons.calendar_month_rounded, 
                          text: '${_itineraire.length} Jours', 
                          color: const Color(0xFF00E5FF)
                        ),
                        const SizedBox(width: 8),
                        if (widget.voyage['type_voyage'] != null)
                          _buildVibrantBadge(
                            icon: Icons.groups_rounded, 
                            text: widget.voyage['type_voyage'], 
                            color: const Color(0xFFFF9F43) // Orange vibe
                          ),
                        const SizedBox(width: 8),
                        if (widget.voyage['budget_total'] != null && widget.voyage['budget_total'] > 0)
                          _buildVibrantBadge(
                            icon: Icons.account_balance_wallet_rounded, 
                            text: '${widget.voyage['budget_total']}€', 
                            color: AppTheme.limeGreen
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVibrantBadge({required IconData icon, required String text, required Color color}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(text, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  // ── VIBRANT DAY BLOCKS ────────────────────────────────────────────────
  Widget _buildVibrantDayBlock(Map<String, dynamic> jour) {
    final items = List<Map<String, dynamic>>.from(jour['items'] ?? []);
    final date = jour['date'] as DateTime;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header of the Day
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Glowing day indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF00C9B1), Color(0xFF00E5FF)]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Text(
                    'Jour ${jour['jour']}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F1B2D)),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Date text
                Text(
                  _formatDate(date),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.9)),
                ),
                const Spacer(),
                
                // Elegant Ghost Add Button
                GestureDetector(
                  onTap: () => _ajouterActivite(jour),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add_rounded, color: Colors.white.withOpacity(0.6), size: 20),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Flowing Timeline
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Text("Temps libre pour flâner", style: TextStyle(color: Colors.white.withOpacity(0.3), fontStyle: FontStyle.italic)),
            )
          else
            ...items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final isLast = i == items.length - 1;
              return _buildTimelineRow(jour, item, isLast);
            }),
        ],
      ),
    );
  }

  Widget _buildTimelineRow(Map<String, dynamic> jour, Map<String, dynamic> item, bool isLast) {
    final type = item['type'] as String? ?? 'activite';
    final slot = item['slot'] as String? ?? '';
    final emoji = _emojiForType(type, item['categorie']);
    
    // Aesthetic assignment heavily influenced by the period of day
    final Color slotColor = _colorForSlot(slot);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Graphic Column: The Living Timeline Track
          SizedBox(
            width: 50,
            child: Column(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: slotColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: slotColor.withOpacity(0.3), blurRadius: 10),
                    ],
                    border: Border.all(color: slotColor.withOpacity(0.8), width: 2),
                  ),
                  child: Center(child: Text(emoji, style: const TextStyle(fontSize: 16))),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 3, // Thicker visible track
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            slotColor.withOpacity(0.6),
                            Colors.white.withOpacity(0.05), // Fades to neutral
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  )
                else 
                  const SizedBox(height: 20),
              ],
            ),
          ),
          
          // Graphic Content: The Glassmorphism Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _VibrantTimelineCard(
                jour: jour,
                item: item,
                horaire: _horaires[slot] ?? '',
                type: type,
                slotColor: slotColor,
                onEdit: () {
                  if (type == 'activite') _modifierActivite(jour, item);
                  if (type == 'restaurant') _modifierRestaurant(jour, item);
                  if (type == 'hotel') _modifierHotel(jour, item);
                },
                onDelete: () {
                  if (type == 'activite') _supprimerActivite(jour, item);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 100),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.flight_takeoff_rounded, size: 70, color: Colors.white.withOpacity(0.05)),
            const SizedBox(height: 24),
            Text('Planning Vide', style: TextStyle(fontSize: 22, color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // ── REUSING PREMIUM PICKER MENU ────────────────────────────────
  Widget _buildPicker({
    required String titre,
    required List<Map<String, dynamic>> items,
    required String Function(Map<String, dynamic>) emoji,
    required String Function(Map<String, dynamic>) titre2,
    required String Function(Map<String, dynamic>) sousTitre,
    required Color couleur,
  }) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: const Color(0xFF162544).withOpacity(0.8), // Glass deep
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
          ),
          child: Column(
            children: [
              Container(margin: const EdgeInsets.only(top: 10), width: 50, height: 5, decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(10))),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(titre, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return GestureDetector(
                      onTap: () => Navigator.pop(context, item),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withOpacity(0.02)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(color: couleur.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                              child: Center(child: Text(emoji(item), style: const TextStyle(fontSize: 22))),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(titre2(item), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                                  const SizedBox(height: 4),
                                  Text(sousTitre(item), style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6))),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.2)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// THE VIBRANT TIMELINE CARD WIDGET
// ─────────────────────────────────────────────
class _VibrantTimelineCard extends StatefulWidget {
  final Map<String, dynamic> jour;
  final Map<String, dynamic> item;
  final String horaire;
  final String type;
  final Color slotColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _VibrantTimelineCard({
    required this.jour,
    required this.item,
    required this.horaire,
    required this.type,
    required this.slotColor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_VibrantTimelineCard> createState() => _VibrantTimelineCardState();
}

class _VibrantTimelineCardState extends State<_VibrantTimelineCard> {
  bool _isTouched = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isTouched = true),
      onTapUp: (_) => setState(() => _isTouched = false),
      onTapCancel: () => setState(() => _isTouched = false),
      child: AnimatedScale(
        scale: _isTouched ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                // Intense glow base
                color: Colors.white.withOpacity(0.04), 
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: widget.slotColor.withOpacity(0.15), width: 1.5),
                boxShadow: [
                  BoxShadow(color: widget.slotColor.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Core Data
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.item['nom'] ?? 'Étape',
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.location_on_rounded, size: 12, color: widget.slotColor.withOpacity(0.8)),
                                const SizedBox(width: 4),
                                Text(
                                  (widget.type == 'restaurant') 
                                      ? (widget.item['type_cuisine'] ?? 'Restaurant') 
                                      : (widget.type == 'hotel') 
                                          ? 'Hébergement' 
                                          : (widget.item['categorie'] ?? ''),
                                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Highlighted Time Tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: widget.slotColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: widget.slotColor.withOpacity(0.5)),
                        ),
                        child: Text(
                          widget.horaire,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: widget.slotColor),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 14),
                  
                  // Meta Data (Durée, Prix)
                  Row(
                    children: [
                      if (widget.item['duree'] != null && widget.item['duree'].toString().isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(6)),
                          child: Row(
                            children: [
                              Icon(Icons.schedule_rounded, size: 12, color: Colors.white.withOpacity(0.6)),
                              const SizedBox(width: 4),
                              Text(widget.item['duree'], style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8))),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (widget.item['prix'] != null || widget.item['prix_moyen'] != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(6)),
                          child: Row(
                            children: [
                              Icon(Icons.euro_rounded, size: 12, color: Colors.white.withOpacity(0.6)),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.item['prix'] ?? widget.item['prix_moyen']}€', 
                                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.bold)
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Spacer(),
                      
                      // Hyper-subtle controls
                      Row(
                        children: [
                          GestureDetector(
                            onTap: widget.onEdit,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.02),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.edit_rounded, size: 16, color: Colors.white.withOpacity(0.2)), // Low opacity
                            ),
                          ),
                          if (widget.type == 'activite') ...[
                            GestureDetector(
                              onTap: widget.onDelete,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.02),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.close_rounded, size: 16, color: Colors.redAccent.withOpacity(0.3)), // Low opacity
                              ),
                            ),
                          ]
                        ],
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}