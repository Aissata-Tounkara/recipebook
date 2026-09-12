// Tests de l'écran d'accueil de RecipeBook (données API simulées).

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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
    expect(find.text('Mode local'), findsOneWidget);
    expect(find.text('Chicken Handi'), findsOneWidget);
  });

  testWidgets('La recherche sans résultat affiche l\'état vide', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester);

    await tester.enterText(find.byType(TextField), 'zzzzzzzz');
    await tester.pump();

    expect(find.text('Aucune recette trouvée'), findsOneWidget);
    expect(find.text('Chicken Handi'), findsNothing);
  });

  testWidgets('Réinitialiser les filtres restaure la liste', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester);

    await tester.enterText(find.byType(TextField), 'zzzzzzzz');
    await tester.pump();
    expect(find.text('Aucune recette trouvée'), findsOneWidget);

    await tester.ensureVisible(find.text('Réinitialiser les filtres'));
    await tester.tap(find.text('Réinitialiser les filtres'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Chicken Handi'), findsOneWidget);
  });
}