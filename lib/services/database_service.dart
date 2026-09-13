// ============================================================================
// FICHIER : database_service.dart
// ROLE    : Sauvegarde locale des recettes favorites (mode hors-ligne).
//           La logique détaillée est documentée dans documentation.md.
// ============================================================================

import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/recipe.dart';
import '../utils/meal_image.dart';

/// Service de gestion des recettes favorites stockées localement.
class DatabaseService {
  static const String _boxName = 'favorites_recipes';
  static const String _thumbsFolder = 'recipe_thumbs';
  static const String _trendingBoxName = 'trending_cache';
  static const String _trendingKey = 'trending';
  static const String _trendingSavedAtKey = 'savedAt';
  static const String _trendingMealsKey = 'meals';
  static const String _allRecipesBoxName = 'all_recipes_cache';
  static const String _allRecipesKey = 'all';

  /// Durée de validité de la liste « tendance » mise en cache.
  static const Duration trendingCacheDuration = Duration(hours: 24);

  /// Durée de validité de la liste « toutes les recettes » mise en cache.
  static const Duration allRecipesCacheDuration = Duration(hours: 24);

  /// Délai maximal d'ouverture de la box de cache : le stockage ne doit
  /// jamais bloquer l'affichage (défensif, utile dans les tests aussi).
  static const Duration _cacheOpenTimeout = Duration(milliseconds: 250);

  final http.Client _client;

  // Dossier Hive (tests uniquement). En production, on utilise le dossier
  // applicatif renvoyé par path_provider.
  final String? _directory;

  Future<Box<Map>>? _boxFuture;
  Future<Box<Map>>? _trendingBoxFuture;
  Future<Box<Map>>? _allRecipesBoxFuture;

  DatabaseService({http.Client? client, String? directory})
      : _client = client ?? http.Client(),
        _directory = directory;

  Future<List<Recipe>> getAllFavorites() async {
    final box = await _openBox();
    final favorites = <Recipe>[];

    for (final value in box.values) {
      try {
        favorites.add(
            Recipe.fromStoredJson(Map<String, dynamic>.from(value)));
      } catch (_) {}
    }
    return favorites;
  }

  Future<bool> isFavorite(String id) async {
    final box = await _openBox();
    return box.containsKey(id);
  }

  Future<void> addFavorite(Recipe recette) async {
    final box = await _openBox();
    if (box.containsKey(recette.id)) return;

    await box.put(recette.id, recette.toJson());
    await _cacheThumbnail(recette);
  }

  Future<void> removeFavorite(String id) async {
    final box = await _openBox();
    await box.delete(id);
    await _deleteThumbnail(id);
  }

  Future<File?> getFavoriteThumbFile(String id) async {
    if (kIsWeb) return null; // Pas de système de fichiers sur le web.
    try {
      final file = await _thumbnailFile(id);
      if (await file.exists()) return file;
    } catch (_) {}
    return null;
  }

  // --------------------------------------------------------------------------
  // Cache des recettes « tendance » (limite l'appel répété à /random.php).
  // --------------------------------------------------------------------------

  /// Lit la liste « tendance » mise en cache. Renvoie null si aucun cache
  /// (ou s'il est illisible), accompagné de sa date d'enregistrement.
  Future<({List<Recipe> recipes, DateTime savedAt})?> getTrendingCache() {
    return _readTrendingCache().timeout(
      _cacheOpenTimeout,
      onTimeout: () => null,
    );
  }

  Future<({List<Recipe> recipes, DateTime savedAt})?> _readTrendingCache() async {
    try {
      final box = await _openTrendingBox();
      final value = box.get(_trendingKey);
      if (value == null) return null;

      final savedAtMs = value[_trendingSavedAtKey] as int?;
      final meals = value[_trendingMealsKey] as List?;
      if (savedAtMs == null || meals == null) return null;

      final recipes = <Recipe>[];
      for (final meal in meals) {
        try {
          recipes.add(
            Recipe.fromStoredJson(Map<String, dynamic>.from(meal as Map)),
          );
        } catch (_) {}
      }
      if (recipes.isEmpty) return null;

      return (
        recipes: recipes,
        savedAt: DateTime.fromMillisecondsSinceEpoch(savedAtMs),
      );
    } catch (_) {
      return null;
    }
  }

  /// Enregistre la liste « tendance » avec son horodatage (best-effort).
  Future<void> saveTrendingCache(List<Recipe> recipes) async {
    if (recipes.isEmpty) return;
    try {
      final box = await _openTrendingBox().timeout(_cacheOpenTimeout);
      await box.put(_trendingKey, {
        _trendingSavedAtKey: DateTime.now().millisecondsSinceEpoch,
        _trendingMealsKey: recipes.map((recipe) => recipe.toJson()).toList(),
      });
    } catch (_) {}
  }

  // --------------------------------------------------------------------------
  // Cache de « toutes les recettes » (composition par catégorie).
  // --------------------------------------------------------------------------

  /// Lit la liste complète mise en cache, avec sa date d'enregistrement.
  /// Renvoie null si aucun cache exploitable (ou délai dépassé).
  Future<({List<Recipe> recipes, DateTime savedAt})?> getAllRecipesCache() {
    return _readAllRecipesCache().timeout(
      _cacheOpenTimeout,
      onTimeout: () => null,
    );
  }

  Future<({List<Recipe> recipes, DateTime savedAt})?> _readAllRecipesCache() async {
    try {
      final box = await _openAllRecipesBox();
      final value = box.get(_allRecipesKey);
      if (value == null) return null;

      final savedAtMs = value[_trendingSavedAtKey] as int?;
      final meals = value[_trendingMealsKey] as List?;
      if (savedAtMs == null || meals == null) return null;

      final recipes = <Recipe>[];
      for (final meal in meals) {
        try {
          recipes.add(
            Recipe.fromStoredJson(Map<String, dynamic>.from(meal as Map)),
          );
        } catch (_) {}
      }
      if (recipes.isEmpty) return null;

      return (
        recipes: recipes,
        savedAt: DateTime.fromMillisecondsSinceEpoch(savedAtMs),
      );
    } catch (_) {
      return null;
    }
  }

  /// Enregistre la liste complète avec son horodatage (best-effort).
  Future<void> saveAllRecipesCache(List<Recipe> recipes) async {
    if (recipes.isEmpty) return;
    try {
      final box = await _openAllRecipesBox().timeout(_cacheOpenTimeout);
      await box.put(_allRecipesKey, {
        _trendingSavedAtKey: DateTime.now().millisecondsSinceEpoch,
        _trendingMealsKey: recipes.map((recipe) => recipe.toJson()).toList(),
      });
    } catch (_) {}
  }

  void dispose() => _client.close();

  // ==========================================================================
  // PARTIE PRIVÉE
  // ==========================================================================

  Future<Box<Map>> _openBox() {
    return _boxFuture ??= _openBoxOnce();
  }

  Future<Box<Map>> _openTrendingBox() {
    return _trendingBoxFuture ??= _openTrendingBoxOnce();
  }

  Future<Box<Map>> _openAllRecipesBox() {
    return _allRecipesBoxFuture ??= _openAllRecipesBoxOnce();
  }

  Future<Box<Map>> _openBoxOnce() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    }
    return Hive.openBox<Map>(_boxName, path: await _resolveDirectory());
  }

  Future<Box<Map>> _openTrendingBoxOnce() async {
    if (Hive.isBoxOpen(_trendingBoxName)) {
      return Hive.box(_trendingBoxName);
    }
    return Hive.openBox<Map>(_trendingBoxName, path: await _resolveDirectory());
  }

  Future<Box<Map>> _openAllRecipesBoxOnce() async {
    if (Hive.isBoxOpen(_allRecipesBoxName)) {
      return Hive.box(_allRecipesBoxName);
    }
    return Hive.openBox<Map>(
      _allRecipesBoxName,
      path: await _resolveDirectory(),
    );
  }

  // Dossier de stockage des box Hive. `_directory` (tests) est prioritaire ;
  // sur le web, path_provider n'est pas supporté et Hive.initFlutter() (voir
  // main.dart) prend en charge le stockage IndexedDB sans chemin explicite.
  Future<String?> _resolveDirectory() async {
    if (_directory != null) return _directory;
    if (kIsWeb) return null;
    return (await getApplicationDocumentsDirectory()).path;
  }

  Future<File> _thumbnailFile(String id) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/$_thumbsFolder');
    return File('${folder.path}/thumb_${Uri.encodeComponent(id)}');
  }

  Future<void> _cacheThumbnail(Recipe recette) async {
    if (kIsWeb) return; // Pas de système de fichiers sur le web.
    final thumbUrl = recette.thumbnail.trim();
    if (thumbUrl.isEmpty) return;

    try {
      final response = await _client
          .get(Uri.parse(mealImageVariant(thumbUrl, size: 'small')))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 || response.bodyBytes.isEmpty) return;

      final file = await _thumbnailFile(recette.id);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(response.bodyBytes);
    } catch (_) {}
  }

  Future<void> _deleteThumbnail(String id) async {
    if (kIsWeb) return; // Pas de système de fichiers sur le web.
    try {
      final file = await _thumbnailFile(id);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}