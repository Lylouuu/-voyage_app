import 'package:flutter/material.dart';

// ── Palette light ──────────────────────────────────────────────
const _kSky      = Color(0xFF4DB6E8);
const _kSkyDeep  = Color(0xFF1A7EC8);
const _kTextDark = Color(0xFF0A192F);
const _kGrey     = Color(0xFF8AA3B8);
const _kBgField  = Color(0xFFF0F7FD);
// ──────────────────────────────────────────────────────────────

class AuthTextField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const AuthTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.isPassword = false,
    this.validator,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField>
    with SingleTickerProviderStateMixin {
  bool _obscure  = true;
  bool _focused  = false;
  late final AnimationController _animCtrl;
  late final Animation<double> _borderAnim;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _borderAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _focusNode = FocusNode()
      ..addListener(() {
        setState(() => _focused = _focusNode.hasFocus);
        _focusNode.hasFocus ? _animCtrl.forward() : _animCtrl.reverse();
      });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _focused ? _kSkyDeep : _kTextDark.withOpacity(0.55),
            letterSpacing: 0.2,
          ),
          child: Text(widget.label),
        ),
        const SizedBox(height: 8),

        // Champ de saisie
        AnimatedBuilder(
          animation: _borderAnim,
          builder: (_, __) {
            return Container(
              decoration: BoxDecoration(
                color: _kBgField,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Color.lerp(
                    Colors.transparent,
                    _kSky,
                    _borderAnim.value,
                  )!,
                  width: 1.8,
                ),
                boxShadow: _focused
                    ? [
                        BoxShadow(
                          color: _kSky.withOpacity(0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: TextFormField(
                controller: widget.controller,
                focusNode: _focusNode,
                obscureText: widget.isPassword && _obscure,
                validator: widget.validator,
                style: const TextStyle(
                  color: _kTextDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                cursorColor: _kSky,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: TextStyle(
                    color: _kGrey.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: Icon(
                    widget.icon,
                    color: _focused ? _kSky : _kGrey,
                    size: 20,
                  ),
                  suffixIcon: widget.isPassword
                      ? GestureDetector(
                          onTap: () => setState(() => _obscure = !_obscure),
                          child: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: _focused ? _kSky : _kGrey,
                            size: 20,
                          ),
                        )
                      : null,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  errorStyle: const TextStyle(
                    color: Color(0xFFE05C5C),
                    fontSize: 11.5,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
