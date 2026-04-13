import 'package:flutter/material.dart';
import 'package:voyage_app/features/admin/theme/admin_theme.dart';
import 'package:voyage_app/features/admin/services/admin_service.dart';
import 'package:voyage_app/features/admin/screens/admin_panel.dart';

/// Écran de connexion dédié à l'administration
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final admin = await AdminService.signInAdmin(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (!mounted) return;

      if (admin != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AdminPanel(adminData: admin)),
        );
      } else {
        setState(() {
          _errorMessage = 'Accès refusé. Seuls les administrateurs peuvent se connecter.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Email ou mot de passe incorrect.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.background,
      body: Stack(
        children: [
          // Fond décoratif
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AdminTheme.accent.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AdminTheme.info.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Contenu principal
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Container(
                    width: 420,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AdminTheme.surface,
                      borderRadius: AdminTheme.radiusXl,
                      border: Border.all(color: AdminTheme.surfaceBorder),
                      boxShadow: AdminTheme.shadowLg,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: AdminTheme.primaryGradient,
                              borderRadius: AdminTheme.radiusLg,
                              boxShadow: [
                                BoxShadow(
                                  color: AdminTheme.accent.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Titre
                          const Text(
                            'Administration',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: AdminTheme.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Connectez-vous pour gérer l\'application',
                            style: TextStyle(
                              fontSize: 14,
                              color: AdminTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Erreur
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AdminTheme.dangerSoft,
                                borderRadius: AdminTheme.radiusMd,
                                border: Border.all(
                                  color: AdminTheme.danger.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: AdminTheme.danger, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        color: AdminTheme.danger,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Email
                          TextFormField(
                            controller: _emailController,
                            style: const TextStyle(
                              color: AdminTheme.textPrimary,
                              fontSize: 14,
                            ),
                            decoration: AdminTheme.inputDecoration(
                              label: 'Adresse email',
                              icon: Icons.email_outlined,
                              hint: 'admin@voyage-app.com',
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Email requis' : null,
                          ),
                          const SizedBox(height: 18),

                          // Mot de passe
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(
                              color: AdminTheme.textPrimary,
                              fontSize: 14,
                            ),
                            decoration: AdminTheme.inputDecoration(
                              label: 'Mot de passe',
                              icon: Icons.lock_outline,
                              hint: '••••••••',
                            ).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AdminTheme.textMuted,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) => v == null || v.length < 6
                                ? 'Min 6 caractères'
                                : null,
                          ),
                          const SizedBox(height: 28),

                          // Bouton connexion
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AdminTheme.accent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: AdminTheme.radiusMd,
                                ),
                                elevation: 0,
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
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.login_rounded, size: 20),
                                        SizedBox(width: 10),
                                        Text(
                                          'Se connecter',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Lien retour
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              '← Retour à l\'application',
                              style: TextStyle(
                                color: AdminTheme.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
