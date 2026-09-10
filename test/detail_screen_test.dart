// Tests de l'écran de détail : ajusteur de portions et cases à cocher.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:recipebook/screens/detail_screen.dart';

void main() {
  testWidgets('Affiche la recette et les quantités de base (4 pers.)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DetailScreen()));
    await tester.pump();

    expect(find.text('Poulet au curry & lait de coco parfumé'), findsOneWidget);
    expect(find.text('600 g'), findsOneWidget); // poulet, base 4 pers.
    expect(find.text('400 ml'), findsOneWidget); // lait de coco
  });

  testWidgets('Le + recalcule les quantités (règle de trois)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DetailScreen()));
    await tester.pump();

    // 4 -> 6 personnes via le préréglage.
    await tester.ensureVisible(find.text('6'));
    await tester.tap(find.text('6'));
    await tester.pump();

    // 600 g * 6/4 = 900 g ; 400 ml * 6/4 = 600 ml.
    expect(find.text('900 g'), findsOneWidget);
    expect(find.text('600 ml'), findsOneWidget);
    expect(find.text('600 g'), findsNothing);
  });

  testWidgets('Cocher un ingrédient le marque comme fait', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DetailScreen()));
    await tester.pump();

    final ingredient = find.text('Riz basmati parfumé');
    expect(ingredient, findsOneWidget);

    await tester.ensureVisible(ingredient);
    await tester.tap(ingredient);
    await tester.pump();

    final textWidget = tester.widget<Text>(ingredient);
    expect(textWidget.style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets('Le badge convives suit le nombre de portions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DetailScreen()));
    await tester.pump();

    expect(find.text('Affichage : 4 convives'), findsOneWidget);

    await tester.ensureVisible(find.text('8'));
    await tester.tap(find.text('8'));
    await tester.pump();

    expect(find.text('Affichage : 8 convives'), findsOneWidget);
  });
}
