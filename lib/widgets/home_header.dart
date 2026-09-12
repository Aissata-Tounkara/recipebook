// En-tête de l'accueil (logo, titre, badge de mode et bouton filtre).

import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF2A93B), Color(0xFFD9662B)],
            ),
          ),
          child: const Icon(
            Icons.restaurant_menu,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 10),
        const Flexible(
          child: Text(
            'RecipeBook',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppPalette.textDark,
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}