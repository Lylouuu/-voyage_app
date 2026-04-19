import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voyage_app/core/theme/app_theme.dart';
import 'package:voyage_app/features/auth/widgets/auth_text__field.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailRegController = TextEditingController();
  final _passwordRegController = TextEditingController();

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailRegController.dispose();
    _passwordRegController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_registerFormKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.signUp(
        email: _emailRegController.text.trim(),
        password: _passwordRegController.text.trim(),
        data: {'nom': _nomController.text.trim()},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Compte créé ! Vérifiez votre email.'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${e.message}'),
            backgroundColor: AppTheme.secondary,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Connecté avec succès !'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${e.message}'),
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
    const Color nightBlue = Color(0xFF131936);
    const Color nightBlueLighter = Color(0xFF1C2541);
    const Color accentTeal = Color(0xFFC4E538); // Vert lime

    return Scaffold(
      backgroundColor: nightBlue,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 50),

              // Logo NexTrip
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "NEX",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const Icon(
                    Icons.airplanemode_active,
                    color: Colors.white,
                    size: 42,
                  ),
                  const Text(
                    "RIP",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Your next adventure starts here',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.5),
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 40),

              // Card principale avec effet glassmorphism
              Container(
                decoration: BoxDecoration(
                  color: nightBlueLighter,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Onglets stylisés
                    Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: accentTeal,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: accentTeal.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white.withOpacity(0.4),
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(text: 'Connexion'),
                          Tab(text: 'Inscription'),
                        ],
                      ),
                    ),

                    // Formulaires
                    SizedBox(
                      height: 400,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // ── LOGIN ──
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  AuthTextField(
                                    label: 'Email',
                                    hint: 'votre@email.com',
                                    icon: Icons.email_outlined,
                                    controller: _emailController,
                                    validator: (v) =>
                                        v!.isEmpty ? 'Email requis' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  AuthTextField(
                                    label: 'Mot de passe',
                                    hint: '••••••••',
                                    icon: Icons.lock_outline,
                                    controller: _passwordController,
                                    isPassword: true,
                                    validator: (v) => v!.length < 6
                                        ? 'Min 6 caractères'
                                        : null,
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {},
                                      child: Text(
                                        'Mot de passe oublié ?',
                                        style: TextStyle(
                                          color: accentTeal.withOpacity(0.8),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Bouton de connexion
                                  Container(
                                    width: double.infinity,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [accentTeal, accentTeal],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: accentTeal.withOpacity(0.4),
                                          blurRadius: 15,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _loading ? null : _signIn,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
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
                                          : const Text(
                                              'Se connecter',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: nightBlue,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // ── REGISTER ──
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                            child: Form(
                              key: _registerFormKey,
                              child: Column(
                                children: [
                                  AuthTextField(
                                    label: 'Nom complet',
                                    hint: 'Votre nom',
                                    icon: Icons.person_outline,
                                    controller: _nomController,
                                    validator: (v) =>
                                        v!.isEmpty ? 'Nom requis' : null,
                                  ),
                                  const SizedBox(height: 14),
                                  AuthTextField(
                                    label: 'Email',
                                    hint: 'votre@email.com',
                                    icon: Icons.email_outlined,
                                    controller: _emailRegController,
                                    validator: (v) =>
                                        v!.isEmpty ? 'Email requis' : null,
                                  ),
                                  const SizedBox(height: 14),
                                  AuthTextField(
                                    label: 'Mot de passe',
                                    hint: '••••••••',
                                    icon: Icons.lock_outline,
                                    controller: _passwordRegController,
                                    isPassword: true,
                                    validator: (v) => v!.length < 6
                                        ? 'Min 6 caractères'
                                        : null,
                                  ),
                                  const SizedBox(height: 20),
                                  // Bouton d'inscription
                                  Container(
                                    width: double.infinity,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [accentTeal, Color(0xFF0093E9)],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: accentTeal.withOpacity(0.4),
                                          blurRadius: 15,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _loading ? null : _signUp,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
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
                                          : const Text(
                                              "S'inscrire",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: nightBlue,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              Text(
                '✈️ Discover the world with NexTrip',
                style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
