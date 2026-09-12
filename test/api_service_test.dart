// Tests du service API : composition de « toutes les recettes » par catégorie.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:recipebook/services/api_service.dart';

http.Response _json(Object body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json'},
);

void main() {
  const Map<String, dynamic> chickenMeal = {
    'idMeal': '52771',
    'strMeal': 'Chicken Handi',
    'strCategory': 'Chicken',
    'strMealThumb': 'https://example.org/chicken.jpg',
  };
  const Map<String, dynamic> beefMeal = {
    'idMeal': '52923',
    'strMeal': 'Beef Wellington',
    'strCategory': 'Beef',
    'strMealThumb': 'https://example.org/beef.jpg',
  };

  ApiService serviceWith({bool breakChicken = false, bool beefHasDup = false}) {
    return ApiService(
      client: MockClient((request) async {
        final category = request.url.queryParameters['c'] ?? '';
        if (breakChicken && category == 'Chicken') {
          throw (http.ClientException('Réseau indisponible'));
        }
        if (category == 'Chicken') {
          return _json({
            'meals': [chickenMeal],
          });
        }
        if (category == 'Beef') {
          return _json({
            'meals': [
              beefMeal,
              if (beefHasDup) chickenMeal, // doublon volontaire
            ],
          });
        }
        return _json({'meals': null});
      }),
    );
  }

  test('getRecipesByCategories fusionne et dédoublonne par id', () async {
    final service = serviceWith(beefHasDup: true);
    final recipes = await service.getRecipesByCategories(['Chicken', 'Beef']);

    expect(recipes.map((r) => r.id), ['52771', '52923']);
    expect(recipes.map((r) => r.name).toSet(), {'Chicken Handi', 'Beef Wellington'});
  });

  test('getRecipesByCategories tolère une catégorie en erreur', () async {
    final service = serviceWith(breakChicken: true);
    final recipes = await service.getRecipesByCategories(['Chicken', 'Beef']);

    // La catégorie en panne est ignorée, le reste est conservé.
    expect(recipes.map((r) => r.id), ['52923']);
  });
}