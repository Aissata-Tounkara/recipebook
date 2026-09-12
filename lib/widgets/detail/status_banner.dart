// Bandeau de statut « enregistré en local / mode hors-ligne » du détail.

import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';

class StatusBanner extends StatelessWidget {
  const StatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppPalette.greenBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.save_alt, size: 16, color: AppPalette.greenText),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Enregistré en local (SQLite) • Mode hors-ligne',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppPalette.greenText,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppPalette.greenText,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'ACTIF',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}