import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:voyage_app/core/theme/app_theme.dart';
import 'package:voyage_app/features/auth/widgets/auth_text__field.dart';
import 'package:voyage_app/features/auth/screens/forgot_password_screen.dart';
import 'package:voyage_app/features/home/screens/home_screen.dart';

// ─── Design palette ──────────────────────────────────────────────────────────
const _kNavy     = Color(0xFF080D1A);
const _kDeepBlue = Color(0xFF0D1730);
const _kGreen    = Color(0xFFCBF266);
const _kCyan     = Color(0xFF00D4FF);
const _kGreenDim = Color(0xFFA8CC4E);
// ─────────────────────────────────────────────────────────────────────────────

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  // ── Controllers ────────────────────────────────────────────────────────────
  late TabController _tabController;
  late VideoPlayerController _videoController;
  bool _videoReady = false;

  final _formKey         = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  final _nomController         = TextEditingController();
  final _emailController       = TextEditingController();
  final _passwordController    = TextEditingController();
  final _emailRegController    = TextEditingController();
  final _passwordRegController = TextEditingController();

  bool _loading    = false;
  int  _activeTab  = 0;
  bool _btnPressed = false;

  // ── Local video asset ──────────────────────────────────────────────────────
  static const _videoAsset = 'assets/videos/hover.mp4';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging) return;
        setState(() => _activeTab = _tabController.index);
      });

    _initVideo();
  }

  Future<void> _initVideo() async {
    _videoController = VideoPlayerController.asset(_videoAsset);
    try {
      await _videoController.initialize();
      _videoController.setLooping(true);
      _videoController.setVolume(0);
      _videoController.play();
      if (mounted) setState(() => _videoReady = true);
    } catch (_) {
      // Video failed — graceful fallback to gradient
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _videoController.dispose();
    _nomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailRegController.dispose();
    _passwordRegController.dispose();
    super.dispose();
  }

  // ── Auth logic (unchanged) ────────────────────────────────────────────────
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('✅ Compte créé ! Vérifiez votre email.'),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ));
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ ${e.message}'),
          backgroundColor: AppTheme.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('✅ Connecté avec succès !'),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ));
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ ${e.message}'),
          backgroundColor: AppTheme.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ═════════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final heroH = screenH * 0.48;   // 48 % hero

    return Scaffold(
      backgroundColor: _kNavy,
      body: Stack(
        children: [
          // ── 1. VIDEO HERO (top ~48 %) ─────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: heroH + 60,  // +60 for curved overlap
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Video or gradient fallback
                _videoReady
                    ? FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _videoController.value.size.width,
                          height: _videoController.value.size.height,
                          child: VideoPlayer(_videoController),
                        ),
                      )
                    : Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF1A2980),
                              Color(0xFF26D0CE),
                            ],
                          ),
                        ),
                      ),

                // Dark gradient overlay for text readability
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.25),
                        Colors.black.withValues(alpha: 0.10),
                        Colors.black.withValues(alpha: 0.50),
                        _kNavy.withValues(alpha: 0.95),
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── 2. SCROLLABLE CONTENT ─────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Hero text overlay area
                  SizedBox(
                    height: heroH - 40,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Logo row
                          _buildLogo(),
                          const SizedBox(height: 20),

                          // Big title
                          const Text(
                            'Travel,\nsimplified.',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.15,
                              letterSpacing: -0.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Subtitle
                          Text(
                            'Plan, explore, and experience the\nworld effortlessly.',
                            style: TextStyle(
                              fontSize: 14.5,
                              color: Colors.white.withValues(alpha: 0.75),
                              height: 1.5,
                              letterSpacing: 0.2,
                              shadows: const [
                                Shadow(
                                  color: Colors.black38,
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Dot indicator
                          _buildDotIndicator(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),

                  // ── AUTH PANEL ──────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildAuthPanel(),
                  ),

                  const SizedBox(height: 24),

                  // Divider + Google
                  _buildOrDivider(),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildGoogleButton(),
                  ),

                  const SizedBox(height: 28),
                  _buildFooter(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  //  WIDGETS
  // ═════════════════════════════════════════════════════════════════════════════

  // ── Logo (compact) ────────────────────────────────────────────────────────
  Widget _buildLogo() {
    return Row(
      children: [
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [Colors.white, Color(0xFFD8E4FF)],
          ).createShader(b),
          child: const Text(
            'NEX',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [_kGreen, _kGreen],
            ).createShader(b),
            child: const Icon(
              Icons.airplanemode_active_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [Color(0xFFD8E4FF), Colors.white],
          ).createShader(b),
          child: const Text(
            'RIP',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }

  // ── Dot indicator ─────────────────────────────────────────────────────────
  Widget _buildDotIndicator() {
    return Row(
      children: List.generate(3, (i) {
        final active = i == 0;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(right: 6),
          width: active ? 24 : 8,
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: active
                ? const LinearGradient(colors: [_kGreen, _kGreen])
                : null,
            color: active ? null : Colors.white.withValues(alpha: 0.25),
          ),
        );
      }),
    );
  }

  // ── Glass auth panel ──────────────────────────────────────────────────────
  Widget _buildAuthPanel() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.10),
                Colors.white.withValues(alpha: 0.04),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.50),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: _kCyan.withValues(alpha: 0.05),
                blurRadius: 60,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              _buildPillToggle(),
              const SizedBox(height: 4),

              // Forms — Increased height for errors
              SizedBox(
                height: _activeTab == 0 ? 360 : 460,
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildLoginForm(),
                    _buildRegisterForm(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Pill toggle ───────────────────────────────────────────────────────────
  Widget _buildPillToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              alignment: _activeTab == 0
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOutCubic,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(19),
                    color: _kGreen,
                    boxShadow: [
                      BoxShadow(
                        color: _kGreen.withValues(alpha: 0.35),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: [
                _pillTab('Connexion', 0),
                _pillTab('Inscription', 1),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pillTab(String label, int index) {
    final active = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() => _activeTab = index);
          _tabController.animateTo(index);
        },
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active
                  ? _kNavy
                  : Colors.white.withValues(alpha: 0.40),
              letterSpacing: 0.2,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  // ── Login form ────────────────────────────────────────────────────────────
  Widget _buildLoginForm() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AuthTextField(
                label: 'Email',
                hint: 'votre@email.com',
                icon: Icons.alternate_email_rounded,
                controller: _emailController,
                validator: (v) => v!.isEmpty ? 'Email requis' : null,
              ),
              const SizedBox(height: 14),
              AuthTextField(
                label: 'Mot de passe',
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                controller: _passwordController,
                isPassword: true,
                validator: (v) =>
                    v!.length < 6 ? 'Min 6 caractères' : null,
              ),
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen()),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 2),
                  ),
                  child: ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: [_kGreen, _kGreen],
                    ).createShader(b),
                    child: const Text(
                      'Mot de passe oublié ?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              _buildCTAButton(label: 'Se connecter', onTap: _signIn),
            ],
          ),
        ),
      ),
    );
  }

  // ── Register form ─────────────────────────────────────────────────────────
  Widget _buildRegisterForm() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
        child: Form(
          key: _registerFormKey,
          child: Column(
            children: [
              AuthTextField(
                label: 'Nom complet',
                hint: 'Votre nom',
                icon: Icons.person_outline_rounded,
                controller: _nomController,
                validator: (v) => v!.isEmpty ? 'Nom requis' : null,
              ),
              const SizedBox(height: 12),
              AuthTextField(
                label: 'Email',
                hint: 'votre@email.com',
                icon: Icons.alternate_email_rounded,
                controller: _emailRegController,
                validator: (v) => v!.isEmpty ? 'Email requis' : null,
              ),
              const SizedBox(height: 12),
              AuthTextField(
                label: 'Mot de passe',
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                controller: _passwordRegController,
                isPassword: true,
                validator: (v) =>
                    v!.length < 6 ? 'Min 6 caractères' : null,
              ),
              const SizedBox(height: 18),
              _buildCTAButton(label: "S'inscrire", onTap: _signUp),
            ],
          ),
        ),
      ),
    );
  }

  // ── Gradient CTA button ───────────────────────────────────────────────────
  Widget _buildCTAButton({
    required String label,
    required Future<void> Function() onTap,
  }) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _btnPressed = true),
      onTapUp: (_) async {
        setState(() => _btnPressed = false);
        if (!_loading) await onTap();
      },
      onTapCancel: () => setState(() => _btnPressed = false),
      child: AnimatedScale(
        scale: _btnPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            color: _loading
                ? _kGreenDim.withValues(alpha: 0.60)
                : _kGreen,
            boxShadow: (_btnPressed || _loading)
                ? []
                : [
                    BoxShadow(
                      color: _kGreen.withValues(alpha: 0.40),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Center(
            child: _loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.4,
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _kNavy,
                      letterSpacing: 0.4,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ── OR divider ────────────────────────────────────────────────────────────
  Widget _buildOrDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 0.5,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              'ou',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 0.5,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }

  // ── Google button ─────────────────────────────────────────────────────────
  Widget _buildGoogleButton() {
    return GestureDetector(
      onTap: () {
        // TODO: Google Sign-In
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Google Sign-In — bientôt disponible'),
          backgroundColor: _kDeepBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ));
      },
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google "G" icon using Material
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(
                child: Text(
                  'G',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4285F4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Continuer avec Google',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.70),
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.flight_rounded,
          size: 12,
          color: Colors.white.withValues(alpha: 0.20),
        ),
        const SizedBox(width: 6),
        Text(
          'Discover the world with NexTrip',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.20),
            fontSize: 11,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
