import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voyage_app/core/theme/app_theme.dart';
import 'package:voyage_app/features/home/screens/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final bool isEditing;
  const OnboardingScreen({super.key, this.isEditing = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _supabase = Supabase.instance.client;
  bool _loading = false;

  // ── Preferences data ──────────────────────────────────────
  String _budget = '';
  String _typeVoyage = '';
  String _dureeSejour = '';
  final List<String> _centresInteret = [];

  final _budgets = [
    {'label': 'Économique', 'emoji': '🪙', 'sub': 'Moins de 800€'},
    {'label': 'Moyen', 'emoji': '💳', 'sub': '800€ - 2000€'},
    {'label': 'Élevé', 'emoji': '💎', 'sub': 'Plus de 2000€'},
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
    {'label': 'Long', 'emoji': '🌍', 'sub': 'Plus d\'une semaine'},
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
          _budget = prefs['budget'] ?? '';
          _typeVoyage = prefs['type_voyage'] ?? '';
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
            'budget': _budget,
            'type_voyage': _typeVoyage,
            'duree_sejour': _dureeSejour,
          })
          .eq('id', user.id);

      if (mounted) {
        if (widget.isEditing) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
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

  // ── UI BUILD ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkNavy,
      body: Stack(
        children: [
          // ── Ambient background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0F1B2D), Color(0xFF0A1628)],
              ),
            ),
          ),

          // ── Content
          SafeArea(
            child: Column(
              children: [
                // ── Header
                _buildHeader(),

                // ── Scrollable sections
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                    child: Column(
                      children: [
                        _buildBudgetSection(),
                        const SizedBox(height: 24),
                        _buildTypeSection(),
                        const SizedBox(height: 24),
                        _buildDureeSection(),
                        const SizedBox(height: 24),
                        _buildInteretsSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Floating CTA
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

  // ── HEADER ──────────────────────────────────────────────────
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
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              ),
            ),
          if (widget.isEditing) const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isEditing ? 'Mes Préférences' : 'Bienvenue ! ✈️',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.isEditing
                      ? 'Personnalisez votre expérience de voyage'
                      : 'Dites-nous ce que vous aimez',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── SECTION WRAPPER ───────────────────────────────────────
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color accentColor,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section title row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.15),
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
                      color: Colors.white,
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

  // ── BUDGET SECTION ────────────────────────────────────────
  Widget _buildBudgetSection() {
    return _buildSectionCard(
      title: 'Budget',
      icon: Icons.account_balance_wallet_rounded,
      accentColor: const Color(0xFFFFD97D),
      child: Column(
        children: _budgets.asMap().entries.map((entry) {
          final b = entry.value;
          final selected = _budget == b['label'];
          return Padding(
            padding: EdgeInsets.only(bottom: entry.key < _budgets.length - 1 ? 10 : 0),
            child: _PremiumOptionTile(
              emoji: b['emoji']!,
              label: b['label']!,
              subtitle: b['sub'],
              selected: selected,
              accentColor: const Color(0xFFFFD97D),
              onTap: () => setState(() => _budget = b['label']!),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── TYPE SECTION ──────────────────────────────────────────
  Widget _buildTypeSection() {
    return _buildSectionCard(
      title: 'Type de voyage',
      icon: Icons.flight_takeoff_rounded,
      accentColor: const Color(0xFF00E5FF),
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
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF00E5FF).withOpacity(0.15)
                    : Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF00E5FF).withOpacity(0.6)
                      : Colors.white.withOpacity(0.05),
                  width: 1.5,
                ),
                boxShadow: selected
                    ? [BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.15), blurRadius: 12)]
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
                      color: selected ? const Color(0xFF00E5FF) : Colors.white.withOpacity(0.7),
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

  // ── DURATION SECTION ──────────────────────────────────────
  Widget _buildDureeSection() {
    return _buildSectionCard(
      title: 'Durée de séjour',
      icon: Icons.schedule_rounded,
      accentColor: const Color(0xFF9080FF),
      child: Column(
        children: _durees.asMap().entries.map((entry) {
          final d = entry.value;
          final selected = _dureeSejour == d['label'];
          return Padding(
            padding: EdgeInsets.only(bottom: entry.key < _durees.length - 1 ? 10 : 0),
            child: _PremiumOptionTile(
              emoji: d['emoji']!,
              label: d['label']!,
              subtitle: d['sub'],
              selected: selected,
              accentColor: const Color(0xFF9080FF),
              onTap: () => setState(() => _dureeSejour = d['label']!),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── INTERESTS SECTION ─────────────────────────────────────
  Widget _buildInteretsSection() {
    return _buildSectionCard(
      title: 'Centres d\'intérêt',
      icon: Icons.interests_rounded,
      accentColor: AppTheme.limeGreen,
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
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.limeGreen.withOpacity(0.15)
                    : Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: selected
                      ? AppTheme.limeGreen.withOpacity(0.6)
                      : Colors.white.withOpacity(0.06),
                  width: 1.5,
                ),
                boxShadow: selected
                    ? [BoxShadow(color: AppTheme.limeGreen.withOpacity(0.1), blurRadius: 10)]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(i['emoji']!, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    i['label']!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected ? AppTheme.limeGreen : Colors.white.withOpacity(0.7),
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.check_rounded, size: 16, color: AppTheme.limeGreen),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── FLOATING CTA ──────────────────────────────────────────
  Widget _buildFloatingCTA() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.darkNavy.withOpacity(0.0),
            AppTheme.darkNavy.withOpacity(0.95),
            AppTheme.darkNavy,
          ],
          stops: const [0.0, 0.3, 1.0],
        ),
      ),
      child: GestureDetector(
        onTap: _canSave ? _savePreferences : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            gradient: _canSave
                ? const LinearGradient(colors: [Color(0xFF00C9B1), Color(0xFF00E5FF)])
                : null,
            color: _canSave ? null : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(18),
            boxShadow: _canSave
                ? [BoxShadow(color: const Color(0xFF00C9B1).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 4))]
                : [],
          ),
          child: Center(
            child: _loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(
                    widget.isEditing ? 'Enregistrer mes préférences' : '🌴  Commencer l\'aventure !',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _canSave ? const Color(0xFF0F1B2D) : Colors.white.withOpacity(0.3),
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// PREMIUM OPTION TILE (Budget / Duration rows)
// ─────────────────────────────────────────────────
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
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? accentColor.withOpacity(0.12)
              : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? accentColor.withOpacity(0.5)
                : Colors.white.withOpacity(0.04),
            width: 1.5,
          ),
          boxShadow: selected
              ? [BoxShadow(color: accentColor.withOpacity(0.1), blurRadius: 12)]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected
                    ? accentColor.withOpacity(0.2)
                    : Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: selected ? accentColor : Colors.white.withOpacity(0.9),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: selected ? accentColor.withOpacity(0.7) : Colors.white.withOpacity(0.4),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: selected
                  ? Icon(Icons.check_circle_rounded, color: accentColor, size: 22, key: const ValueKey('check'))
                  : Container(
                      key: const ValueKey('circle'),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
