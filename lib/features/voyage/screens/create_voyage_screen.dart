import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voyage_app/core/theme/app_theme.dart';

class CreateVoyageScreen extends StatefulWidget {
  final String? initialVilleId;
  const CreateVoyageScreen({super.key, this.initialVilleId});

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
    if (widget.initialVilleId != null) {
      _selectedVilleId = widget.initialVilleId;
      _loadActivites(widget.initialVilleId!);
    }
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
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.limeGreen,
              onPrimary: Color(0xFF0F1B2D),
              surface: Color(0xFF162544),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF162544),
          ),
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
      _showSnack('Veuillez sélectionner les dates', Colors.redAccent);
      return;
    }
    if (_selectedVilleId == null) {
      _showSnack('Veuillez sélectionner une destination', Colors.redAccent);
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
        _showSnack('✅ Voyage créé avec succès !', AppTheme.limeGreen);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) _showSnack('Erreur : $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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

  String _formatDate(DateTime? date) {
    if (date == null) return 'Sélectionner';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  int _nombreJours() {
    if (_dateDebut == null || _dateFin == null) return 0;
    return _dateFin!.difference(_dateDebut!).inDays;
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
                colors: [Color(0xFF0F1B2D), Color(0xFF0A1628)],
              ),
            ),
          ),
          
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildHeader(),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildPremiumCard(
                            title: '📝 Nom du voyage',
                            child: _PremiumTextField(
                              controller: _titreController,
                              hintText: 'Ex: Vacances été 2025 à Bali',
                              icon: Icons.edit_outlined,
                              validator: (v) => v!.isEmpty ? 'Nom requis' : null,
                            ),
                          ),
                          const SizedBox(height: 24),

                          _buildPremiumCard(
                            title: '👥 Type de voyage',
                            child: _buildTravelTypeSelector(),
                          ),
                          const SizedBox(height: 24),

                          _buildPremiumCard(
                            title: '🌍 Destination',
                            child: _buildDestinationDropdown(),
                          ),
                          const SizedBox(height: 24),

                          if (_activites.isNotEmpty) ...[
                            _buildPremiumCard(
                              title: '🎯 Activités souhaitées',
                              child: _buildActivitiesList(),
                            ),
                            const SizedBox(height: 24),
                          ],

                          _buildPremiumCard(
                            title: '📅 Dates du voyage',
                            child: _buildDatesCard(),
                          ),
                          const SizedBox(height: 24),

                          _buildPremiumCard(
                            title: '💰 Budget estimé',
                            child: _PremiumTextField(
                              controller: _budgetController,
                              hintText: 'Ex: 1500',
                              icon: Icons.euro_rounded,
                              keyboardType: TextInputType.number,
                              suffixText: '€',
                            ),
                          ),
                          const SizedBox(height: 24),

                          _buildPremiumCard(
                            title: '📌 Notes & Remarques',
                            child: _PremiumTextField(
                              controller: _notesController,
                              hintText: 'Ajoutez vos notes, idées...',
                              icon: Icons.notes_rounded,
                              maxLines: 3,
                            ),
                          ),
                          
                          const SizedBox(height: 120), // Bottom padding for CTA
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // BOTTOM CTA BUTTON (Floating)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).padding.bottom + 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppTheme.darkNavy,
                    AppTheme.darkNavy.withOpacity(0.9),
                    Colors.transparent,
                  ],
                  stops: const [0.3, 0.7, 1.0],
                ),
              ),
              child: _InteractiveButton(
                loading: _loading,
                label: 'Créer mon voyage',
                onTap: _loading ? () {} : _createVoyage,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────
  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Créer un voyage',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Planifiez votre prochaine aventure',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // PREMIUM SECTION CARDS
  // ─────────────────────────────────────────────
  Widget _buildPremiumCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF162544),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SPECIFIC UI FORMS
  // ─────────────────────────────────────────────
  Widget _buildTravelTypeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _types.map((t) {
        final sel = _selectedType == t['label'];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedType = t['label']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: sel ? AppTheme.limeGreen.withOpacity(0.15) : Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: sel ? AppTheme.limeGreen : Colors.transparent),
              ),
              child: Column(
                children: [
                  Text(t['emoji']!, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 6),
                  Text(
                    t['label']!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: sel ? FontWeight.bold : FontWeight.w600,
                      color: sel ? AppTheme.limeGreen : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDestinationDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedVilleId,
      dropdownColor: const Color(0xFF162544),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.limeGreen),
      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
      // Muted background to match text fields
      decoration: InputDecoration(
        hintText: 'Choisir une ville',
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        prefixIcon: const Icon(Icons.location_on_outlined, color: AppTheme.limeGreen),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      items: _villes.map((v) {
        return DropdownMenuItem<String>(
          value: v['id'].toString(),
          child: Text(
            '${v['nom']} — ${v['pays']?['nom'] ?? ''}',
            style: const TextStyle(fontSize: 15),
          ),
        );
      }).toList(),
      onChanged: (val) {
        setState(() => _selectedVilleId = val);
        if (val != null) _loadActivites(val);
      },
    );
  }

  Widget _buildActivitiesList() {
    return Column(
      children: _activites.map((a) {
        final sel = _selectedActivites.contains(a['id'].toString());
        return GestureDetector(
          onTap: () {
            setState(() {
              if (sel) {
                _selectedActivites.remove(a['id'].toString());
              } else {
                _selectedActivites.add(a['id'].toString());
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: sel ? AppTheme.limeGreen.withOpacity(0.1) : Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: sel ? AppTheme.limeGreen.withOpacity(0.5) : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  sel ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: sel ? AppTheme.limeGreen : Colors.white.withOpacity(0.3),
                  size: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a['nom'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: sel ? FontWeight.bold : FontWeight.w600,
                          color: sel ? Colors.white : Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${a['duree'] ?? ''} · ${a['prix'] == 0 ? 'Gratuit' : '${a['prix']}€'}',
                        style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDatesCard() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _pickDate(isDebut: true),
                child: _buildDateBox(
                  label: 'DÉPART',
                  date: _formatDate(_dateDebut),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => _pickDate(isDebut: false),
                child: _buildDateBox(
                  label: 'RETOUR',
                  date: _formatDate(_dateFin),
                ),
              ),
            ),
          ],
        ),
        if (_nombreJours() > 0) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.limeGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.flight_takeoff_rounded, color: AppTheme.limeGreen, size: 18),
                const SizedBox(width: 10),
                Text(
                  '${_nombreJours()} jours de voyage',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.limeGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDateBox({required String label, required String date}) {
    final bool isSelected = date != 'Sélectionner';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.5),
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            date,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PREMIUM TEXT FIELD COMPONENT
// ─────────────────────────────────────────────
class _PremiumTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final String? suffixText;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _PremiumTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.suffixText,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  State<_PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<_PremiumTextField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isFocused ? AppTheme.limeGreen : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: _isFocused
              ? [BoxShadow(color: AppTheme.limeGreen.withOpacity(0.15), blurRadius: 10)]
              : [],
        ),
        child: TextFormField(
          controller: widget.controller,
          maxLines: widget.maxLines,
          keyboardType: widget.keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            filled: false, // Prevents global theme from painting it white
            hintText: widget.hintText,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontWeight: FontWeight.normal),
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Icon(widget.icon, color: _isFocused ? AppTheme.limeGreen : Colors.white.withOpacity(0.5)),
            ),
            suffixText: widget.suffixText,
            suffixStyle: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            contentPadding: const EdgeInsets.all(16),
            border: InputBorder.none,
          ),
          validator: widget.validator,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// INTERACTIVE CTA BUTTON
// ─────────────────────────────────────────────
class _InteractiveButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool loading;

  const _InteractiveButton({required this.label, required this.onTap, this.loading = false});

  @override
  State<_InteractiveButton> createState() => _InteractiveButtonState();
}

class _InteractiveButtonState extends State<_InteractiveButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (!widget.loading) widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.limeGreen, Color(0xFF00C9B1)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.limeGreen.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: widget.loading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: Color(0xFF0F1B2D), strokeWidth: 3),
                  )
                : Text(
                    widget.label,
                    style: const TextStyle(
                      color: Color(0xFF0F1B2D),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
