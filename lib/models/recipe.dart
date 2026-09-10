// Modèles de données pour RecipeBook.

/// Un ingrédient : son nom et sa quantité.
class Ingredient {
  final String name;
  final String measure;

  const Ingredient({required this.name, required this.measure});

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: (json['name'] ?? '').toString(),
      measure: (json['measure'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'measure': measure};

  @override
  String toString() => measure.isEmpty ? name : '$measure $name';
}

/// Une recette de cuisine.
class Recipe {
  final String id;
  final String name;
  final String category;
  final String instructions;
  final String thumbnail; // URL de l'image
  final List<Ingredient> ingredients;

  // TheMealDB ne donne pas le nombre de portions, on part sur 4 par défaut.
  final int basePortions;

  const Recipe({
    required this.id,
    required this.name,
    required this.category,
    required this.instructions,
    required this.thumbnail,
    required this.ingredients,
    this.basePortions = 4,
  });

  // Parse un "meal" renvoyé par TheMealDB.
  // Les ingrédients arrivent en 20 paires strIngredient1..20 / strMeasure1..20,
  // souvent vides : on ne garde que celles qui ont un nom.
  factory Recipe.fromJson(Map<String, dynamic> json) {
    final ingredients = <Ingredient>[];

    for (var i = 1; i <= 20; i++) {
      final name = (json['strIngredient$i'] ?? '').toString().trim();
      final measure = (json['strMeasure$i'] ?? '').toString().trim();

      if (name.isNotEmpty) {
        ingredients.add(Ingredient(name: name, measure: measure));
      }
    }

    return Recipe(
      id: (json['idMeal'] ?? '').toString(),
      name: (json['strMeal'] ?? '').toString(),
      category: (json['strCategory'] ?? '').toString(),
      instructions: (json['strInstructions'] ?? '').toString(),
      thumbnail: (json['strMealThumb'] ?? '').toString(),
      ingredients: ingredients,
      basePortions: json['basePortions'] is int
          ? json['basePortions'] as int
          : 4,
    );
  }

  // Sérialise toute la recette (pour sauvegarder un favori en local).
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'instructions': instructions,
    'thumbnail': thumbnail,
    'basePortions': basePortions,
    'ingredients': ingredients.map((ing) => ing.toJson()).toList(),
  };

  // Relit une recette sauvegardée localement (format de toJson, pas celui de l'API).
  factory Recipe.fromStoredJson(Map<String, dynamic> json) {
    final rawIngredients = json['ingredients'] as List<dynamic>? ?? [];

    return Recipe(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      instructions: (json['instructions'] ?? '').toString(),
      thumbnail: (json['thumbnail'] ?? '').toString(),
      basePortions: json['basePortions'] is int
          ? json['basePortions'] as int
          : 4,
      ingredients: rawIngredients
          .map((e) => Ingredient.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  @override
  String toString() => 'Recipe($id, $name, ${ingredients.length} ingrédients)';
}
