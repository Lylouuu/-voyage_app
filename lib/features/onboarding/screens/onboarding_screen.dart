import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voyage_app/core/theme/app_theme.dart';
import 'package:voyage_app/features/home/screens/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _supabase = Supabase.instance.client;
  final _pageController = PageController();

  int _currentPage = 0;
  bool _loading = false;

  // Préférences sélectionnées
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

  bool get _canNext {
    switch (_currentPage) {
      case 0:
        return _budget.isNotEmpty;
      case 1:
        return _typeVoyage.isNotEmpty;
      case 2:
        return _dureeSejour.isNotEmpty;
      case 3:
        return _centresInteret.isNotEmpty;
      default:
        return false;
    }
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _savePreferences();
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _loading = true);
    try {
      final user = _supabase.auth.currentUser!;

      // Sauvegarder dans la table preferences
      await _supabase.from('preferences').upsert({
        'id_user': user.id,
        'budget': _budget,
        'type_voyage': _typeVoyage,
        'duree_sejour': _dureeSejour,
        'centres_interet': _centresInteret,
      });

      // Mettre à jour la table utilisateurs
      await _supabase
          .from('utilisateurs')
          .update({
            'budget': _budget,
            'type_voyage': _typeVoyage,
            'duree_sejour': _dureeSejour,
          })
          .eq('id', user.id);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppTheme.secondary,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Barre de progression
            _buildProgressBar(),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildBudgetPage(),
                  _buildTypePage(),
                  _buildDureePage(),
                  _buildInteretsPage(),
                ],
              ),
            ),

            // Bouton suivant
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  // ── PROGRESS BAR ─────────────────────────────────────────────
  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        children: [
          Row(
            children: List.generate(4, (i) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= _currentPage
                        ? AppTheme.primary
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            'Étape ${_currentPage + 1} sur 4',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── PAGE BUDGET ───────────────────────────────────────────────
  Widget _buildBudgetPage() {
    return _buildPage(
      title: 'Quel est votre\nbudget de voyage ?',
      subtitle: 'Nous adapterons nos recommandations',
      child: Column(
        children: _budgets.map((b) {
          final selected = _budget == b['label'];
          return _buildOptionCard(
            emoji: b['emoji']!,
            label: b['label']!,
            sub: b['sub'],
            selected: selected,
            color: AppTheme.coral,
            onTap: () => setState(() => _budget = b['label']!),
          );
        }).toList(),
      ),
    );
  }

  // ── PAGE TYPE VOYAGE ──────────────────────────────────────────
  Widget _buildTypePage() {
    return _buildPage(
      title: 'Vous voyagez\nplutôt comment ?',
      subtitle: 'Choisissez votre style de voyage',
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
        children: _types.map((t) {
          final selected = _typeVoyage == t['label'];
          return GestureDetector(
            onTap: () => setState(() => _typeVoyage = t['label']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: selected ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? AppTheme.primary : Colors.grey.shade200,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: selected
                        ? AppTheme.primary.withOpacity(0.3)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(t['emoji']!, style: const TextStyle(fontSize: 32)),
                  const SizedBox(height: 8),
                  Text(
                    t['label']!,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppTheme.dark,
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

  // ── PAGE DUREE ────────────────────────────────────────────────
  Widget _buildDureePage() {
    return _buildPage(
      title: 'Quelle durée\nde séjour préférez-vous ?',
      subtitle: 'Pour mieux planifier vos voyages',
      child: Column(
        children: _durees.map((d) {
          final selected = _dureeSejour == d['label'];
          return _buildOptionCard(
            emoji: d['emoji']!,
            label: d['label']!,
            sub: d['sub'],
            selected: selected,
            color: const Color(0xFF7C3AED),
            onTap: () => setState(() => _dureeSejour = d['label']!),
          );
        }).toList(),
      ),
    );
  }

  // ── PAGE INTERETS ─────────────────────────────────────────────
  Widget _buildInteretsPage() {
    return _buildPage(
      title: 'Quels sont vos\ncentres d\'intérêt ?',
      subtitle: 'Sélectionnez tout ce qui vous attire',
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: selected ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: selected ? AppTheme.primary : Colors.grey.shade200,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: selected
                        ? AppTheme.primary.withOpacity(0.3)
                        : Colors.black.withOpacity(0.04),
                    blurRadius: 8,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppTheme.dark,
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

  // ── TEMPLATE PAGE ─────────────────────────────────────────────
  Widget _buildPage({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.dark,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(fontSize: 15, color: AppTheme.muted)),
          const SizedBox(height: 28),
          child,
        ],
      ),
    );
  }

  // ── OPTION CARD ───────────────────────────────────────────────
  Widget _buildOptionCard({
    required String emoji,
    required String label,
    String? sub,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? color : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? color.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppTheme.dark,
                  ),
                ),
                if (sub != null)
                  Text(
                    sub,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected ? Colors.white70 : AppTheme.muted,
                    ),
                  ),
              ],
            ),
            const Spacer(),
            if (selected)
              const Icon(Icons.check_circle, color: Colors.white, size: 22),
          ],
        ),
      ),
    );
  }

  // ── BOUTON BAS ────────────────────────────────────────────────
  Widget _buildBottomButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        children: [
          if (_currentPage > 0)
            TextButton(
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Text(
                '← Retour',
                style: TextStyle(color: AppTheme.muted, fontSize: 14),
              ),
            ),
          ElevatedButton(
            onPressed: _canNext ? _nextPage : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              disabledBackgroundColor: Colors.grey.shade200,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    _currentPage < 3
                        ? 'Continuer →'
                        : '🌴 Commencer l\'aventure !',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
