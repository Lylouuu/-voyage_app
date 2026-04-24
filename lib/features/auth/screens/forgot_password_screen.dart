import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:voyage_app/features/auth/widgets/auth_text__field.dart';

// ─── Same design palette as auth_screen ──────────────────────────────────────
const _kNavy     = Color(0xFF080D1A);
const _kGreen    = Color(0xFFCBF266);
const _kCyan     = Color(0xFF00D4FF);
const _kGreenDim = Color(0xFFA8CC4E);
// ─────────────────────────────────────────────────────────────────────────────

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late VideoPlayerController _videoController;
  bool _videoReady = false;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _loading = false;
  bool _emailSent = false;
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
      // Graceful fallback
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // ── Reset password logic ──────────────────────────────────────────────────
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
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  // ═════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final heroH = screenH * 0.42; // slightly shorter than auth

    return Scaffold(
      backgroundColor: _kNavy,
      body: Stack(
        children: [
          // ── 1. VIDEO HERO ─────────────────────────────────────────────────
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
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF1A2980),
                              Color(0xFF26D0CE),
                            ],
                          ),
                        ),
                      ),
                // Dark gradient overlay
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

          // ── 2. CONTENT ────────────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Hero text area
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
                          Text(
                            _emailSent
                                ? 'Check your\ninbox'
                                : 'Reset your\npassword',
                            style: const TextStyle(
                              fontSize: 36,
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
                          Text(
                            _emailSent
                                ? 'We sent a reset link to your email.\nPlease check your inbox.'
                                : 'Enter your email to receive\nreset instructions.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.70),
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
                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
                  ),

                  // ── Glass panel ───────────────────────────────────────────
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

                  // Back to login
                  _buildBackToLogin(),

                  const SizedBox(height: 32),
                  _buildFooter(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── 3. BACK BUTTON (top-left) ─────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white.withValues(alpha: 0.80),
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

  // ═════════════════════════════════════════════════════════════════════════════
  //  WIDGETS
  // ═════════════════════════════════════════════════════════════════════════════

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

  // ── Reset form panel ──────────────────────────────────────────────────────
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
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mail icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kGreen.withValues(alpha: 0.12),
                    border: Border.all(
                      color: _kGreen.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Icon(
                    Icons.mail_outline_rounded,
                    color: _kGreen,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 20),

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
                const SizedBox(height: 22),

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

  // ── Success panel ─────────────────────────────────────────────────────────
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
              // Success check icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kGreen.withValues(alpha: 0.15),
                  border: Border.all(
                    color: _kGreen.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _kGreen.withValues(alpha: 0.20),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: _kGreen,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Email envoyé !',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
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
                  color: Colors.white.withValues(alpha: 0.55),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

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

  // ── CTA button (same as auth screen) ──────────────────────────────────────
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

  // ── Back to login link ────────────────────────────────────────────────────
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
            color: Colors.white.withValues(alpha: 0.40),
          ),
          const SizedBox(width: 6),
          Text(
            'Retour à la connexion',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.40),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
