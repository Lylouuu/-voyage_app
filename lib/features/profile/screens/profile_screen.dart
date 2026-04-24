import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voyage_app/core/theme/app_theme.dart';
import 'package:voyage_app/features/onboarding/screens/onboarding_screen.dart';
import 'package:voyage_app/features/recommandations/screens/recommandations_screen.dart';
import 'package:voyage_app/features/search/screens/search_screen.dart';
import 'package:voyage_app/features/voyage/screens/mes_voyages_screen.dart';
import 'package:voyage_app/features/auth/screens/auth_screen.dart';
import 'package:voyage_app/features/favoris/screens/favoris_screen.dart';
import 'package:voyage_app/main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _prefs;
  bool _loading = true;
  int _countVoyages = 0;
  int _countFavoris = 0;
  int _countAvis = 0;

  // Settings state
  String _selectedLang = 'Français';

  @override
  void initState() {
    super.initState();
    _loadLocalSettings();
    _loadData();
  }

  Future<void> _loadLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _selectedLang = prefs.getString('selectedLang') ?? 'Français';
      });
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is String) await prefs.setString(key, value);
  }

  Future<void> _loadData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    Map<String, dynamic>? userData;
    Map<String, dynamic>? prefs;

    try {
      final userRows = await _supabase
          .from('utilisateurs')
          .select()
          .eq('id', user.id)
          .limit(1);
      userData = userRows.isNotEmpty ? userRows.first : null;
    } catch (e) {
      debugPrint('[Profile] ERREUR utilisateurs: $e');
    }

    try {
      final prefsRows = await _supabase
          .from('preferences')
          .select()
          .eq('id_user', user.id)
          .limit(1);
      prefs = prefsRows.isNotEmpty ? prefsRows.first : null;
    } catch (e) {
      debugPrint('[Profile] ERREUR preferences: $e');
    }

    try {
      final resVoyages = await _supabase.from('plans_voyage').select('id').eq('id_user', user.id);
      final resFavoris = await _supabase.from('favoris').select('id_user').eq('id_user', user.id);
      final resAvis = await _supabase.from('avis').select('id').eq('id_user', user.id);

      if (mounted) {
        setState(() {
          _countVoyages = resVoyages.length;
          _countFavoris = resFavoris.length;
          _countAvis = resAvis.length;
        });
      }
    } catch (e) {
      debugPrint('[Profile] ERREUR stats: $e');
    }

    if (mounted) {
      setState(() {
        _user = userData;
        _prefs = prefs;
        _loading = false;
      });
    }
  }

  Future<void> _signOut() async {
    await _supabase.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (route) => false,
      );
    }
  }

  String _getUserInitial() {
    final nom = _user?['nom'] ?? 'C';
    if (nom.isNotEmpty) {
      return nom[0].toUpperCase();
    }
    return 'C';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkNavy,
      bottomNavigationBar: _buildBottomNav(),
      body: Stack(
        children: [
          // Background Gradient (Soft and dark)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0F1B2D),
                  Color(0xFF0A1628),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.limeGreen),
                  )
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSimpleHeader(),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPreferencesSection(),
                              const SizedBox(height: 32),
                              _buildSettingsSection(),
                              const SizedBox(height: 32),
                              _buildLogoutButton(),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HEADER (SIMPLE + PREMIUM)
  // ─────────────────────────────────────────────
  Widget _buildSimpleHeader() {
    final initial = _getUserInitial();
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white.withOpacity(0.9), size: 18),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Avatar: Circle, soft neon background, subtle shadow
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.limeGreen, Color(0xFF6EDC7B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F1B2D),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _user?['nom'] ?? 'Voyageur',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _user?['email'] ?? 'email@introuvable.com',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 28),
          
          // Ultra Clean Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCleanStat('$_countVoyages', 'Voyages'),
              _buildCleanStat('$_countFavoris', 'Favoris'),
              _buildCleanStat('$_countAvis', 'Avis'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCleanStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // PREFERENCES SECTION
  // ─────────────────────────────────────────────
  Widget _buildPreferencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mes préférences',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF162544),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              _buildPrefRow('💰', 'Budget', _prefs?['budget'] ?? 'Non défini'),
              _buildDivider(),
              _buildPrefRow('👥', 'Type de voyage', _prefs?['type_voyage'] ?? 'Non défini'),
              _buildDivider(),
              _buildPrefRow('📅', 'Durée de séjour', _prefs?['duree_sejour'] ?? 'Non défini'),
              
              if (_prefs?['centres_interet'] != null) ...[
                _buildDivider(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Centres d\'intérêt',
                        style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6)),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (_prefs!['centres_interet'] as List)
                            .map(
                              (i) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.limeGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  i.toString(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.limeGreen,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Modifier préférences Button (Clean, no glow)
        _InteractiveButton(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const OnboardingScreen(isEditing: true),
              ),
            ).then((_) => _loadData());
          },
          label: 'Modifier mes préférences',
        ),
      ],
    );
  }

  Widget _buildPrefRow(String icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 14),
          Text(
            label,
            style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.limeGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white.withOpacity(0.05),
    );
  }

  // ─────────────────────────────────────────────
  // SETTINGS SECTION
  // ─────────────────────────────────────────────
  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Paramètres',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _InteractiveSettingCard(
          icon: Icons.favorite_rounded,
          label: 'Mes Favoris',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavorisScreen()),
            ).then((_) => _loadData());
          },
        ),
        const SizedBox(height: 10),
        _InteractiveSettingCard(icon: Icons.language_rounded, label: 'Langue & Région', onTap: _showLanguageFilters),
        const SizedBox(height: 10),
        _InteractiveSettingCard(icon: Icons.help_outline_rounded, label: 'Aide & Support', onTap: _showHelpBottomSheet),
      ],
    );
  }

  void _showLanguageFilters() {
    final languages = ['Français', 'English', 'Español', 'العربية'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF162544),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Langue', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                Column(
                  children: languages.map((lang) {
                    final isSelected = _selectedLang == lang;
                    return GestureDetector(
                      onTap: () {
                        setModalState(() => _selectedLang = lang);
                        setState(() => _selectedLang = lang);
                        _saveSetting('selectedLang', lang);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        color: Colors.transparent,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(lang, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                            if (isSelected) const Icon(Icons.check_circle_rounded, color: AppTheme.limeGreen),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showHelpBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF162544),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Aide & Support', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 24),
            _buildHelpRow(Icons.question_answer_rounded, 'Foire aux questions (FAQ)'),
            const SizedBox(height: 20),
            _buildHelpRow(Icons.email_rounded, 'Nous contacter'),
            const SizedBox(height: 20),
            _buildHelpRow(Icons.description_rounded, 'Conditions d\'utilisation'),
            const SizedBox(height: 32),
            Center(child: Text('Version 1.0.0', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12))),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.7), size: 22),
        const SizedBox(width: 16),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
        const Spacer(),
        Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.3), size: 20),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8, top: 12),
          child: Text(
            'Sécurité',
            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.w600),
          ),
        ),
        _InteractiveSettingCard(
          icon: Icons.logout_rounded,
          label: 'Déconnexion',
          onTap: _signOut,
          isDanger: true,
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // BOTTOM NAVIGATION BAR
  // ─────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 8, top: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(index: 0, icon: Icons.home_rounded, activeIcon: Icons.home_rounded, label: 'Home'),
          _buildNavItem(index: 1, icon: Icons.explore_outlined, activeIcon: Icons.explore, label: 'Explorer'),
          _buildNavAIButton(),
          _buildNavItem(index: 3, icon: Icons.luggage_outlined, activeIcon: Icons.luggage, label: 'Mes Voyages'),
          _buildNavItem(index: 4, icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildNavItem({required int index, required IconData icon, required IconData activeIcon, required String label}) {
    final isActive = 4 == index;
    return GestureDetector(
      onTap: () {
        if (isActive) return;
        if (index == 0) {
          Navigator.pop(context);
        } else if (index == 1) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
        } else if (index == 3) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MesVoyagesScreen()));
        }
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.limeGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive ? const Color(0xFF0F1B2D) : Colors.white.withOpacity(0.4),
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.limeGreen : Colors.white.withOpacity(0.35),
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavAIButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const RecommandationsScreen()));
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7C3AED), Color(0xFF9F5AFF), Color(0xFFB47AFF)],
          ),
          boxShadow: [
            BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: const Center(
          child: Icon(Icons.auto_awesome, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// INTERACTIVE WIDGETS
// ─────────────────────────────────────────────

class _InteractiveSettingCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDanger;

  const _InteractiveSettingCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  State<_InteractiveSettingCard> createState() => _InteractiveSettingCardState();
}

class _InteractiveSettingCardState extends State<_InteractiveSettingCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isDanger ? Colors.redAccent : Colors.white;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF162544),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isPressed ? Colors.white.withOpacity(0.1) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: color.withOpacity(0.8), size: 22),
              const SizedBox(width: 16),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 16,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.3), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractiveButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _InteractiveButton({required this.label, required this.onTap});

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
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.limeGreen.withOpacity(0.9), // Soft green, no heavy glow
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: const TextStyle(
                color: Color(0xFF0F1B2D),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
