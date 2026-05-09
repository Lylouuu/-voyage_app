import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:voyage_app/features/auth/widgets/auth_text__field.dart';
import 'package:voyage_app/features/auth/screens/forgot_password_screen.dart';

// ── Palette light & épurée ─────────────────────────────────────────────────
const _kBg       = Color(0xFFF4F9FF); // Fond principal bleu très pâle
const _kSky      = Color(0xFF4DB6E8); // Bleu ciel
const _kSkyDeep  = Color(0xFF1A7EC8); // Bleu océan
const _kTextDark = Color(0xFF0A192F); // Texte principal
const _kTextMid  = Color(0xFF4A6580); // Texte secondaire
// ──────────────────────────────────────────────────────────────────────────

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late VideoPlayerController _videoController;
  bool _videoReady = false;

  final _loginFormKey    = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  final _nomController         = TextEditingController();
  final _emailController       = TextEditingController();
  final _passwordController    = TextEditingController();
  final _emailRegController    = TextEditingController();
  final _passwordRegController = TextEditingController();

  bool _loading   = false;
  int  _activeTab = 0;

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
    } catch (_) {}
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

  // ── Auth logic ────────────────────────────────────────────────────────────
  Future<void> _signIn() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) _showSnack('✅ Connecté avec succès !', success: true);
    } on AuthException catch (e) {
      if (mounted) _showSnack('❌ ${e.message}', success: false);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
      if (mounted) _showSnack('✅ Compte créé ! Vérifiez votre email.', success: true);
    } on AuthException catch (e) {
      if (mounted) _showSnack('❌ ${e.message}', success: false);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: success ? _kSkyDeep : Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final videoH  = screenH * 0.44;

    return Scaffold(
      backgroundColor: _kBg,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ── 1. VIDÉO HERO ──────────────────────────────────────────────
            _buildVideoHero(videoH),

            // ── 2. FORMULAIRE (design clair) ───────────────────────────────
            Transform.translate(
              offset: const Offset(0, -32),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildCard(),
              ),
            ),

            Transform.translate(
              offset: const Offset(0, -20),
              child: Column(
                children: [
                  _buildOrDivider(),
                  const SizedBox(height: 14),
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
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  WIDGETS
  // ══════════════════════════════════════════════════════════

  // ── Vidéo hero avec overlay dégradé ───────────────────────────────────
  Widget _buildVideoHero(double videoH) {
    return SizedBox(
      width: double.infinity,
      height: videoH,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Vidéo ou fallback dégradé
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
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1A4F7A),
                        Color(0xFF4DB6E8),
                      ],
                    ),
                  ),
                ),

          // Overlay dégradé vers le blanc en bas (transition douce)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.10),
                  Colors.transparent,
                  _kBg.withOpacity(0.50),
                  _kBg.withOpacity(0.92),
                ],
                stops: const [0.0, 0.40, 0.75, 1.0],
              ),
            ),
          ),

          // Texte en bas de la vidéo
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(26, 0, 26, 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  _buildLogo(),
                  const SizedBox(height: 14),
                  // Titre
                  const Text(
                    'Voyagez,\nsans limites.',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.2,
                      letterSpacing: -0.5,
                      shadows: [
                        Shadow(color: Colors.black45, blurRadius: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Planifiez, explorez, vivez.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.78),
                      letterSpacing: 0.1,
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

  // ── Logo NEX✈RIP ─────────────────────────────────────────────────────
  Widget _buildLogo() {
    return Row(
      children: [
        const Text(
          'NEX',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Icon(
            Icons.airplanemode_active_rounded,
            color: Colors.white.withOpacity(0.9),
            size: 18,
          ),
        ),
        const Text(
          'RIP',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  // ── Carte formulaire blanche épurée ───────────────────────────────────
  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _kSky.withOpacity(0.10),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 24),
          _buildToggle(),
          const SizedBox(height: 4),

          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            child: SizedBox(
              height: _activeTab == 0 ? 318 : 408,
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildLoginForm(),
                  _buildRegisterForm(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Toggle Connexion / Inscription ─────────────────────────────────────
  Widget _buildToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F7FD),
          borderRadius: BorderRadius.circular(24),
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
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _kSky.withOpacity(0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: [
                _toggleTab('Connexion', 0),
                _toggleTab('Inscription', 1),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleTab(String label, int index) {
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
              fontSize: 13.5,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? _kSkyDeep : _kTextMid,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  // ── Formulaire Connexion ───────────────────────────────────────────────
  Widget _buildLoginForm() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Form(
          key: _loginFormKey,
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
                validator: (v) => v!.length < 6 ? 'Min. 6 caractères' : null,
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ForgotPasswordScreen()),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 4),
                  ),
                  child: const Text(
                    'Mot de passe oublié ?',
                    style: TextStyle(
                      color: _kSky,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildCTAButton(label: 'Se connecter', onTap: _signIn),
            ],
          ),
        ),
      ),
    );
  }

  // ── Formulaire Inscription ─────────────────────────────────────────────
  Widget _buildRegisterForm() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
              const SizedBox(height: 14),
              AuthTextField(
                label: 'Email',
                hint: 'votre@email.com',
                icon: Icons.alternate_email_rounded,
                controller: _emailRegController,
                validator: (v) => v!.isEmpty ? 'Email requis' : null,
              ),
              const SizedBox(height: 14),
              AuthTextField(
                label: 'Mot de passe',
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                controller: _passwordRegController,
                isPassword: true,
                validator: (v) => v!.length < 6 ? 'Min. 6 caractères' : null,
              ),
              const SizedBox(height: 22),
              _buildCTAButton(label: "Créer mon compte", onTap: _signUp),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bouton CTA ─────────────────────────────────────────────────────────
  Widget _buildCTAButton({
    required String label,
    required Future<void> Function() onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kSkyDeep,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _kSky.withOpacity(0.45),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ).copyWith(
          elevation: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.pressed) ? 0 : 4),
          shadowColor: WidgetStateProperty.all(_kSky.withOpacity(0.28)),
        ),
        child: _loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 17),
                ],
              ),
      ),
    );
  }

  // ── Séparateur OU ─────────────────────────────────────────────────────
  Widget _buildOrDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          Expanded(
              child: Divider(
                  color: _kTextMid.withOpacity(0.15), thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text('ou',
                style: TextStyle(
                    color: _kTextMid.withOpacity(0.5), fontSize: 12.5)),
          ),
          Expanded(
              child: Divider(
                  color: _kTextMid.withOpacity(0.15), thickness: 1)),
        ],
      ),
    );
  }

  // ── Bouton Google ─────────────────────────────────────────────────────
  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: () =>
            _showSnack('Google Sign-In bientôt disponible 🚀', success: true),
        style: OutlinedButton.styleFrom(
          foregroundColor: _kTextDark,
          side: BorderSide(color: _kTextMid.withOpacity(0.22), width: 1.2),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFF4285F4),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(
                child: Text('G',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
            ),
            const SizedBox(width: 12),
            Text('Continuer avec Google',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _kTextDark.withOpacity(0.70))),
          ],
        ),
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.flight_rounded, size: 12, color: _kSky.withOpacity(0.5)),
        const SizedBox(width: 6),
        Text(
          'Explorez le monde avec NexTrip',
          style: TextStyle(
              color: _kTextMid.withOpacity(0.4),
              fontSize: 11.5,
              letterSpacing: 0.2),
        ),
      ],
    );
  }
}
