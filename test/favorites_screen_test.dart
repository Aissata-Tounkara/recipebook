// Tests d'affichage de l'écran des favoris.
//
// Les données sont injectées via [FavoritesScreen.loader] pour rester dans un
// environnement de widget test sans E/S réelle (le stockage Hive lui-même est
// déjà couvert par database_service_test).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:recipebook/models/recipe.dart';
import 'package:recipebook/screens/favorites_screen.dart';
import 'package:recipebook/services/api_service.dart';
import 'package:recipebook/services/database_service.dart';

const Recipe _favorite = Recipe(
  id: '52771',
  name: 'Chicken Handi',
  category: 'Chicken',
  instructions: 'Step one.',
  thumbnail: '',
  ingredients: [Ingredient(name: 'Chicken', measure: '500g')],
);

Widget _buildScreen({
  Future<List<Recipe>> Function()? loader,
  required VoidCallback onRemovedSignal,
}) {
  return MaterialApp(
    home: FavoritesScreen(
      database: DatabaseService(),
      api: ApiService(
        client: MockClient((_) async => http.Response('{}', 200)),
      ),
      favorites: const {'52771'},
      onRemoved: (_) => onRemovedSignal(),
      onOpenRecipe: (_) {},
      loader: loader ?? () async => const [_favorite],
    ),
  );
}

void main() {
  testWidgets('Affiche les recettes favorites', (WidgetTester tester) async {
    var removed = false;
    await tester.pumpWidget(_buildScreen(onRemovedSignal: () => removed = true));
    await tester.pump();

    expect(find.text('Mes favoris'), findsOneWidget);
    expect(find.text('Chicken Handi'), findsOneWidget);
    expect(removed, isFalse);
  });

  testWidgets('Retirer un favori vide la liste', (WidgetTester tester) async {
    await tester.pumpWidget(_buildScreen(onRemovedSignal: () {}));
    await tester.pump();

    // Le bouton cœur de la carte retire le favori.
    await tester.tap(find.byIcon(Icons.favorite));
    await tester.pump();

    expect(find.text('Chicken Handi'), findsNothing);
    expect(find.text('Aucun favori pour le moment'), findsOneWidget);
  });

  testWidgets('Affiche l\'état vide quand il n\'y a aucun favori', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildScreen(loader: () async => const [], onRemovedSignal: () {}),
    );
    await tester.pump();

    expect(find.text('Aucun favori pour le moment'), findsOneWidget);
  });
}