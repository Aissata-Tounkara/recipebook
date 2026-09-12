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
        const _ModeChip(),
        const SizedBox(width: 8),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppPalette.card,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.tune, color: AppPalette.textDark, size: 20),
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppPalette.greenBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppPalette.greenText,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'Mode local',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppPalette.greenText,
            ),
          ),
        ],
      ),
    );
  }
}