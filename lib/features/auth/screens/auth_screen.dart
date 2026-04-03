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
    return Scaffold(
      body: Stack(
        children: [
          // Fond dégradé
          Container(
            height: 320,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF00C9B1), Color(0xFF0093E9)],
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // Logo & titre
                  const Text('✈️', style: TextStyle(fontSize: 52)),
                  const SizedBox(height: 12),
                  const Text(
                    'Voyage App',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Planifiez votre aventure',
                    style: TextStyle(fontSize: 15, color: Colors.white70),
                  ),

                  const SizedBox(height: 40),

                  // Card principale
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Onglets
                        Container(
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicator: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            labelColor: Colors.white,
                            unselectedLabelColor: AppTheme.muted,
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
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  8,
                                  20,
                                  20,
                                ),
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
                                          child: const Text(
                                            'Mot de passe oublié ?',
                                            style: TextStyle(
                                              color: AppTheme.primary,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ElevatedButton(
                                        onPressed: _loading ? null : _signIn,
                                        child: _loading
                                            ? const SizedBox(
                                                height: 22,
                                                width: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Text(
                                                'Se connecter',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // ── REGISTER ──
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  8,
                                  20,
                                  20,
                                ),
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
                                      ElevatedButton(
                                        onPressed: _loading ? null : _signUp,
                                        child: _loading
                                            ? const SizedBox(
                                                height: 22,
                                                width: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Text(
                                                "S'inscrire",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
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
                    '🌍 Découvrez le monde avec nous',
                    style: TextStyle(color: AppTheme.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
