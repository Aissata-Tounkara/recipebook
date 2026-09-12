// Appels à l'API TheMealDB (https://www.themealdb.com/api/json/v1/1/).
//
// Quand l'API ne trouve rien, elle renvoie {"meals": null} avec un code 200 :
// dans ce cas on renvoie une liste vide ou null, on ne lève pas d'erreur.
// On lève une ApiException seulement en cas de vrai problème réseau/serveur.

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/recipe.dart';

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}

class ApiService {
  static const String _baseUrl = 'https://www.themealdb.com/api/json/v1/1';

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  // GET + vérification du code HTTP + décodage JSON.
  Future<Map<String, dynamic>> _getJson(String path) async {
    final url = Uri.parse('$_baseUrl/$path');

    final http.Response response;
    try {
      response = await _client.get(url);
    } catch (e) {
      throw ApiException('Impossible de contacter le serveur ($e)');
    }

    if (response.statusCode != 200) {
      throw ApiException(
        'Le serveur a répondu ${response.statusCode} pour $url',
      );
    }

    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw ApiException('Réponse illisible du serveur ($e)');
    }
  }

  // Recherche par nom : /search.php?s=...
  Future<List<Recipe>> searchRecipesByName(String query) async {
    final data = await _getJson(
      'search.php?s=${Uri.encodeQueryComponent(query)}',
    );

    final meals = data['meals'];
    if (meals == null) return [];

    return (meals as List<dynamic>)
        .map((meal) => Recipe.fromJson(meal as Map<String, dynamic>))
        .toList();
  }

  // Détail par id : /lookup.php?i=...
  Future<Recipe?> getRecipeById(String id) async {
    final data = await _getJson('lookup.php?i=${Uri.encodeQueryComponent(id)}');

    final meals = data['meals'];
    if (meals == null || (meals as List<dynamic>).isEmpty) return null;

    return Recipe.fromJson(meals.first as Map<String, dynamic>);
  }

  // Liste des catégories : /categories.php
  Future<List<String>> getCategories() async {
    final data = await _getJson('categories.php');

    final categories = data['categories'];
    if (categories == null) return [];

    return (categories as List<dynamic>)
        .map(
          (cat) =>
              (cat as Map<String, dynamic>)['strCategory']?.toString() ?? '',
        )
        .where((name) => name.isNotEmpty)
        .toList();
  }

  // Recette au hasard : /random.php
  Future<Recipe?> getRandomRecipe() async {
    final data = await _getJson('random.php');

    final meals = data['meals'];
    if (meals == null || (meals as List<dynamic>).isEmpty) return null;

    return Recipe.fromJson(meals.first as Map<String, dynamic>);
  }

  // Plusieurs recettes au hasard (pour la page d'accueil) : on consulte
  // /random.php plusieurs fois et on dédoublonne par id.
  Future<List<Recipe>> getRandomMeals(int count) async {
    final seen = <String>{};
    final recipes = <Recipe>[];

    final results = await Future.wait([
      for (var i = 0; i < count; i++) _getJson('random.php'),
    ]);

    for (final data in results) {
      final meals = data['meals'];
      if (meals == null || (meals as List<dynamic>).isEmpty) continue;

      final recipe = Recipe.fromJson(meals.first as Map<String, dynamic>);
      if (recipe.id.isNotEmpty && seen.add(recipe.id)) {
        recipes.add(recipe);
      }
    }

    return recipes;
  }

  // Recettes d'une catégorie : /filter.php?c=...
  Future<List<Recipe>> getRecipesByCategory(String category) async {
    final data = await _getJson(
      'filter.php?c=${Uri.encodeQueryComponent(category)}',
    );

    final meals = data['meals'];
    if (meals == null) return [];

    return (meals as List<dynamic>)
        .map((meal) => Recipe.fromJson(meal as Map<String, dynamic>))
        .toList();
  }

  void dispose() => _client.close();
}
