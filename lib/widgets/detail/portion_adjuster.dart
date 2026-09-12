// Ajusteur de portions dynamique (règle de trois en temps réel).

import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';

class PortionAdjuster extends StatelessWidget {
  const PortionAdjuster({
    super.key,
    required this.portions,
    required this.basePortions,
    required this.onChanged,
  });

  final int portions;
  final int basePortions;
  final ValueChanged<int> onChanged;

  static const List<int> _presets = [2, 4, 6, 8];

  void _setPortions(int value) {
    onChanged(value.clamp(1, 20));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppPalette.peachBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tune,
                  size: 18,
                  color: AppPalette.peachText,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nombre de portions',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppPalette.textDark,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Les quantités s\'ajustent automatiquement',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppPalette.greenBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Recette pour $portions personnes',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppPalette.greenText,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _stepperButton(Icons.remove, () => _setPortions(portions - 1)),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$portions',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: AppPalette.brown,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'pers.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppPalette.textDark,
                      ),
                    ),
                    const Text(
                      'personnes',
                      style: TextStyle(fontSize: 12, color: AppPalette.textMuted),
                    ),
                  ],
                ),
              ),
              _stepperButton(Icons.add, () => _setPortions(portions + 1)),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Préréglages rapides :',
            style: TextStyle(fontSize: 12.5, color: AppPalette.textMuted),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < _presets.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: _presetChip(_presets[i])),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppPalette.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.sync, size: 16, color: AppPalette.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Les quantités ci-dessous se recalculent automatiquement'
                  ' selon le nombre de personnes choisi.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppPalette.textMuted,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepperButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppPalette.peachBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: AppPalette.brown, size: 26),
      ),
    );
  }

  Widget _presetChip(int value) {
    final selected = portions == value;
    final isDefault = value == basePortions;
    return GestureDetector(
      onTap: () => _setPortions(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppPalette.greenText : AppPalette.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppPalette.greenText : AppPalette.thinBorder,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : AppPalette.textDark,
              ),
            ),
            Text(
              isDefault ? 'pers.\n(défaut)' : 'pers.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                height: 1.1,
                color: selected ? Colors.white : AppPalette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}