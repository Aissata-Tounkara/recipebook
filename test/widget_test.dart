// Tests de l'écran d'accueil de RecipeBook (données API simulées).

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:recipebook/screens/home_screen.dart';
import 'package:recipebook/services/api_service.dart';
import 'package:recipebook/services/database_service.dart';
import 'package:recipebook/widgets/bottom_nav_bar.dart';

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

http.Response _json(Object body) => http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json'});

MockClient _mockApi() {
  return MockClient((request) async {
    final path = request.url.path;
    if (path.contains('random.php')) {
      return _json({
        'meals': [_meal],
      });
    }
    if (path.contains('search.php')) {
      final query = request.url.queryParameters['s'] ?? '';
      if (query.toLowerCase().contains('zzzz')) return _json({'meals': null});
      return _json({
        'meals': [_meal],
      });
    }
    if (path.contains('categories.php')) {
      return _json({
        'categories': [
          {'strCategory': 'Chicken'},
        ],
      });
    }
    if (path.contains('filter.php')) {
      return _json({
        'meals': [_meal],
      });
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

  testWidgets("L'accueil affiche l'en-tête et les recettes tendance", (WidgetTester tester) async {
    await pumpHome(tester);

    expect(find.text('RecipeBook'), findsOneWidget);
    expect(find.text('Bonjour !'), findsOneWidget);
    expect(find.text('Recettes tendance'), findsOneWidget);
    // La même recette apparaît dans « Recettes tendance » et dans l'aperçu
    // de « Toutes les recettes ».
    expect(find.text('Chicken Handi'), findsWidgets);
  });

  testWidgets('La recherche sans résultat affiche l\'état vide', (WidgetTester tester) async {
    await pumpHome(tester);

    await tester.enterText(find.byType(TextField), 'zzzzzzzz');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Aucune recette trouvée'), findsOneWidget);
    expect(find.text('Chicken Handi'), findsNothing);
  });

  testWidgets('Réinitialiser les filtres restaure la liste', (WidgetTester tester) async {
    // Surface haute : avec l'en-tête épinglé, l'état vide dépasse l'écran par
    // défaut (600 px) — il faut la place pour atteindre le bouton.
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpHome(tester);

    await tester.enterText(find.byType(TextField), 'zzzzzzzz');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Aucune recette trouvée'), findsOneWidget);

    await tester.tap(find.text('Réinitialiser les filtres'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Chicken Handi'), findsWidgets);
  });

  testWidgets('Sans connexion, l\'accueil affiche l\'état d\'erreur', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          api: ApiService(client: _throwingClient()),
          database: DatabaseService(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // La section « tendance » et la section « toutes les recettes » ont
    // chacune un état d'erreur « Réessayer ».
    expect(find.text("Oups ! Nous n'avons pas pu nous connecter"), findsWidgets);
    expect(find.text('Chicken Handi'), findsNothing);
  });

  testWidgets("La section Toutes les recettes mène à la liste complète", (WidgetTester tester) async {
    // Surface haute : la section « Toutes les recettes » est sous la ligne de
    // flottaison — on étend la vue pour la rendre visible et tappable.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpHome(tester);

    expect(find.text('Toutes les recettes'), findsOneWidget);
    expect(find.text('1 recettes'), findsOneWidget);
    expect(find.text('Voir tout'), findsOneWidget);

    await tester.tap(find.text('Voir tout'));
    await tester.pumpAndSettle();

    // Écran pleine page : la grille complète est affichée (l'accueil,
    // derrière, n'est plus compté).
    expect(find.text('Chicken Handi'), findsOneWidget);
  });

  testWidgets('La recherche et les catégories restent épinglées en haut', (WidgetTester tester) async {
    await pumpHome(tester);

    // Défile d'une bonne hauteur pour dépasser l'en-tête collant.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // La barre de recherche est toujours visible, collée en haut.
    final searchTop = tester.getTopLeft(find.text('Rechercher une recette...'));
    expect(searchTop.dy, lessThan(200));

    // Les puces de catégories populaires restent affichées.
    expect(find.text('Poulet'), findsWidgets);
    expect(find.text('Poisson'), findsOneWidget);
  });

  testWidgets('Sur grand écran, la navigation devient un rail latéral', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpHome(tester);

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(BottomNavBar), findsNothing);
    expect(find.text('Recettes tendance'), findsOneWidget);

    // La marque est portée par le rail, le contenu commence par « Bonjour ».
    expect(find.text('RecipeBook'), findsOneWidget);
    expect(find.text('Bonjour !'), findsOneWidget);

    // Déplié : les libellés des destinations sont visibles.
    expect(find.text('Accueil'), findsOneWidget);
    expect(find.text('Catégories'), findsOneWidget);
    expect(find.text('Favoris'), findsOneWidget);

    // On replie le rail : seules les icônes restent, le contenu est inchangé.
    await tester.tap(find.byIcon(Icons.keyboard_double_arrow_left));
    await tester.pumpAndSettle();

    // Les libellés sont masqués (taille nulle, conservés pour l'accessibilité)
    // et la marque disparaît du rail.
    expect(tester.getSize(find.text('Accueil')).isEmpty, isTrue);
    expect(tester.getSize(find.text('Catégories')).isEmpty, isTrue);
    expect(tester.getSize(find.text('Favoris')).isEmpty, isTrue);
    expect(find.text('RecipeBook'), findsNothing);
    final rail = find.byType(NavigationRail);
    expect(find.descendant(of: rail, matching: find.byIcon(Icons.home)), findsOneWidget);
    expect(find.descendant(of: rail, matching: find.byIcon(Icons.grid_view_outlined)), findsOneWidget);
    expect(find.descendant(of: rail, matching: find.byIcon(Icons.favorite_border)), findsOneWidget);
    expect(find.text('Bonjour !'), findsOneWidget);
    expect(find.text('Recettes tendance'), findsOneWidget);

    // On redéplie : les libellés et la marque reviennent.
    await tester.tap(find.byIcon(Icons.keyboard_double_arrow_right));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.text('Accueil')).isEmpty, isFalse);
    expect(tester.getSize(find.text('RecipeBook')).isEmpty, isFalse);
    expect(find.text('Bonjour !'), findsOneWidget);
  });

  testWidgets('La recette ouverte garde la barre de navigation visible (mobile)', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester);

    // La carte tendance se trouve sous la barre du bas : on remonte un peu.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -120));
    await tester.pump();
    await tester.tap(find.text('Chicken Handi').first);
    await tester.pumpAndSettle();

    // Le détail s'affiche dans la zone de contenu, la barre du bas demeure.
    expect(find.byType(BottomNavBar), findsOneWidget);
    expect(find.text('Chicken Handi'), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('La recette ouverte garde le rail latéral visible (grand écran)', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpHome(tester);

    await tester.tap(find.text('Chicken Handi').first);
    await tester.pumpAndSettle();

    // Le rail reste affiché pendant que le détail se pousse dans le contenu.
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(BottomNavBar), findsNothing);
    expect(find.text('Chicken Handi'), findsOneWidget);
    expect(find.text('Bonjour !'), findsNothing);
  });
}

/// Client qui simule une panne réseau pour tout appel API.
MockClient _throwingClient() => MockClient((_) async => throw http.ClientException('Réseau indisponible'));
