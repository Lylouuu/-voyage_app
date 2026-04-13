import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voyage_app/core/theme/app_theme.dart';
import 'package:voyage_app/features/admin/screens/admin_login_screen.dart';
import 'package:voyage_app/features/onboarding/screens/onboarding_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
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
      debugPrint('[Profile] utilisateurs: $userData');
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
      debugPrint('[Profile] preferences: $prefs');
    } catch (e) {
      debugPrint('[Profile] ERREUR preferences: $e');
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 56, 24, 32),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0093E9), Color(0xFF7C3AED)],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Bouton retour
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Avatar
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 2,
                            ),
                          ),
                          child: const Center(
                            child: Text('✈️', style: TextStyle(fontSize: 36)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _user?['nom'] ?? '',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _user?['email'] ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStat('0', 'Voyages'),
                            _buildStat('0', 'Favoris'),
                            _buildStat('0', 'Avis'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Préférences
                        _buildSection(
                          title: '🎯 Mes préférences',
                          child: Column(
                            children: [
                              _buildPrefRow(
                                '💰 Budget',
                                _prefs?['budget'] ?? 'Non défini',
                              ),
                              _buildPrefRow(
                                '👥 Type de voyage',
                                _prefs?['type_voyage'] ?? 'Non défini',
                              ),
                              _buildPrefRow(
                                '📅 Durée de séjour',
                                _prefs?['duree_sejour'] ?? 'Non défini',
                              ),
                              const SizedBox(height: 10),
                              // Centres d'intérêt
                              if (_prefs?['centres_interet'] != null) ...[
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '🌟 Centres d\'intérêt',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.muted,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: (_prefs!['centres_interet'] as List)
                                      .map(
                                        (i) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              50,
                                            ),
                                            border: Border.all(
                                              color: AppTheme.primary
                                                  .withOpacity(0.3),
                                            ),
                                          ),
                                          child: Text(
                                            i.toString(),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                              const SizedBox(height: 14),
                              // Modifier préférences
                              OutlinedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const OnboardingScreen(isEditing: true),
                                    ),
                                  ).then((_) => _loadData());
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primary,
                                  side: BorderSide(color: AppTheme.primary),
                                  minimumSize: const Size(double.infinity, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  '✏️ Modifier mes préférences',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Paramètres
                        _buildSection(
                          title: '⚙️ Paramètres',
                          child: Column(
                            children: [
                              _buildMenuItem('🔔', 'Notifications', () {}),
                              _buildMenuItem('🌐', 'Langue & Région', () {}),
                              _buildMenuItem('❓', 'Aide & Support', () {}),
                              _buildMenuItem('⚙️', 'Administration', () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                                );
                              }),
                              _buildMenuItem(
                                '🚪',
                                'Déconnexion',
                                _signOut,
                                color: AppTheme.coral,
                              ),
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

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.dark,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildPrefRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: AppTheme.muted)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    String emoji,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: color ?? AppTheme.dark,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: color ?? AppTheme.muted, size: 20),
          ],
        ),
      ),
    );
  }
}
