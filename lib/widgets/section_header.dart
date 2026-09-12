// En-tête de section (« Catégories populaires », « Recettes tendance »…).

import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.badge,
    this.showSeeAll = true,
  });

  final String title;
  final String? badge;
  final bool showSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppPalette.textDark,
            ),
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppPalette.greenBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppPalette.greenText,
              ),
            ),
          ),
        ],
        const Spacer(),
        if (showSeeAll)
          Row(
            children: const [
              Text(
                'Voir tout',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.brown,
                ),
              ),
              SizedBox(width: 2),
              Icon(Icons.arrow_forward, size: 16, color: AppPalette.brown),
            ],
          ),
      ],
    );
  }
}