import 'package:flutter_test/flutter_test.dart';
import 'package:recipebook/utils/portion_calculator.dart';

void main() {
  group('PortionCalculator.scaleMeasure', () {
    test('Conserve les chaînes vides ou sans portion modifiée', () {
      expect(
        PortionCalculator.scaleMeasure('', basePortions: 4, targetPortions: 2),
        '',
      );
      expect(
        PortionCalculator.scaleMeasure('200g', basePortions: 4, targetPortions: 4),
        '200g',
      );
    });

    test('Adapte les nombres entiers', () {
      // 4 portions -> 2 portions (ratio 0.5)
      expect(
        PortionCalculator.scaleMeasure('200g', basePortions: 4, targetPortions: 2),
        '100g',
      );
      // 4 portions -> 6 portions (ratio 1.5)
      expect(
        PortionCalculator.scaleMeasure('200 g', basePortions: 4, targetPortions: 6),
        '300 g',
      );
      // 4 portions -> 8 portions (ratio 2)
      expect(
        PortionCalculator.scaleMeasure('2 eggs', basePortions: 4, targetPortions: 8),
        '4 eggs',
      );
    });

    test('Adapte les fractions simples', () {
      // 1/2 tsp * (4 -> 8) => 1 tsp
      expect(
        PortionCalculator.scaleMeasure('1/2 tsp', basePortions: 4, targetPortions: 8),
        '1 tsp',
      );
      // 1/2 tsp * (4 -> 2) => 1/4 tsp
      expect(
        PortionCalculator.scaleMeasure('1/2 tsp', basePortions: 4, targetPortions: 2),
        '1/4 tsp',
      );
      // 1/4 cup * (4 -> 8) => 1/2 cup
      expect(
        PortionCalculator.scaleMeasure('1/4 cup', basePortions: 4, targetPortions: 8),
        '1/2 cup',
      );
    });

    test('Adapte les fractions mixtes', () {
      // 1 1/2 cups * (4 -> 8) => 3 cups
      expect(
        PortionCalculator.scaleMeasure('1 1/2 cups', basePortions: 4, targetPortions: 8),
        '3 cups',
      );
    });

    test('Conserve les mentions textuelles sans quantité numérique', () {
      expect(
        PortionCalculator.scaleMeasure('Pinch', basePortions: 4, targetPortions: 8),
        'Pinch',
      );
      expect(
        PortionCalculator.scaleMeasure('to taste', basePortions: 4, targetPortions: 8),
        'to taste',
      );
    });
  });
}
