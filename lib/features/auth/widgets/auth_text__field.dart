import 'package:flutter/material.dart';

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

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscure = true;
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  // Palette
  static const Color _accentGreen = Color(0xFFCBF266);

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
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
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: _isFocused
                ? _accentGreen
                : Colors.white.withValues(alpha: 0.55),
          ),
          child: Text(widget.label.toUpperCase()),
        ),
        const SizedBox(height: 8),

        // Input with animated glow
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: _accentGreen.withValues(alpha: 0.18),
                      blurRadius: 16,
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: _accentGreen.withValues(alpha: 0.08),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.20),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.isPassword && _obscure,
            validator: widget.validator,
            // ── PURE WHITE text — fully visible ──
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
            cursorColor: _accentGreen,
            cursorWidth: 2,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.30),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  widget.icon,
                  color: _isFocused
                      ? _accentGreen.withValues(alpha: 0.90)
                      : Colors.white.withValues(alpha: 0.40),
                  size: 19,
                ),
              ),
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: _isFocused
                            ? _accentGreen.withValues(alpha: 0.80)
                            : Colors.white.withValues(alpha: 0.35),
                        size: 19,
                      ),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                    )
                  : null,
              filled: true,
              fillColor: _isFocused
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.12)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.12)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: _accentGreen.withValues(alpha: 0.70),
                  width: 1.4,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                    color: Color(0xFFFF6B6B), width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                    color: Color(0xFFFF6B6B), width: 1.4),
              ),
              errorStyle: const TextStyle(
                color: Color(0xFFFF6B6B),
                fontSize: 11,
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 17),
            ),
          ),
        ),
      ],
    );
  }
}
