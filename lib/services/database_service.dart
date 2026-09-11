// ============================================================================
// FICHIER : database_service.dart
// ROLE    : Sauvegarde locale des recettes favorites (mode hors-ligne).
//           La logique détaillée est documentée dans documentation.md.
// ============================================================================

import 'dart:io';

import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/recipe.dart';

/// Service de gestion des recettes favorites stockées localement.
class DatabaseService {
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
    try {
      final file = await _thumbnailFile(id);
      if (await file.exists()) return file;
    } catch (_) {}
    return null;
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

    final directory =
        _directory ?? (await getApplicationDocumentsDirectory()).path;
    return Hive.openBox<Map>(_boxName, path: directory);
  }

  Future<File> _thumbnailFile(String id) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/$_thumbsFolder');
    return File('${folder.path}/thumb_${Uri.encodeComponent(id)}');
  }

  Future<void> _cacheThumbnail(Recipe recette) async {
    final thumbUrl = recette.thumbnail.trim();
    if (thumbUrl.isEmpty) return;

    try {
      final response = await _client
          .get(Uri.parse(thumbUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 || response.bodyBytes.isEmpty) return;

      final file = await _thumbnailFile(recette.id);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(response.bodyBytes);
    } catch (_) {}
  }

  Future<void> _deleteThumbnail(String id) async {
    try {
      final file = await _thumbnailFile(id);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}