// ============================================================================
// FICHIER : database_service_test.dart
// ROLE    : Tests unitaires du service de favoris (DatabaseService).
// ============================================================================

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:recipebook/models/recipe.dart';
import 'package:recipebook/services/database_service.dart';

void main() {
  // Dossier temporaire pour stocker la box Hive et les miniatures de test.
  late Directory tempDir;

  // Valeur par défaut de la plateforme pour la restaurer entre les tests.
  final originalPathProvider = PathProviderPlatform.instance;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('db_service_test');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
    PathProviderPlatform.instance = originalPathProvider;
  });

  // Client par défaut : échec de toute image (aucune miniature ne s'écrit).
  DatabaseService serviceWithoutImage() {
    return DatabaseService(
      directory: tempDir.path,
      client: MockClient((request) async => http.Response('Not Found', 404)),
    );
  }

  // Client renvoyant les octets d'une fausse image.
  DatabaseService serviceWithImage() {
    return DatabaseService(
      directory: tempDir.path,
      client: MockClient((request) async {
        if (request.url.path.contains('.jpg')) {
          return http.Response.bytes([1, 2, 3, 4], 200);
        }
        return http.Response('Not Found', 404);
      }),
    );
  }

  // Client qui échoue sur tout téléchargement d'image.
  DatabaseService serviceWithBrokenImage() {
    return DatabaseService(
      directory: tempDir.path,
      client: MockClient((request) async => http.Response('Error', 500)),
    );
  }

  group('Tests du service de favoris', () {
    group('Gestion des recettes', () {
      test('1. Ajoute un favori et le relit : round-trip complet', () async {
        final db = serviceWithImage();

        await db.addFavorite(_mockRecipe('52771', name: 'Spicy Arrabiata Penne'));

        final favorites = await db.getAllFavorites();
        expect(favorites, hasLength(1));

        final saved = favorites.first;
        expect(saved.id, '52771');
        expect(saved.name, 'Spicy Arrabiata Penne');
        expect(saved.category, 'Vegetarian');
        expect(saved.basePortions, 4);
        expect(saved.thumbnail, 'https://images.test/meals/52771.jpg');
        expect(saved.instructions, 'Cuire les pâtes et mélanger la sauce.');
        expect(saved.ingredients, hasLength(2));
        expect(saved.ingredients.first.name, 'penne rigate');
        expect(saved.ingredients.first.measure, '200g');
      });

      test('2. Ne crée pas de doublon quand le même favori est ajouté deux fois',
          () async {
        final db = serviceWithoutImage();

        final recipe = _mockRecipe('52771');
        await db.addFavorite(recipe);
        await db.addFavorite(recipe);

        expect(await db.getAllFavorites(), hasLength(1));
      });

      test('3. Conserve plusieurs favoris distincts', () async {
        final db = serviceWithoutImage();

        await db.addFavorite(_mockRecipe('52771'));
        await db.addFavorite(_mockRecipe('52802', name: 'Fish pie'));

        final favorites = await db.getAllFavorites();
        expect(favorites, hasLength(2));
        expect(favorites.map((recipe) => recipe.id).toSet(),
            {'52771', '52802'});
      });

      test('4. Retire uniquement le favori ciblé', () async {
        final db = serviceWithoutImage();

        await db.addFavorite(_mockRecipe('52771'));
        await db.addFavorite(_mockRecipe('52802', name: 'Fish pie'));

        await db.removeFavorite('52771');

        final favorites = await db.getAllFavorites();
        expect(favorites, hasLength(1));
        expect(favorites.first.id, '52802');
      });

      test('5. Retirer un id inconnu ne modifie pas la liste', () async {
        final db = serviceWithoutImage();

        await db.addFavorite(_mockRecipe('52771'));
        await db.removeFavorite('99999');

        expect(await db.getAllFavorites(), hasLength(1));
      });

      test('6. Renvoie une liste vide quand aucun favori n\'est stocké',
          () async {
        final db = serviceWithoutImage();
        expect(await db.getAllFavorites(), isEmpty);
      });

      test('7. Ignore les valeurs malformées dans la box', () async {
        // On injecte directement dans la box une entrée valide et une invalide.
        final seed = await Hive.openBox<Map>('favorites_recipes',
            path: tempDir.path);
        await seed.put('good', _mockRecipe('52771').toJson());
        await seed.put('bad', {'id': 'x', 'ingredients': 'cassé'});
        await seed.close();

        final db = serviceWithoutImage();
        final favorites = await db.getAllFavorites();

        expect(favorites, hasLength(1));
        expect(favorites.first.id, '52771');
      });

      test('8. isFavorite retourne le bon statut', () async {
        final db = serviceWithoutImage();

        expect(await db.isFavorite('52771'), isFalse);

        await db.addFavorite(_mockRecipe('52771'));
        expect(await db.isFavorite('52771'), isTrue);
        expect(await db.isFavorite('52802'), isFalse);
      });

      test('9. Un autre service relit les mêmes favoris', () async {
        final writer = serviceWithoutImage();
        await writer.addFavorite(_mockRecipe('52771'));

        final reader = serviceWithoutImage();
        final favorites = await reader.getAllFavorites();

        expect(favorites, hasLength(1));
        expect(favorites.first.id, '52771');
      });
    });

    group('Cache des miniatures hors-ligne', () {
      test('10. Télécharge la miniature du favori et l\'écrit sur disque',
          () async {
        final db = serviceWithImage();

        await db.addFavorite(_mockRecipe('52771'));

        final file = await db.getFavoriteThumbFile('52771');
        expect(file, isNotNull);

        expect(file!.path, contains('recipe_thumbs'));

        final bytes = await file.readAsBytes();
        expect(bytes, [1, 2, 3, 4]);
      });

      test('11. Un échec de téléchargement ne bloque pas la sauvegarde',
          () async {
        final db = serviceWithBrokenImage();

        await db.addFavorite(_mockRecipe('52771'));

        expect(await db.getAllFavorites(), hasLength(1));
        expect(await db.getFavoriteThumbFile('52771'), isNull);
      });

      test('12. Retire le fichier miniature en même temps que le favori',
          () async {
        final db = serviceWithImage();

        await db.addFavorite(_mockRecipe('52771'));
        expect(await db.getFavoriteThumbFile('52771'), isNotNull);

        await db.removeFavorite('52771');

        expect(await db.getAllFavorites(), isEmpty);
        expect(await db.getFavoriteThumbFile('52771'), isNull);
      });

      test('13. Chaque favori possède sa propre miniature', () async {
        final db = serviceWithImage();

        await db.addFavorite(_mockRecipe('52771'));
        expect(await db.getFavoriteThumbFile('52802'), isNull);
      });
    });
  });
}

// ============================================================================
// DONNÉES FACTICES
// ============================================================================

/// Construit une recette de test complète.
Recipe _mockRecipe(String id, {String name = 'Spicy Arrabiata Penne'}) {
  return Recipe(
    id: id,
    name: name,
    category: 'Vegetarian',
    instructions: 'Cuire les pâtes et mélanger la sauce.',
    thumbnail: 'https://images.test/meals/$id.jpg',
    ingredients: const [
      Ingredient(name: 'penne rigate', measure: '200g'),
      Ingredient(name: 'garlic', measure: '3 cloves'),
    ],
  );
}

/// Stub de [PathProviderPlatform] qui renvoie le dossier temporaire au lieu
/// du canal natif (indisponible dans les tests Dart pures).
class _FakePathProvider extends PathProviderPlatform {
  final String documentsPath;

  _FakePathProvider(this.documentsPath);

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}