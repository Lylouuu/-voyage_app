import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voyage_app/core/theme/app_theme.dart';
import 'package:voyage_app/main.dart';

class OnboardingScreen extends StatefulWidget {
  final bool isEditing;
  const OnboardingScreen({super.key, this.isEditing = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _supabase = Supabase.instance.client;
  bool _loading = false;

  // ── Données de préférences ─────────────────────────────────
  String _budget = '';
  String _typeVoyage = '';
  String _dureeSejour = '';
  final List<String> _centresInteret = [];

  final _budgets = [
    {'label': 'Économique', 'emoji': '🪙', 'sub': 'Moins de 800 €'},
    {'label': 'Moyen', 'emoji': '💳', 'sub': '800 € – 2 000 €'},
    {'label': 'Élevé', 'emoji': '💎', 'sub': 'Plus de 2 000 €'},
  ];

  final _types = [
    {'label': 'Solo', 'emoji': '🧳'},
    {'label': 'Couple', 'emoji': '💑'},
    {'label': 'Famille', 'emoji': '👨‍👩‍👧'},
    {'label': 'Groupe', 'emoji': '👥'},
  ];

  final _durees = [
    {'label': 'Court', 'emoji': '⚡', 'sub': '1 à 3 jours'},
    {'label': 'Moyen', 'emoji': '🗓️', 'sub': '4 à 7 jours'},
    {'label': 'Long', 'emoji': '🌍', 'sub': "Plus d'une semaine"},
  ];

  final _interets = [
    {'label': 'Culture', 'emoji': '🏛️'},
    {'label': 'Nature', 'emoji': '🌿'},
    {'label': 'Gastronomie', 'emoji': '🍜'},
    {'label': 'Shopping', 'emoji': '🛍️'},
    {'label': 'Sport', 'emoji': '🏄'},
    {'label': 'Aventure', 'emoji': '🧗'},
    {'label': 'Détente', 'emoji': '🧘'},
    {'label': 'Romantique', 'emoji': '💑'},
  ];

  // ── Couleurs d'accent par section (palette bleu ciel) ──────
  static const Color _accentBudget  = Color(0xFF4DB6E8); // Bleu ciel vif
  static const Color _accentType    = Color(0xFF00B4D8); // Cyan azur
  static const Color _accentDuree   = Color(0xFF7EC8E3); // Bleu ciel doux
  static const Color _accentInteret = Color(0xFF4DB6E8); // Bleu ciel vif

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) _loadExistingPrefs();
  }

  Future<void> _loadExistingPrefs() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      final rows = await _supabase
          .from('preferences')
          .select()
          .eq('id_user', user.id)
          .limit(1);
      final prefs = rows.isNotEmpty ? rows.first : null;
      if (prefs != null && mounted) {
        setState(() {
          _budget      = prefs['budget']       ?? '';
          _typeVoyage  = prefs['type_voyage']  ?? '';
          _dureeSejour = prefs['duree_sejour'] ?? '';
          final ci = prefs['centres_interet'];
          if (ci is List) {
            _centresInteret
              ..clear()
              ..addAll(ci.map((e) => e.toString()));
          }
        });
      }
    } catch (e) {
      debugPrint('[Onboarding] ERREUR chargement prefs: $e');
    }
  }

  bool get _canSave =>
      _budget.isNotEmpty &&
      _typeVoyage.isNotEmpty &&
      _dureeSejour.isNotEmpty &&
      _centresInteret.isNotEmpty;

  Future<void> _savePreferences() async {
    setState(() => _loading = true);
    try {
      final user = _supabase.auth.currentUser!;

      final existingRows = await _supabase
          .from('preferences')
          .select('id_user')
          .eq('id_user', user.id)
          .limit(1);
      final existing = existingRows.isNotEmpty ? existingRows.first : null;
      final prefsData = {
        'budget': _budget,
        'type_voyage': _typeVoyage,
        'duree_sejour': _dureeSejour,
        'centres_interet': _centresInteret,
      };
      if (existing != null) {
        await _supabase
            .from('preferences')
            .update(prefsData)
            .eq('id_user', user.id);
      } else {
        await _supabase
            .from('preferences')
            .insert({'id_user': user.id, ...prefsData});
      }

      await _supabase
          .from('utilisateurs')
          .update({
            'budget':       _budget,
            'type_voyage':  _typeVoyage,
            'duree_sejour': _dureeSejour,
          })
          .eq('id', user.id);

      if (mounted) {
        if (widget.isEditing) {
          Navigator.pop(context);
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AuthWrapper()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── UI BUILD ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FF),
      body: Stack(
        children: [
          // ── Dégradé d'ambiance Light Premium
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF4F9FF), // Bleu ciel très clair
                  Color(0xFFEBF5FB), // Un peu plus dense
                ],
              ),
            ),
          ),

          // ── Contenu principal
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                    child: Column(
                      children: [
                        _buildBudgetSection(),
                        const SizedBox(height: 20),
                        _buildTypeSection(),
                        const SizedBox(height: 20),
                        _buildDureeSection(),
                        const SizedBox(height: 20),
                        _buildInteretsSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bouton flottant CTA
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildFloatingCTA(),
          ),
        ],
      ),
    );
  }

  // ── EN-TÊTE ────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Row(
        children: [
          if (widget.isEditing)
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF4A6580),
                  size: 18,
                ),
              ),
            ),
          if (widget.isEditing) const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.isEditing ? 'Mes Préférences' : 'Bienvenue ! ✈️',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0A192F),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.isEditing
                      ? 'Personnalisez votre expérience de voyage'
                      : 'Dites-nous ce que vous aimez',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4A6580),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── CARTE DE SECTION ──────────────────────────────────────
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color accentColor,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: accentColor.withOpacity(0.10),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: accentColor, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A192F),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              child,
            ],
          ),
        ),
      ),
    );
  }

  // ── SECTION BUDGET ────────────────────────────────────────
  Widget _buildBudgetSection() {
    return _buildSectionCard(
      title: 'Budget',
      icon: Icons.account_balance_wallet_rounded,
      accentColor: _accentBudget,
      child: Column(
        children: _budgets.asMap().entries.map((entry) {
          final b = entry.value;
          final selected = _budget == b['label'];
          return Padding(
            padding: EdgeInsets.only(
              bottom: entry.key < _budgets.length - 1 ? 10 : 0,
            ),
            child: _PremiumOptionTile(
              emoji: b['emoji']!,
              label: b['label']!,
              subtitle: b['sub'],
              selected: selected,
              accentColor: _accentBudget,
              onTap: () => setState(() => _budget = b['label']!),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── SECTION TYPE DE VOYAGE ────────────────────────────────
  Widget _buildTypeSection() {
    return _buildSectionCard(
      title: 'Type de voyage',
      icon: Icons.flight_takeoff_rounded,
      accentColor: _accentType,
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: _types.map((t) {
          final selected = _typeVoyage == t['label'];
          return GestureDetector(
            onTap: () => setState(() => _typeVoyage = t['label']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              decoration: BoxDecoration(
                color: selected
                    ? _accentType.withOpacity(0.14)
                    : Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected
                      ? _accentType.withOpacity(0.55)
                      : Colors.white.withOpacity(0.06),
                  width: 1.5,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: _accentType.withOpacity(0.18),
                          blurRadius: 14,
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(t['emoji']!, style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 8),
                  Text(
                    t['label']!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? _accentType
                          : Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── SECTION DURÉE ─────────────────────────────────────────
  Widget _buildDureeSection() {
    return _buildSectionCard(
      title: 'Durée de séjour',
      icon: Icons.schedule_rounded,
      accentColor: _accentDuree,
      child: Column(
        children: _durees.asMap().entries.map((entry) {
          final d = entry.value;
          final selected = _dureeSejour == d['label'];
          return Padding(
            padding: EdgeInsets.only(
              bottom: entry.key < _durees.length - 1 ? 10 : 0,
            ),
            child: _PremiumOptionTile(
              emoji: d['emoji']!,
              label: d['label']!,
              subtitle: d['sub'],
              selected: selected,
              accentColor: _accentDuree,
              onTap: () => setState(() => _dureeSejour = d['label']!),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── SECTION CENTRES D'INTÉRÊT ─────────────────────────────
  Widget _buildInteretsSection() {
    return _buildSectionCard(
      title: "Centres d'intérêt",
      icon: Icons.interests_rounded,
      accentColor: _accentInteret,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _interets.map((i) {
          final selected = _centresInteret.contains(i['label']);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (selected) {
                  _centresInteret.remove(i['label']);
                } else {
                  _centresInteret.add(i['label']!);
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? _accentInteret.withOpacity(0.14)
                    : Colors.white,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: selected
                      ? _accentInteret.withOpacity(0.55)
                      : const Color(0xFF4DB6E8).withOpacity(0.1),
                  width: 1.5,
                ),
                boxShadow: [
                  if (!selected)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  if (selected)
                    BoxShadow(
                      color: _accentInteret.withOpacity(0.12),
                      blurRadius: 10,
                    ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(i['emoji']!, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    i['label']!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? _accentInteret
                          : const Color(0xFF4A6580),
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.check_rounded,
                      size: 15,
                      color: _accentInteret,
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── BOUTON FLOTTANT CTA ───────────────────────────────────
  Widget _buildFloatingCTA() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFF4F9FF).withOpacity(0.0),
            const Color(0xFFF4F9FF).withOpacity(0.94),
            const Color(0xFFF4F9FF),
          ],
          stops: const [0.0, 0.28, 1.0],
        ),
      ),
      child: GestureDetector(
        onTap: _canSave ? _savePreferences : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            gradient: _canSave
                ? const LinearGradient(
                    colors: [Color(0xFF4DB6E8), Color(0xFF1A7EC8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: _canSave ? null : const Color(0xFFEBF5FB),
            borderRadius: BorderRadius.circular(18),
            boxShadow: _canSave
                ? [
                    BoxShadow(
                      color: const Color(0xFF4DB6E8).withOpacity(0.38),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: _loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.isEditing
                            ? 'Enregistrer mes préférences'
                            : '🌴  Commencer l\'aventure !',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _canSave
                              ? Colors.white
                              : const Color(0xFF4A6580).withOpacity(0.5),
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (_canSave) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// WIDGET : Tuile d'option premium (Budget / Durée)
// ─────────────────────────────────────────────────────────────
class _PremiumOptionTile extends StatelessWidget {
  final String emoji;
  final String label;
  final String? subtitle;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  const _PremiumOptionTile({
    required this.emoji,
    required this.label,
    this.subtitle,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? accentColor.withOpacity(0.11)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? accentColor.withOpacity(0.50)
                : const Color(0xFF4DB6E8).withOpacity(0.1),
            width: 1.5,
          ),
          boxShadow: [
            if (!selected)
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
            if (selected)
              BoxShadow(
                color: accentColor.withOpacity(0.12),
                blurRadius: 14,
              ),
          ],
        ),
        child: Row(
          children: [
            // Icône emoji
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected
                    ? accentColor.withOpacity(0.18)
                    : const Color(0xFFEBF5FB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 16),
            // Label + sous-titre
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: selected
                          ? accentColor
                          : const Color(0xFF0A192F),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: selected
                            ? accentColor.withOpacity(0.65)
                            : const Color(0xFF4A6580),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Indicateur sélectionné / non sélectionné
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: selected
                  ? Icon(
                      Icons.check_circle_rounded,
                      color: accentColor,
                      size: 22,
                      key: const ValueKey('check'),
                    )
                  : Container(
                      key: const ValueKey('circle'),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF4DB6E8).withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
