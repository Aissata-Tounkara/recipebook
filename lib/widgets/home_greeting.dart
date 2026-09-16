// Message de bienvenue affiché en haut de l'accueil.

import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

class HomeGreeting extends StatelessWidget {
  const HomeGreeting({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Bonjour !',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: AppPalette.textDark,
          ),
        ),
        SizedBox(height: 6),
        Text(
          "Qu'est-ce qu'on cuisine aujourd'hui ?",
          style: TextStyle(fontSize: 16, color: AppPalette.textMuted),
        ),
      ],
    );
  }
}
