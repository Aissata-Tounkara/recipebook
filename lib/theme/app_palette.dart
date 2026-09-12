// Palette de couleurs partagée par tous les écrans de RecipeBook.

import 'package:flutter/material.dart';

class AppPalette {
  AppPalette._();

  static const background = Color(0xFFFBF5EE);
  static const card = Colors.white;
  static const brown = Color(0xFF9E4A24);
  static const textDark = Color(0xFF2E2A26);
  static const textMuted = Color(0xFF8C8279);

  // Accents pastel.
  static const peachBg = Color(0xFFF7E2D2);
  static const peachText = Color(0xFFB5602A);
  static const greenBg = Color(0xFFDDEBE0);
  static const greenText = Color(0xFF3F7D5A);
  static const pinkBg = Color(0xFFF6E0E0);
  static const amber = Color(0xFFF2A93B);
  static const heart = Color(0xFFE05B4B);

  // Repli visuel des images.
  static const imageGradient = <Color>[
    Color(0xFFF7E2D2),
    Color(0xFFEBC9AE),
  ];

  static const thinBorder = Color(0xFFEDE3D8);
}