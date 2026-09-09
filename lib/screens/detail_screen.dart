// ============================================================================
// FICHIER : detail_screen.dart
// ROLE    : Écran de consultation détaillée d'une recette avec ajustement
//           dynamique des portions et mise en page responsive (mobile / tablette).
// ============================================================================

import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../services/api_service.dart';
import '../utils/portion_calculator.dart';

/// Écran d'affichage du détail d'une recette.
/// 
/// C'est un [StatefulWidget] car l'écran gère plusieurs états locaux :
/// 1. Le chargement asynchrone des données depuis l'API (_isLoading).
/// 2. La gestion des erreurs réseau éventuelles (_errorMessage).
/// 3. L'ajustement interactif du nombre de portions (_portions).
class DetailScreen extends StatefulWidget {
  // Identifiant unique (idMeal) de la recette à charger.
  final String recipeId;

  const DetailScreen({
    super.key,
    required this.recipeId,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  // Service responsable des requêtes HTTP vers l'API TheMealDB.
  final ApiService _apiService = ApiService();

  // Données de la recette une fois chargée avec succès depuis l'API.
  Recipe? _recipe;

  // Booléen pour afficher l'indicateur de chargement (CircularProgressIndicator).
  bool _isLoading = true;

  // Message d'erreur textuel si la requête échoue.
  String? _errorMessage;

  // Nombre de portions choisi par l'utilisateur (initialisé avec la valeur de base).
  int _portions = 4;

  @override
  void initState() {
    super.initState();

    // Au premier affichage de l'écran, on lance le chargement de la recette.
    _loadRecipe();
  }

  /// Récupère la recette depuis l'API via son identifiant.
  Future<void> _loadRecipe() async {
    // ÉTAPE 1 : Réinitialisation de l'état
    // Si l'utilisateur clique sur "Réessayer", on remet l'état en chargement
    // et on efface l'ancien message d'erreur pour réafficher le spinner.
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // ÉTAPE 2 : Appel asynchrone à l'API TheMealDB
      final recipe = await _apiService.getRecipeById(widget.recipeId);

      // ÉTAPE 3 : Vérification du montage du Widget
      // Si l'utilisateur a quitté l'écran avant la fin de la requête,
      // on n'appelle pas setState() pour éviter une exception Flutter.
      if (!mounted) return;

      setState(() {
        _recipe = recipe;
        _isLoading = false;

        // On initialise le nombre de portions avec la valeur par défaut de la recette
        // (généralement 4 portions).
        _portions = recipe?.basePortions ?? 4;
      });
    } catch (e) {
      if (!mounted) return;

      // En cas d'exception (ex: absence de connexion Internet),
      // on met fin au chargement et on enregistre l'erreur à afficher.
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  void dispose() {
    // Bonne pratique : on libère les ressources et connexions HTTP ouvertes.
    _apiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ------------------------------------------------------------------------
    // CAS 1 : Écran de chargement en cours
    // ------------------------------------------------------------------------
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Détail de la recette'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // ------------------------------------------------------------------------
    // CAS 2 : Écran d'erreur avec possibilité de réessayer
    // ------------------------------------------------------------------------
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Détail de la recette'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _loadRecipe,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ------------------------------------------------------------------------
    // CAS 3 : Recette introuvable dans la base de données
    // ------------------------------------------------------------------------
    if (_recipe == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Détail de la recette'),
        ),
        body: const Center(
          child: Text('Recette introuvable.'),
        ),
      );
    }

    // ------------------------------------------------------------------------
    // CAS 4 : Affichage complet de la recette
    // ------------------------------------------------------------------------
    final recipe = _recipe!;

    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.name),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Sur grand écran / tablette, on limite la largeur maximale à 900px
          // pour éviter que le texte et les cartes ne soient trop étirés.
          final contentWidth =
              constraints.maxWidth > 900 ? 900.0 : constraints.maxWidth;

          return Center(
            child: SizedBox(
              width: contentWidth,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildContent(recipe, constraints.maxWidth),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Construit l'ensemble du contenu de la recette avec adaptation responsive.
  Widget _buildContent(Recipe recipe, double screenWidth) {
    // Si la largeur de l'écran dépasse 600px, on active la disposition "Tablette".
    final bool isTablet = screenWidth >= 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ====================================================================
        // 1. IMAGE DE LA RECETTE
        // ====================================================================
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            recipe.thumbnail,
            width: double.infinity,
            height: isTablet ? 350 : 230,
            fit: BoxFit.cover,
            // Widget de secours si l'image ne charge pas (pas de réseau ou URL invalide)
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: isTablet ? 350 : 230,
                width: double.infinity,
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.image_not_supported,
                  size: 60,
                  color: Colors.grey,
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 20),

        // ====================================================================
        // 2. NOM DE LA RECETTE
        // ====================================================================
        Text(
          recipe.name,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 8),

        // ====================================================================
        // 3. CATÉGORIE
        // ====================================================================
        if (recipe.category.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              label: Text(recipe.category),
              avatar: const Icon(Icons.restaurant, size: 18),
            ),
          ),

        const SizedBox(height: 24),

        // ====================================================================
        // 4. INGRÉDIENTS & CALCULATEUR (RESPONSIVE)
        // ====================================================================
        if (isTablet)
          // Sur TABLETTE : affichage côte à côte (2 colonnes)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildIngredients(recipe),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildPortionCalculator(recipe),
              ),
            ],
          )
        else
          // Sur TÉLÉPHONE : affichage l'un en-dessous de l'autre (1 colonne)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPortionCalculator(recipe),
              const SizedBox(height: 24),
              _buildIngredients(recipe),
            ],
          ),

        const SizedBox(height: 30),

        // ====================================================================
        // 5. INSTRUCTIONS DE PRÉPARATION
        // ====================================================================
        _buildInstructions(recipe),

        const SizedBox(height: 30),
      ],
    );
  }

  // ==========================================================================
  // SECTION : LISTE DES INGRÉDIENTS AVEC CALCUL DYNAMIQUE DES QUANTITÉS
  // ==========================================================================

  Widget _buildIngredients(Recipe recipe) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ingrédients',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Badge indiquant le nombre d'ingrédients
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${recipe.ingredients.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Parcours de chaque ingrédient avec ajustement proportionnel de la mesure
            ...recipe.ingredients.map(
              (ingredient) {
                // CALCUL DYNAMIQUE :
                // On recalcule la quantité grâce au calculateur de portions
                final scaledMeasure = PortionCalculator.scaleMeasure(
                  ingredient.measure,
                  basePortions: recipe.basePortions,
                  targetPortions: _portions,
                );

                // Texte complet (ex: "300g Spaghetti" ou "2 eggs")
                final displayItem = scaledMeasure.isEmpty
                    ? ingredient.name
                    : '$scaledMeasure ${ingredient.name}';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Puce colorée
                      Text(
                        '• ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          displayItem,
                          style: const TextStyle(fontSize: 15, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // SECTION : CALCULATEUR DE PORTIONS INTERACTIF
  // ==========================================================================

  Widget _buildPortionCalculator(Recipe recipe) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Nombre de portions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // Contrôles - / + pour ajuster le nombre de portions
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Bouton Décrémenter (-)
                IconButton.filledTonal(
                  onPressed: _portions > 1
                      ? () {
                          setState(() {
                            _portions--;
                          });
                        }
                      : null, // Désactivé si on atteint le minimum de 1 portion
                  icon: const Icon(Icons.remove),
                ),

                // Affichage du nombre de portions sélectionné
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    '$_portions',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),

                // Bouton Incrémenter (+)
                IconButton.filledTonal(
                  onPressed: () {
                    setState(() {
                      _portions++;
                    });
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Note informative sur la recette de base
            Text(
              'Recette d\'origine prévue pour ${recipe.basePortions} portion${recipe.basePortions > 1 ? 's' : ''}.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 6),

            // Indicateur clair de proportion
            if (_portions != recipe.basePortions)
              Text(
                'Quantités ajustées pour $_portions portion${_portions > 1 ? 's' : ''}.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // SECTION : INSTRUCTIONS DE PRÉPARATION
  // ==========================================================================

  Widget _buildInstructions(Recipe recipe) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Instructions de préparation',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Divider(height: 24),

            // Affichage des instructions fournies par l'API
            Text(
              recipe.instructions.trim().isEmpty
                  ? 'Aucune instruction disponible pour cette recette.'
                  : recipe.instructions.trim(),
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}