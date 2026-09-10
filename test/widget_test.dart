// Tests de l'écran d'accueil de RecipeBook.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:recipebook/main.dart';

void main() {
  testWidgets("L'accueil affiche l'en-tête et les recettes tendance", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RecipeBookApp());
    await tester.pump();

    expect(find.text('RecipeBook'), findsOneWidget);
    expect(find.text('Bonjour ! 👋'), findsOneWidget);
    expect(find.text('Recettes tendance'), findsOneWidget);
    expect(find.text('Poulet rôti aux herbes'), findsOneWidget);
    expect(find.text('Mode local'), findsOneWidget);
  });

  testWidgets('La recherche sans résultat affiche l\'état vide', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RecipeBookApp());
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'zzzzzzzz');
    await tester.pump();

    expect(find.text('Aucune recette trouvée'), findsOneWidget);
    expect(find.text('Poulet rôti aux herbes'), findsNothing);
  });

  testWidgets('Réinitialiser les filtres restaure la liste', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RecipeBookApp());
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'zzzzzzzz');
    await tester.pump();
    expect(find.text('Aucune recette trouvée'), findsOneWidget);

    await tester.ensureVisible(find.text('Réinitialiser les filtres'));
    await tester.tap(find.text('Réinitialiser les filtres'));
    await tester.pumpAndSettle();

    expect(find.text('Poulet rôti aux herbes'), findsOneWidget);
  });
}
