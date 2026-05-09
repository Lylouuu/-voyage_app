import 'package:flutter/material.dart';

class AppTheme {
  // ── Palette principale : Bleu ciel & blanc voyage ──────────
  static const Color primary = Color(0xFF4DB6E8);      // Bleu ciel vif
  static const Color primaryLight = Color(0xFF87CEEB);  // Bleu ciel doux
  static const Color primaryDeep = Color(0xFF1A7EC8);   // Bleu océan profond
  static const Color secondary = Color(0xFFE0F7FA);     // Blanc azuré
  static const Color accent = Color(0xFF00B4D8);        // Cyan azur
  static const Color accentSoft = Color(0xFF90E0EF);    // Cyan clair

  static const Color background = Color(0xFFF0F8FF);    // Alice blue
  static const Color dark = Color(0xFF0D1B2A);          // Bleu nuit profond
  static const Color muted = Color(0xFF7A9BA8);         // Gris bleuté
  static const Color coral = Color(0xFFFF7F6B);         // Accent chaleureux

  // ── Light theme (Nouveau design) ────────────────────────────
  static const Color backgroundLight = Color(0xFFF4F9FF); // Bleu très pâle (fond)
  static const Color surfaceLight = Colors.white;         // Blanc pur (cartes, panneaux)
  static const Color textDark = Color(0xFF0A192F);        // Bleu nuit pour le texte
  static const Color darkNavy = Color(0xFF0E2D4A);       // Bleu océan profond (plus de nuit noire)
  static const Color darkNavyLight = Color(0xFF143657);  // Bleu océan intermédiaire
  static const Color skyBlue = Color(0xFF4DB6E8);        // Bleu ciel vif

  /// Couleur d'accent principal (boutons, indicateurs actifs)
  /// Remplace l'ancien limeGreen jaune par un bleu ciel élégant
  static const Color limeGreen = skyBlue; // alias de compatibilité → bleu ciel

  /// Thème global Light — fond blanc/bleu très pâle, accents bleu ciel
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: skyBlue,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: ColorScheme.light(
        primary: skyBlue,
        secondary: secondary,
        surface: surfaceLight,
        background: backgroundLight,
        onBackground: textDark,
        onSurface: textDark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDeep,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 3,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF0F7FD),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: skyBlue, width: 1.8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle:
            TextStyle(color: const Color(0xFF8AA3B8).withOpacity(0.7)),
      ),
    );
  }
}
