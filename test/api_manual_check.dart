// Petit script de vérification manuelle du service API.
// A lancer avec : dart run test/api_manual_check.dart
// (pas nommé *_test.dart pour que "flutter test" ne le prenne pas :
//  les tests Flutter bloquent les vrais appels réseau)

// ignore_for_file: avoid_print

import 'package:recipebook/services/api_service.dart';

Future<void> main() async {
  final api = ApiService();

  try {
    print('Recherche de recettes pour "Arrabiata"...\n');
    final results = await api.searchRecipesByName('Arrabiata');

    print('Nombre de résultats trouvés : ${results.length}');

    if (results.isEmpty) {
      print('Aucun résultat.');
      return;
    }

    final first = results.first;
    print('Première recette      : ${first.name}');
    print('Nombre d\'ingrédients  : ${first.ingredients.length}');
    print('Détail des ingrédients :');
    for (final ing in first.ingredients) {
      print('  - $ing');
    }

    if (first.ingredients.isEmpty) {
      print('\nProbleme : la liste d\'ingrédients est vide.');
    } else {
      print('\nOK : parsing des ingrédients fonctionnel.');
    }
  } on ApiException catch (e) {
    print('Erreur API : $e');
  } finally {
    api.dispose();
  }
}
