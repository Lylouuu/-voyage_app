import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:voyage_app/features/auth/widgets/auth_text__field.dart';

// ─── Palette bleu ciel & voyage ──────────────────────────────────────────────
const _kNavy     = Color(0xFF0E2D4A);  // Bleu océan profond
const _kSky      = Color(0xFF4DB6E8);  // Bleu ciel vif
const _kSkyDeep  = Color(0xFF1A7EC8);  // Bleu océan
const _kSkyDim   = Color(0xFF3A95C5);  // Bleu ciel atténué
const _kCyan     = Color(0xFF00B4D8);  // Cyan azur
// ─────────────────────────────────────────────────────────────────────────────

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late VideoPlayerController _videoController;
  bool _videoReady = false;

  final _formKey         = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _loading    = false;
  bool _emailSent  = false;
  bool _btnPressed = false;

  static const _videoAsset = 'assets/videos/hover.mp4';

  @override
  void initState() {
    super.initState();
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
      // Fallback dégradé si la vidéo échoue
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // ── Logique réinitialisation ───────────────────────────────────────────────
  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        _emailController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _loading = false;
          _emailSent = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ ${e.toString()}'),
          backgroundColor: const Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final heroH   = screenH * 0.42;

    return Scaffold(
      backgroundColor: _kNavy,
      body: Stack(
        children: [
          // ── 1. VIDÉO / DÉGRADÉ HERO ─────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: heroH + 60,
            child: Stack(
              fit: StackFit.expand,
              children: [
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
                              Color(0xFF0E2D4A),
                              Color(0xFF1A5F8A),
                              Color(0xFF4DB6E8),
                            ],
                            stops: [0.0, 0.55, 1.0],
                          ),
                        ),
                      ),

                // Overlay dégradé sombre
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.22),
                        Colors.black.withOpacity(0.05),
                        Colors.black.withOpacity(0.48),
                        _kNavy.withOpacity(0.97),
                      ],
                      stops: const [0.0, 0.3, 0.65, 1.0],
                    ),
                  ),
                ),

                // Lueur décorative bleu ciel
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _kSky.withOpacity(0.16),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── 2. CONTENU SCROLLABLE ────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Zone texte hero
                  SizedBox(
                    height: heroH - 50,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLogo(),
                          const SizedBox(height: 24),

                          // Titre animé (change selon état)
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            child: Text(
                              _emailSent
                                  ? 'Vérifiez\nvotre boîte !'
                                  : 'Mot de passe\noublié ?',
                              key: ValueKey(_emailSent),
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.15,
                                letterSpacing: -0.8,
                                shadows: [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 22,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            child: Text(
                              _emailSent
                                  ? 'Un lien de réinitialisation\na été envoyé à votre email.'
                                  : 'Saisissez votre email et nous vous\nenverrons un lien de récupération.',
                              key: ValueKey('sub_$_emailSent'),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.68),
                                height: 1.55,
                                letterSpacing: 0.1,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black38,
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
                  ),

                  // ── Panneau glassmorphism ─────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: _emailSent
                          ? _buildSuccessPanel()
                          : _buildResetPanel(),
                    ),
                  ),

                  const SizedBox(height: 24),
                  _buildBackToLogin(),
                  const SizedBox(height: 32),
                  _buildFooter(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── 3. BOUTON RETOUR (haut gauche) ───────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _kSky.withOpacity(0.20),
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: _kSky,
                      size: 18,
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

  // ═══════════════════════════════════════════════════════════════════════════
  //  WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

  // ── Logo NEX✈RIP ──────────────────────────────────────────────────────────
  Widget _buildLogo() {
    return Row(
      children: [
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [Colors.white, Color(0xFFD0EEFF)],
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
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [_kSky, _kCyan],
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
            colors: [Color(0xFFD0EEFF), Colors.white],
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

  // ── Panneau de réinitialisation ───────────────────────────────────────────
  Widget _buildResetPanel() {
    return ClipRRect(
      key: const ValueKey('reset'),
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.09),
                Colors.white.withOpacity(0.03),
              ],
            ),
            border: Border.all(
              color: _kSky.withOpacity(0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.48),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: _kSky.withOpacity(0.06),
                blurRadius: 60,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône mail bleu ciel
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        _kSky.withOpacity(0.18),
                        _kCyan.withOpacity(0.10),
                      ],
                    ),
                    border: Border.all(
                      color: _kSky.withOpacity(0.28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _kSky.withOpacity(0.20),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mail_outline_rounded,
                    color: _kSky,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 22),

                AuthTextField(
                  label: 'Email',
                  hint: 'votre@email.com',
                  icon: Icons.alternate_email_rounded,
                  controller: _emailController,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email requis';
                    if (!v.contains('@')) return 'Email invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                _buildCTAButton(
                  label: 'Envoyer le lien',
                  onTap: _sendResetLink,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Panneau succès ────────────────────────────────────────────────────────
  Widget _buildSuccessPanel() {
    return ClipRRect(
      key: const ValueKey('success'),
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.09),
                Colors.white.withOpacity(0.03),
              ],
            ),
            border: Border.all(
              color: _kSky.withOpacity(0.18),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.48),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: _kSky.withOpacity(0.08),
                blurRadius: 60,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icône succès avec dégradé bleu ciel
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [_kSky, _kSkyDeep],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _kSky.withOpacity(0.38),
                      blurRadius: 22,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(height: 22),

              const Text(
                'Email envoyé !',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Vérifiez votre boîte de réception\npour réinitialiser votre mot de passe.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: Colors.white.withOpacity(0.52),
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 26),

              _buildCTAButton(
                label: 'Retour à la connexion',
                onTap: () async => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bouton CTA dégradé bleu ciel ──────────────────────────────────────────
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
        scale: _btnPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(27),
            gradient: _loading
                ? LinearGradient(
                    colors: [
                      _kSkyDim.withOpacity(0.6),
                      _kSkyDeep.withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [_kSky, _kSkyDeep],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            boxShadow: (_btnPressed || _loading)
                ? []
                : [
                    BoxShadow(
                      color: _kSky.withOpacity(0.40),
                      blurRadius: 22,
                      offset: const Offset(0, 7),
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
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 17,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ── Lien retour connexion ─────────────────────────────────────────────────
  Widget _buildBackToLogin() {
    if (_emailSent) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.arrow_back_rounded,
            size: 14,
            color: Colors.white.withOpacity(0.35),
          ),
          const SizedBox(width: 6),
          Text(
            'Retour à la connexion',
            style: TextStyle(
              color: Colors.white.withOpacity(0.38),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Pied de page ──────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [_kSky, _kCyan],
          ).createShader(b),
          child: Icon(
            Icons.flight_rounded,
            size: 12,
            color: Colors.white.withOpacity(0.3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'Explorez le monde avec NexTrip',
          style: TextStyle(
            color: Colors.white.withOpacity(0.20),
            fontSize: 11,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
