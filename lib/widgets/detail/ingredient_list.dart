// Liste d'ingrédients en lecture seule, avec miniature et quantités
// recalculées par portions.

import 'package:flutter/material.dart';

import '../../models/recipe.dart';
import '../../theme/app_palette.dart';
import '../../utils/meal_image.dart';
import '../../utils/portion_calculator.dart';

class IngredientList extends StatelessWidget {
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
                  '${ingredients.length} éléments',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.peachText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (ingredients.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'La liste des ingrédients n\'est pas disponible\n'
                'pour cette recette.',
                style: TextStyle(fontSize: 14, color: AppPalette.textMuted),
              ),
            )
          else
            for (var i = 0; i < ingredients.length; i++)
              _ingredientRow(ingredients[i]),
        ],
      ),
    );
  }

  Widget _ingredientRow(Ingredient ingredient) {
    // Quantité recalculée pour le nombre de portions courant.
    final scaled = PortionCalculator.scaleMeasure(
      ingredient.measure,
      basePortions: basePortions,
      targetPortions: portions,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 30,
              height: 30,
              child: _IngredientImage(name: ingredient.name),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              ingredient.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                color: AppPalette.textDark,
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
    );
  }
}

/// Miniature d'un ingrédient TheMealDB, avec repli si l'image manque
/// (hors-ligne, ingrédient inconnu du service…).
class _IngredientImage extends StatelessWidget {
  const _IngredientImage({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final url = ingredientImageUrl(name);
    if (url.isEmpty) return _placeholder(name);

    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) => _placeholder(name),
      errorBuilder: (context, error, stack) => _placeholder(name),
    );
  }

  Widget _placeholder(String ingredient) {
    return Container(
      color: AppPalette.peachBg,
      alignment: Alignment.center,
      child: Text(
        ingredient.isEmpty ? '?' : ingredient.characters.first.toUpperCase(),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppPalette.peachText,
        ),
      ),
    );
  }
}