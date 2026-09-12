// Puce d'une catégorie populaire (barre horizontale de l'accueil).

import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.icon,
    required this.background,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color background;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(24),
          border: selected ? Border.all(color: AppPalette.brown, width: 1.5) : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppPalette.textDark),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppPalette.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}