import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voyage_app/core/theme/app_theme.dart';

class CreateVoyageScreen extends StatefulWidget {
  const CreateVoyageScreen({super.key});

  @override
  State<CreateVoyageScreen> createState() => _CreateVoyageScreenState();
}

class _CreateVoyageScreenState extends State<CreateVoyageScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _notesController = TextEditingController();
  final _budgetController = TextEditingController();

  DateTime? _dateDebut;
  DateTime? _dateFin;
  bool _loading = false;
  List<Map<String, dynamic>> _villes = [];
  List<Map<String, dynamic>> _activites = [];
  List<String> _selectedActivites = [];
  String? _selectedVilleId;
  String _selectedType = 'Solo';

  final _types = [
    {'label': 'Solo', 'emoji': '🧳'},
    {'label': 'Couple', 'emoji': '💑'},
    {'label': 'Famille', 'emoji': '👨‍👩‍👧'},
    {'label': 'Groupe', 'emoji': '👥'},
  ];

  @override
  void initState() {
    super.initState();
    _loadVilles();
  }

  @override
  void dispose() {
    _titreController.dispose();
    _notesController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _loadVilles() async {
    final villes = await _supabase
        .from('villes')
        .select('id, nom, pays(nom)')
        .order('nom');
    if (mounted) {
      setState(() => _villes = List<Map<String, dynamic>>.from(villes));
    }
  }

  Future<void> _loadActivites(String villeId) async {
    final activites = await _supabase
        .from('activites')
        .select('id, nom, categorie, prix, duree')
        .eq('id_ville', villeId);
    if (mounted) {
      setState(() {
        _activites = List<Map<String, dynamic>>.from(activites);
        _selectedActivites = [];
      });
    }
  }

  Future<void> _pickDate({required bool isDebut}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isDebut ? now : (_dateDebut ?? now),
      firstDate: now,
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: ColorScheme.light(primary: AppTheme.primary)),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isDebut) {
          _dateDebut = picked;
          if (_dateFin != null && _dateFin!.isBefore(picked)) {
            _dateFin = null;
          }
        } else {
          _dateFin = picked;
        }
      });
    }
  }

  Future<void> _createVoyage() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateDebut == null || _dateFin == null) {
      _showSnack('Veuillez sélectionner les dates', AppTheme.coral);
      return;
    }
    if (_selectedVilleId == null) {
      _showSnack('Veuillez sélectionner une destination', AppTheme.coral);
      return;
    }

    setState(() => _loading = true);
    try {
      final user = _supabase.auth.currentUser!;

      // Créer le plan voyage
      final voyage = await _supabase
          .from('plans_voyage')
          .insert({
            'id_user': user.id,
            'titre': _titreController.text.trim(),
            'date_debut': _dateDebut!.toIso8601String().split('T')[0],
            'date_fin': _dateFin!.toIso8601String().split('T')[0],
            'statut': 'en cours',
            'budget_total': double.tryParse(_budgetController.text) ?? 0,
            'type_voyage': _selectedType,
            'notes': _notesController.text.trim(),
          })
          .select()
          .single();

      // Ajouter la ville
      await _supabase.from('plan_villes').insert({
        'id_plan': voyage['id'],
        'id_ville': _selectedVilleId,
      });

      if (mounted) {
        _showSnack('✅ Voyage créé avec succès !', AppTheme.primary);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) _showSnack('Erreur : $e', AppTheme.coral);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Sélectionner';
    return '${date.day}/${date.month}/${date.year}';
  }

  int _nombreJours() {
    if (_dateDebut == null || _dateFin == null) return 0;
    return _dateFin!.difference(_dateDebut!).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
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
                    colors: [Color(0xFF00C9B1), Color(0xFF0093E9)],
                  ),
                ),
                child: const SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 50, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '✈️ Créer un voyage',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Planifiez votre prochaine aventure',
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // ── Titre
                    _buildCard(
                      title: '📝 Nom du voyage',
                      child: TextFormField(
                        controller: _titreController,
                        style: const TextStyle(color: AppTheme.dark),
                        decoration: InputDecoration(
                          hintText: 'Ex: Vacances été 2025 à Bali',
                          hintStyle: TextStyle(
                            color: AppTheme.muted.withValues(alpha: 0.6),
                          ),
                          prefixIcon: const Icon(
                            Icons.edit_outlined,
                            color: AppTheme.primary,
                          ),
                        ),
                        validator: (v) => v!.isEmpty ? 'Nom requis' : null,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Type de voyage
                    _buildCard(
                      title: '👥 Type de voyage',
                      child: Row(
                        children: _types.map((t) {
                          final sel = _selectedType == t['label'];
                          return Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedType = t['label']!),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? AppTheme.primary
                                      : AppTheme.background,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: sel
                                        ? AppTheme.primary
                                        : Colors.grey.shade200,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      t['emoji']!,
                                      style: const TextStyle(fontSize: 22),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      t['label']!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: sel
                                            ? Colors.white
                                            : AppTheme.dark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Destination
                    _buildCard(
                      title: '🌍 Destination',
                      child: DropdownButtonFormField<String>(
                        value: _selectedVilleId,
                        decoration: InputDecoration(
                          hintText: 'Choisir une ville',
                          hintStyle: TextStyle(
                            color: AppTheme.muted.withValues(alpha: 0.6),
                          ),
                          prefixIcon: const Icon(
                            Icons.location_on_outlined,
                            color: AppTheme.primary,
                          ),
                        ),
                        items: _villes.map((v) {
                          return DropdownMenuItem<String>(
                            value: v['id'].toString(),
                            child: Text(
                              '${v['nom']} — ${v['pays']?['nom'] ?? ''}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.dark,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedVilleId = val);
                          if (val != null) _loadActivites(val);
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Activités
                    if (_activites.isNotEmpty)
                      _buildCard(
                        title: '🎯 Activités à faire',
                        child: Column(
                          children: _activites.map((a) {
                            final sel = _selectedActivites.contains(
                              a['id'].toString(),
                            );
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (sel) {
                                    _selectedActivites.remove(
                                      a['id'].toString(),
                                    );
                                  } else {
                                    _selectedActivites.add(a['id'].toString());
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? AppTheme.primary.withValues(alpha: 0.08)
                                      : AppTheme.background,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: sel
                                        ? AppTheme.primary
                                        : Colors.grey.shade200,
                                    width: sel ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      sel
                                          ? Icons.check_circle
                                          : Icons.circle_outlined,
                                      color: sel
                                          ? AppTheme.primary
                                          : AppTheme.muted,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            a['nom'] ?? '',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: sel
                                                  ? AppTheme.primary
                                                  : AppTheme.dark,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${a['duree'] ?? ''} · ${a['prix'] == 0 ? 'Gratuit' : '${a['prix']}€'}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.muted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: Text(
                                        a['categorie'] ?? '',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                    if (_activites.isNotEmpty) const SizedBox(height: 16),

                    // ── Dates
                    _buildCard(
                      title: '📅 Dates du voyage',
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _pickDate(isDebut: true),
                                  child: _buildDateBox(
                                    label: 'Départ',
                                    date: _formatDate(_dateDebut),
                                    icon: Icons.flight_takeoff,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _pickDate(isDebut: false),
                                  child: _buildDateBox(
                                    label: 'Retour',
                                    date: _formatDate(_dateFin),
                                    icon: Icons.flight_land,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_nombreJours() > 0) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    color: AppTheme.primary,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_nombreJours()} jours de voyage',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Budget
                    _buildCard(
                      title: '💰 Budget estimé (€)',
                      child: TextFormField(
                        controller: _budgetController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: AppTheme.dark),
                        decoration: InputDecoration(
                          hintText: 'Ex: 1500',
                          hintStyle: TextStyle(
                            color: AppTheme.muted.withValues(alpha: 0.6),
                          ),
                          prefixIcon: const Icon(
                            Icons.euro,
                            color: AppTheme.primary,
                          ),
                          suffixText: '€',
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Notes
                    _buildCard(
                      title: '📌 Notes & remarques',
                      child: TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        style: const TextStyle(color: AppTheme.dark),
                        decoration: InputDecoration(
                          hintText:
                              'Ajoutez vos notes, idées, choses à ne pas oublier...',
                          hintStyle: TextStyle(
                            color: AppTheme.muted.withValues(alpha: 0.6),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Bouton créer
                    ElevatedButton(
                      onPressed: _loading ? null : _createVoyage,
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              '✈️ Créer mon voyage',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.dark,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildDateBox({
    required String label,
    required String date,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            date,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: date == 'Sélectionner' ? AppTheme.muted : AppTheme.dark,
            ),
          ),
        ],
      ),
    );
  }
}
