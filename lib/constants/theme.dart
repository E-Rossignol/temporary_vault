import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color darkBackground = Color(0xFF0C0C0F);
  static const Color darkGold = Color(0xFFB8860B); // dark gold accent

  static ThemeData themeData() {
    final base = ThemeData.dark();
    return base.copyWith(
      // rendre le scaffold transparent afin que l'image de fond soit visible
      scaffoldBackgroundColor: Colors.transparent,
      // s'assurer que les surfaces par défaut n'obstruent pas l'arrière-plan
      canvasColor: Colors.transparent,
      textTheme: GoogleFonts.montserratTextTheme(
        base.textTheme,
      ).apply(bodyColor: Colors.white, displayColor: Colors.white),
      colorScheme: ColorScheme.dark(
        primary: darkGold,
        secondary: darkGold.withOpacity(0.9),
        background: darkBackground,
      ),
      appBarTheme: AppBarTheme(
        // appbar semi-transparent pour conserver lisibilité sans masquer totalement le fond
        backgroundColor: Colors.black.withOpacity(0.35),
        elevation: 2,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkGold,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF131316),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
      ),
    );
  }
}
