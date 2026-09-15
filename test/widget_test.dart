// Tests de l'écran d'accueil de RecipeBook (données API simulées).

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:recipebook/models/recipe.dart';
import 'package:recipebook/screens/home_screen.dart';
import 'package:recipebook/services/api_service.dart';
import 'package:recipebook/services/database_service.dart';

const Map<String, dynamic> _meal = {
  'idMeal': '52771',
  'strMeal': 'Chicken Handi',
  'strCategory': 'Chicken',
  'strArea': 'Indian',
  'strInstructions': 'Step one.\nStep two.',
  'strMealThumb': '',
  'strIngredient1': 'Chicken',
  'strMeasure1': '500g',
  'strIngredient2': '',
  'strMeasure2': '',
};

http.Response _json(Object body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json'},
);

MockClient _mockApi() {
  return MockClient((request) async {
    final path = request.url.path;
    if (path.contains('random.php')) {
      return _json({'meals': [_meal]});
    }
    if (path.contains('search.php')) {
      final query = request.url.queryParameters['s'] ?? '';
      if (query.toLowerCase().contains('zzzz')) return _json({'meals': null});
      return _json({'meals': [_meal]});
    }
    if (path.contains('categories.php')) {
      return _json({
        'categories': [
          {'strCategory': 'Chicken'},
        ],
      });
    }
    if (path.contains('filter.php')) {
      return _json({'meals': [_meal]});
    }
    return _json({'meals': null});
  });
}

void main() {
  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          api: ApiService(client: _mockApi()),
          // Sans dossier : path_provider échoue vite en test et le favori vide
          // est rattrapé par DatabaseService.
          database: DatabaseService(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets("L'accueil affiche l'en-tête et les recettes tendance", (
    WidgetTester tester,
  ) async {
    await pumpHome(tester);

    expect(find.text('RecipeBook'), findsOneWidget);
    expect(find.text('Bonjour ! 👋'), findsOneWidget);
    expect(find.text('Recettes tendance'), findsOneWidget);
    // La même recette apparaît dans « Recettes tendance » et dans l'aperçu
    // de « Toutes les recettes ».
    expect(find.text('Chicken Handi'), findsWidgets);
  });

  testWidgets('La recherche sans résultat affiche l\'état vide', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester);

    await tester.enterText(find.byType(TextField), 'zzzzzzzz');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Aucune recette trouvée'), findsOneWidget);
    expect(find.text('Chicken Handi'), findsNothing);
  });

  testWidgets('Réinitialiser les filtres restaure la liste', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester);

    await tester.enterText(find.byType(TextField), 'zzzzzzzz');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Aucune recette trouvée'), findsOneWidget);

    await tester.ensureVisible(find.text('Réinitialiser les filtres'));
    await tester.tap(find.text('Réinitialiser les filtres'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Chicken Handi'), findsWidgets);
  });

  testWidgets('Un cache récent évite l\'appel API', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          api: ApiService(client: _throwingClient()),
          database: _FakeDatabase(
            cached: (recipes: [Recipe.fromJson(_meal)], savedAt: DateTime.now()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Chicken Handi'), findsOneWidget);
    expect(
      find.text('Connexion indisponible — recettes chargées précédemment.'),
      findsNothing,
    );
  });

  testWidgets('Sans connexion, les recettes en cache tombent en secours', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          api: ApiService(client: _throwingClient()),
          database: _FakeDatabase(
            cached: (
              recipes: [Recipe.fromJson(_meal)],
              savedAt: DateTime.now().subtract(const Duration(days: 2)),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Chicken Handi'), findsOneWidget);
    expect(
      find.text('Connexion indisponible — recettes chargées précédemment.'),
      findsOneWidget,
    );
    expect(find.text('Aucune recette trouvée'), findsNothing);
  });

  testWidgets("La section Toutes les recettes mène à la liste complète", (
    WidgetTester tester,
  ) async {
    await pumpHome(tester);

    expect(find.text('Toutes les recettes'), findsOneWidget);
    expect(find.text('1 recettes'), findsOneWidget);
    expect(find.text('Voir tout'), findsOneWidget);

    await tester.ensureVisible(find.text('Voir tout'));
    await tester.tap(find.text('Voir tout'));
    await tester.pumpAndSettle();

    // Écran pleine page : la grille complète est affichée (l'accueil,
    // derrière, n'est plus compté).
    expect(find.text('Chicken Handi'), findsOneWidget);
  });

  testWidgets('Toutes les recettes retombe sur le cache hors-ligne', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          api: ApiService(client: _throwingClient()),
          database: _FakeDatabase(
            cached: (
              recipes: [Recipe.fromJson(_meal)],
              savedAt: DateTime.now().subtract(const Duration(days: 2)),
            ),
            allCached: (
              recipes: [Recipe.fromJson(_meal)],
              savedAt: DateTime.now().subtract(const Duration(days: 2)),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Toutes les recettes'), findsOneWidget);
    expect(find.text('1 recettes'), findsOneWidget);
  });
}

/// Client qui simule une panne réseau pour tout appel API.
MockClient _throwingClient() =>
    MockClient((_) async => throw http.ClientException('Réseau indisponible'));

/// Base de données de test : caches contrôlés, pas d'E/S réelle.
class _FakeDatabase extends DatabaseService {
  _FakeDatabase({required this.cached, this.allCached})
      : super(
          directory: Directory.systemTemp.createTempSync('fake_db').path,
          client: MockClient(
            (_) async => throw http.ClientException('Réseau indisponible'),
          ),
        );

  final ({List<Recipe> recipes, DateTime savedAt})? cached;
  final ({List<Recipe> recipes, DateTime savedAt})? allCached;

  @override
  Future<({List<Recipe> recipes, DateTime savedAt})?> getTrendingCache() async =>
      cached;

  @override
  Future<void> saveTrendingCache(List<Recipe> recipes) async {}

  @override
  Future<({List<Recipe> recipes, DateTime savedAt})?> getAllRecipesCache() async =>
      allCached;

  @override
  Future<void> saveAllRecipesCache(List<Recipe> recipes) async {}
}