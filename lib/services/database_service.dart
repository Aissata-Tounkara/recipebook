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
  // Noms des anciennes box de cache (utilisés uniquement pour le nettoyage).
  static const String _legacyTrendingBoxName = 'trending_cache';
  static const String _legacyAllRecipesBoxName = 'all_recipes_cache';

  static const String _boxName = 'favorites_recipes';
  static const String _thumbsFolder = 'recipe_thumbs';

  final http.Client _client;

  // Dossier Hive (tests uniquement). En production, on utilise le dossier
  // applicatif renvoyé par path_provider.
  final String? _directory;

  Future<Box<Map>>? _boxFuture;

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

  /// Supprime définitivement les anciennes box de cache (tendance / toutes
  /// les recettes) qui ne sont plus utilisées — Hive ne stocke que les
  /// favoris. Best-effort : échec silencieux si les fichiers n'existent pas.
  static Future<void> deleteLegacyCacheBoxes() async {
    for (final name in const [_legacyTrendingBoxName, _legacyAllRecipesBoxName]) {
      try {
        await Hive.deleteBoxFromDisk(name);
      } catch (_) {}
    }
  }

  void dispose() => _client.close();

  // ==========================================================================
  // PARTIE PRIVÉE
  // ==========================================================================

  Future<Box<Map>> _openBox() {
    return _boxFuture ??= _openBoxOnce();
  }

  Future<Box<Map>> _openBoxOnce() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    }
    return Hive.openBox<Map>(_boxName, path: await _resolveDirectory());
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
          .get(Uri.parse(mealImageVariant(thumbUrl, size: 'medium')))
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