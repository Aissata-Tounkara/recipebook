// Grille d'informations (portions, cuisson, niveau, énergie).

import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';

class InfoGrid extends StatelessWidget {
  const InfoGrid({
    super.key,
    required this.basePortions,
    required this.cookTime,
    required this.difficulty,
    required this.energy,
  });

  final int basePortions;
  final String cookTime;
  final String difficulty;
  final String energy;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.restaurant, 'Base recette', '$basePortions portions'),
      (Icons.schedule, 'Cuisson', cookTime),
      (Icons.signal_cellular_alt, 'Niveau', difficulty),
      (Icons.local_fire_department, 'Énergie', energy),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _InfoTile(items[0])),
            const SizedBox(width: 12),
            Expanded(child: _InfoTile(items[1])),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _InfoTile(items[2])),
            const SizedBox(width: 12),
            Expanded(child: _InfoTile(items[3])),
          ],
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile(this.item);

  final (IconData, String, String) item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppPalette.peachBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.$1, size: 18, color: AppPalette.peachText),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.$2,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppPalette.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.$3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}