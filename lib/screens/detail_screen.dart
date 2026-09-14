import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../services/api_service.dart';
import '../utils/portion_calculator.dart';

// ============================================================================
// Écran qui affiche les détails d'une recette sélectionnée
// ============================================================================
class DetailScreen extends StatefulWidget {
  // Identifiant de la recette transmis depuis la liste
  final String recipeId;

  const DetailScreen({super.key, required this.recipeId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  // Service pour appeler l'API
  final ApiService _api = ApiService();

  // Variables d'état
  Recipe? _recipe;        // Données de la recette reçues de l'API
  bool _isLoading = true; // true = chargement en cours, false = terminé
  int _portions = 4;      // Nombre de portions choisi par l'utilisateur

  @override
  void initState() {
    super.initState();
    // Charge la recette dès l'ouverture de l'écran
    _loadRecipe();
  }

  // Fonction asynchrone qui interroge l'API
  Future<void> _loadRecipe() async {
    final data = await _api.getRecipeById(widget.recipeId);

    // Sécurité : vérifie que l'écran est toujours affiché
    if (!mounted) return;

    // Met à jour l'état avec les données reçues
    setState(() {
      _recipe = data;
      _isLoading = false;
      if (data != null) {
        _portions = data.basePortions; // Initialise avec les portions de base
      }
    });
  }

  @override
  void dispose() {
    _api.dispose(); // Libère les ressources du service API
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Si les données sont en cours de chargement -> affiche un spinner
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détail')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // 2. Si la recette n'a pas pu être chargée -> affiche un bouton pour réessayer
    if (_recipe == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détail')),
        body: Center(
          child: ElevatedButton(
            onPressed: _loadRecipe,
            child: const Text('Réessayer'),
          ),
        ),
      );
    }

    // 3. La recette est chargée avec succès
    final recipe = _recipe!;

    return Scaffold(
      appBar: AppBar(title: Text(recipe.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Photo de la recette
          Image.network(recipe.thumbnail, height: 200, fit: BoxFit.cover),
          const SizedBox(height: 10),

          // Nom de la recette
          Text(
            recipe.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          // Catégorie (ex: Dessert, Vegetarian...)
          if (recipe.category.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(label: Text(recipe.category)),
            ),
          const SizedBox(height: 10),

          // Sélecteur de portions (+ et -)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Portions : ', style: TextStyle(fontSize: 16)),
              // Bouton (-) : désactivé si portions == 1
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: _portions > 1 ? () => setState(() => _portions--) : null,
              ),
              // Affichage du nombre de portions actuel
              Text('$_portions', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              // Bouton (+) : augmente les portions
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => setState(() => _portions++),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Section Ingrédients
          const Text('Ingrédients', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          // On parcourt chaque ingrédient et on adapte sa quantité selon les portions
          ...recipe.ingredients.map((ing) {
            final q = PortionCalculator.scaleMeasure(
              ing.measure,
              basePortions: recipe.basePortions,
              targetPortions: _portions,
            );
            final text = q.isEmpty ? ing.name : '$q ${ing.name}';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('• $text'),
            );
          }),
          const SizedBox(height: 15),

          // Section Instructions de préparation
          const Text('Instructions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          Text(recipe.instructions, style: const TextStyle(height: 1.4)),
        ],
      ),
    );
  }
}