// Ligne note + catégorie en haut de l'écran de détail.

import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';

class RatingRow extends StatelessWidget {
  const RatingRow({super.key, required this.rating, required this.reviews, required this.category});

  final double rating;
  final int reviews;
  final String category;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppPalette.card,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, size: 15, color: AppPalette.amber),
              const SizedBox(width: 4),
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppPalette.textDark,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '($reviews avis)',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppPalette.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppPalette.peachBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppPalette.peachText,
              ),
            ),
          ),
        ),
      ],
    );
  }
}