// Liste d'ingrédients cochables avec quantités recalculées par portions.

import 'package:flutter/material.dart';

import '../../models/recipe.dart';
import '../../theme/app_palette.dart';
import '../../utils/portion_calculator.dart';

class IngredientList extends StatefulWidget {
  const IngredientList({
    super.key,
    required this.ingredients,
    required this.basePortions,
    required this.portions,
  });

  final List<Ingredient> ingredients;
  final int basePortions;
  final int portions;

  @override
  State<IngredientList> createState() => _IngredientListState();
}

class _IngredientListState extends State<IngredientList> {
  final Set<int> _checked = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              const Flexible(
                child: Text(
                  'Ingrédients',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.textDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppPalette.peachBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.ingredients.length} éléments',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.peachText,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Spacer(),
              const Flexible(
                child: Text(
                  'Cochez au fur et à mesure',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 11.5, color: AppPalette.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (widget.ingredients.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Aucun ingrédient détaillé.',
                style: TextStyle(fontSize: 14, color: AppPalette.textMuted),
              ),
            )
          else
            for (var i = 0; i < widget.ingredients.length; i++)
              _ingredientRow(i, widget.ingredients[i]),
        ],
      ),
    );
  }

  Widget _ingredientRow(int index, Ingredient ingredient) {
    final checked = _checked.contains(index);

    // Quantité recalculée pour le nombre de portions courant.
    final scaled = PortionCalculator.scaleMeasure(
      ingredient.measure,
      basePortions: widget.basePortions,
      targetPortions: widget.portions,
    );

    return InkWell(
      onTap: () {
        setState(() {
          if (checked) {
            _checked.remove(index);
          } else {
            _checked.add(index);
          }
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: checked ? AppPalette.greenText : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: checked ? AppPalette.greenText : const Color(0xFFCFC4B8),
                  width: 1.5,
                ),
              ),
              child: checked
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                ingredient.name,
                style: TextStyle(
                  fontSize: 14,
                  color: checked ? AppPalette.textMuted : AppPalette.textDark,
                  decoration: checked
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppPalette.peachBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                scaled.isEmpty ? '—' : scaled,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.peachText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}