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

  DateTime? _dateDebut;
  DateTime? _dateFin;
  bool _loading = false;
  List<Map<String, dynamic>> _villes = [];
  String? _selectedVilleId;
  String? _selectedVilleNom;

  @override
  void initState() {
    super.initState();
    _loadVilles();
  }

  @override
  void dispose() {
    _titreController.dispose();
    super.dispose();
  }

  Future<void> _loadVilles() async {
    final villes = await _supabase
        .from('villes')
        .select('id, nom, pays(nom)')
        .order('nom');
    if (mounted) {
      setState(() {
        _villes = List<Map<String, dynamic>>.from(villes);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner les dates'),
          backgroundColor: AppTheme.coral,
        ),
      );
      return;
    }
    if (_selectedVilleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une destination'),
          backgroundColor: AppTheme.coral,
        ),
      );
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
            'budget_total': 0,
          })
          .select()
          .single();

      // Ajouter la ville au plan
      await _supabase.from('plan_villes').insert({
        'id_plan': voyage['id'],
        'id_ville': _selectedVilleId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Voyage créé avec succès !'),
            backgroundColor: AppTheme.primary,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppTheme.coral,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
          // Header
          SliverAppBar(
            expandedHeight: 160,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📝 Nom du voyage',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.dark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _titreController,
                            style: const TextStyle(color: AppTheme.dark),
                            decoration: InputDecoration(
                              hintText: 'Ex: Vacances été 2025 à Bali',
                              hintStyle: TextStyle(
                                color: AppTheme.muted.withOpacity(0.6),
                              ),
                              prefixIcon: const Icon(
                                Icons.edit_outlined,
                                color: AppTheme.primary,
                              ),
                            ),
                            validator: (v) => v!.isEmpty ? 'Nom requis' : null,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Destination
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🌍 Destination',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.dark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedVilleId,
                            decoration: InputDecoration(
                              hintText: 'Choisir une ville',
                              hintStyle: TextStyle(
                                color: AppTheme.muted.withOpacity(0.6),
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
                              setState(() {
                                _selectedVilleId = val;
                                _selectedVilleNom = _villes.firstWhere(
                                  (v) => v['id'].toString() == val,
                                )['nom'];
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Dates
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📅 Dates du voyage',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.dark,
                            ),
                          ),
                          const SizedBox(height: 12),
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
                                color: AppTheme.primary.withOpacity(0.1),
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
                                    style: TextStyle(
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

                    const SizedBox(height: 32),

                    // Bouton créer
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

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
        ],
      ),
      child: child,
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
