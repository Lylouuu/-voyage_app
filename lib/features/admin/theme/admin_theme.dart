import 'package:flutter/material.dart';

/// Thème premium clair (Light Mode) avec design fluide pour le panneau d'administration
class AdminTheme {
  // ── Couleurs principales ────────────────────────────────────
  static const Color background = Color(0xFFF4F9FF); // Bleu ciel très clair
  static const Color surface = Color(0xFFFFFFFF); // Blanc pur
  static const Color surfaceLight = Color(0xFFF8FAFC); // Gris/Bleu très très clair
  static const Color surfaceBorder = Color(0x1A4A6580); // Bordure subtile foncée

  // Accents (Bleu Ciel moderne)
  static const Color accent = Color(0xFF4DB6E8); // Bleu ciel
  static const Color accentLight = Color(0xFF7EC8E3);
  static const Color accentSoft = Color(0x1A4DB6E8);

  // Sémantiques
  static const Color success = Color(0xFF00C9A7);
  static const Color successSoft = Color(0x1A00C9A7);
  static const Color warning = Color(0xFFFFB547);
  static const Color warningSoft = Color(0x1AFFB547);
  static const Color danger = Color(0xFFFF6B6B);
  static const Color dangerSoft = Color(0x1AFF6B6B);
  static const Color info = Color(0xFF4ECDC4);
  static const Color infoSoft = Color(0x1A4ECDC4);

  // Texte
  static const Color textPrimary = Color(0xFF0A192F); // Bleu marine très foncé
  static const Color textSecondary = Color(0xFF4A6580); // Gris bleuté
  static const Color textMuted = Color(0x994A6580); // Gris bleuté 60%

  // Gradient principal
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4DB6E8), Color(0xFF1A7EC8)],
  );

  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
  );

  // ── Bordures & rayons (Plus fluides) ────────────────────────
  static BorderRadius radiusSm = BorderRadius.circular(12);
  static BorderRadius radiusMd = BorderRadius.circular(16);
  static BorderRadius radiusLg = BorderRadius.circular(24);
  static BorderRadius radiusXl = BorderRadius.circular(30);

  // ── Ombres (Très douces pour l'effet light) ─────────────────
  static List<BoxShadow> shadowSm = [
    BoxShadow(
      color: const Color(0xFF000000).withOpacity(0.04),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> shadowMd = [
    BoxShadow(
      color: const Color(0xFF000000).withOpacity(0.08),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> shadowLg = [
    BoxShadow(
      color: const Color(0xFF4DB6E8).withOpacity(0.15),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];

  // ── Décoration carte ────────────────────────────────────────
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: surface,
    borderRadius: radiusLg,
    border: Border.all(color: surfaceBorder.withOpacity(0.5), width: 1),
    boxShadow: shadowSm,
  );

  static BoxDecoration get cardDecorationHover => BoxDecoration(
    color: surface,
    borderRadius: radiusLg,
    border: Border.all(color: accent.withOpacity(0.5), width: 1),
    boxShadow: shadowLg,
  );

  // ── Styles de texte ─────────────────────────────────────────
  static const TextStyle headingLg = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle headingMd = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static const TextStyle headingSm = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static const TextStyle bodyMd = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );

  static const TextStyle bodySm = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: textMuted,
  );

  static const TextStyle labelMd = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: textSecondary,
  );

  // ── Input decoration (Champs fluides) ───────────────────────
  static InputDecoration inputDecoration({
    required String label,
    IconData? icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
      hintStyle: const TextStyle(color: textMuted, fontSize: 13),
      prefixIcon: icon != null ? Icon(icon, color: accent, size: 22) : null,
      filled: true,
      fillColor: Colors.transparent,
      border: OutlineInputBorder(
        borderRadius: radiusMd,
        borderSide: BorderSide(color: surfaceBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radiusMd,
        borderSide: BorderSide(color: surfaceBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radiusMd,
        borderSide: const BorderSide(color: accent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radiusMd,
        borderSide: const BorderSide(color: danger),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  // ── Button styles (Boutons modernes et arrondis) ────────────
  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: accent,
    foregroundColor: Colors.white, // White text on blue button
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)), // Fluid button
    elevation: 4,
    shadowColor: accent.withOpacity(0.5),
    textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
  );

  static ButtonStyle dangerButton = ElevatedButton.styleFrom(
    backgroundColor: danger,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
    elevation: 4,
    shadowColor: danger.withOpacity(0.5),
    textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
  );

  static ButtonStyle outlineButton = OutlinedButton.styleFrom(
    foregroundColor: textPrimary,
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
    side: const BorderSide(color: surfaceBorder, width: 1.5),
    textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
  );
}
