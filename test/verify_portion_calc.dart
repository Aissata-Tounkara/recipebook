// ignore_for_file: avoid_print

import 'dart:io';
import 'package:recipebook/utils/portion_calculator.dart';

void main() {
  final cases = [
    // [measure, base, target, expected]
    ['200g', 4, 2, '100g'],
    ['200 g', 4, 6, '300 g'],
    ['2 eggs', 4, 8, '4 eggs'],
    ['1/2 tsp', 4, 8, '1 tsp'],
    ['1/2 tsp', 4, 2, '1/4 tsp'],
    ['1/4 cup', 4, 8, '1/2 cup'],
    ['1 1/2 cups', 4, 8, '3 cups'],
    ['Pinch', 4, 8, 'Pinch'],
    ['to taste', 4, 8, 'to taste'],
    ['', 4, 2, ''],
    ['100g', 4, 4, '100g'],
  ];

  int passed = 0;
  for (final c in cases) {
    final measure = c[0] as String;
    final base = c[1] as int;
    final target = c[2] as int;
    final expected = c[3] as String;

    final actual = PortionCalculator.scaleMeasure(
      measure,
      basePortions: base,
      targetPortions: target,
    );

    if (actual == expected) {
      print('PASS: "$measure" ($base->$target) => "$actual"');
      passed++;
    } else {
      print('FAIL: "$measure" ($base->$target) => Actual: "$actual", Expected: "$expected"');
      exitCode = 1;
    }
  }

  print('\nResults: $passed / ${cases.length} passed.');
}
