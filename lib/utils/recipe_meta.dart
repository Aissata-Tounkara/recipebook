// ============================================================================
// FICHIER : recipe_meta.dart
// ROLE    : Dériver les informations d'affichage qu'une recette TheMealDB ne
//           fournit pas directement (note, durée, calories, difficulté,
//           description…). Les valeurs sont déterministes : elles ne changent
//           pas entre deux affichages de la même recette.
// ============================================================================

import '../models/recipe.dart';

/// Méta-informations calculées pour l'affichage d'une carte de recette.
class RecipeMeta {
  const RecipeMeta({
    required this.description,
    required this.time,
    required this.kcal,
    required this.rating,
    required this.reviews,
    required this.tag,
    required this.tagIsGreen,
    required this.difficulty,
    required this.chefTip,
  });

  final String description;
  final String time;
  final String kcal;
  final double rating;
  final int reviews;
  final String tag;
  final bool tagIsGreen;
  final String difficulty;
  final String chefTip;

  factory RecipeMeta.from(Recipe recipe) {
    final hash = _stableHash(recipe.id != '' ? recipe.id : recipe.name);

    return RecipeMeta(
      description: _buildDescription(recipe),
      time: '${_pick(hash, 1, 20, 60)} min',
      kcal: '${_pick(hash, 2, 320, 640)} kcal',
      rating: 4.0 + (_pick(hash, 3, 2, 9)) / 10,
      reviews: _pick(hash, 4, 41, 315),
      tag: _buildTag(recipe),
      tagIsGreen: _isGreen(recipe.category, recipe.tags),
      difficulty: _buildDifficulty(recipe, hash),
      chefTip: _buildChefTip(recipe, hash),
    );
  }

  // --------------------------------------------------------------------------
  // Dérivations
  // --------------------------------------------------------------------------

  static String _buildDescription(Recipe recipe) {
    final parts = <String>[];
    if (recipe.area.trim().isNotEmpty) {
      parts.add(recipe.area.trim());
    }
    for (final ingredient in recipe.ingredients.take(3)) {
      if (ingredient.name.trim().isNotEmpty) {
        parts.add(ingredient.name.trim());
      }
    }
    if (parts.isEmpty) return 'Recette authentique';
    return parts.join(' · ');
  }

  static String _buildTag(Recipe recipe) {
    if (_isGreen(recipe.category, recipe.tags)) {
      return 'Végétarien';
    }
    if (recipe.category.trim().isNotEmpty) {
      return _translateCategory(recipe.category);
    }
    return _tagFromTags(recipe.tags);
  }

  static String _tagFromTags(String tags) {
    final parts = tags.split(',');
    var first = '';
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isNotEmpty) {
        first = trimmed;
        break;
      }
    }
    return first.isEmpty ? 'Recette' : first;
  }

  static bool _isGreen(String category, String tags) {
    final c = category.toLowerCase();
    final t = tags.toLowerCase();
    return c.contains('veg') || t.contains('veg') || t.contains('vegan');
  }

  static String _translateCategory(String category) {
    final c = category.toLowerCase();
    if (c.contains('chicken')) return 'Poulet';
    if (c.contains('beef')) return 'Bœuf';
    if (c.contains('seafood') || c.contains('fish')) return 'Poisson';
    if (c.contains('vegetarian') || c.contains('vegan')) return 'Végétarien';
    if (c.contains('dessert')) return 'Dessert';
    if (c.contains('pasta')) return 'Pâtes';
    if (c.contains('breakfast')) return 'Petit-déj';
    return category;
  }

  static String _buildDifficulty(Recipe recipe, int hash) {
    final nb = recipe.ingredients.length;
    if (nb >= 18) return 'Gourmet';
    if (nb >= 10) return 'Confirmé';
    if (nb >= 5) return 'Facile';
    return _pick(hash, 5, 0, 2) == 0 ? 'Facile' : 'Rapide';
  }

  static String _buildChefTip(Recipe recipe, int hash) {
    const tips = [
      'Pour une sauce encore plus veloutée, ajoutez une pincée d\'épices '
          'supplémentaires en début de cuisson.',
      'Laissez reposer quelques minutes avant de servir : les saveurs '
          'n\'en seront que meilleures.',
      'Goûtez et ajustez l\'assaisonnement à mi-cuisson, c\'est là que tout '
          'se joue.',
      'Préparez tous vos ingrédients avant de commencer : la cuisson sera '
          'plus fluide.',
      'Une touche de citron frais en fin de préparation réveille tous les '
          'arômes.',
    ];
    return tips[hash % tips.length];
  }

  static int _stableHash(String input) {
    var hash = 0;
    for (final code in input.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return hash;
  }

  static int _pick(int hash, int salt, int min, int max) =>
      min + ((hash + salt) % (max - min + 1));
}