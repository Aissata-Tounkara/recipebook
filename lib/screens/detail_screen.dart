import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../theme/app_palette.dart';
import '../utils/recipe_meta.dart';
import '../widgets/detail/chef_tip_card.dart';
import '../widgets/detail/detail_bottom_bar.dart';
import '../widgets/detail/hero_image.dart';
import '../widgets/detail/info_grid.dart';
import '../widgets/detail/ingredient_list.dart';
import '../widgets/detail/portion_adjuster.dart';
import '../widgets/detail/preparation_list.dart';
import '../widgets/detail/rating_row.dart';

// ============================================================================
// Écran de détail d'une recette
// ============================================================================
class DetailScreen extends StatefulWidget {
  final Recipe recipe;
  final bool initiallyFavorite;
  final ValueChanged<bool>? onFavoriteChanged;
  final ApiService? api;
  final DatabaseService? database;

  const DetailScreen({
    super.key,
    required this.recipe,
    this.initiallyFavorite = false,
    this.onFavoriteChanged,
    this.api,
    this.database,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  // Données locales
  late Recipe _recipe = widget.recipe;
  late bool _isFavorite = widget.initiallyFavorite;
  late int _portions = widget.recipe.basePortions;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Si la recette n'a pas encore ses détails, on les charge depuis l'API
    if (_recipe.ingredients.isEmpty && widget.api != null) {
      _loadDetails();
    }
  }

  // Charge les détails complets de la recette via l'API
  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    final full = await widget.api!.getRecipeById(_recipe.id);
    if (!mounted) return;
    if (full != null) {
      setState(() {
        _recipe = full;
        _portions = full.basePortions;
      });
    }
    setState(() => _isLoading = false);
  }

  // Gestion du bouton Favori (Ajouter / Retirer)
  Future<void> _toggleFavorite() async {
    final next = !_isFavorite;
    setState(() => _isFavorite = next);

    // Message de confirmation en bas d'écran (Toast)
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(next ? 'Ajoutée à vos favoris' : 'Retirée de vos favoris'),
          duration: const Duration(seconds: 2),
        ),
      );

    // Sauvegarde dans la base de données locale
    if (widget.database != null && _recipe.id.isNotEmpty) {
      try {
        if (next) {
          await widget.database!.addFavorite(_recipe);
        } else {
          await widget.database!.removeFavorite(_recipe.id);
        }
      } catch (_) {}
    }

    widget.onFavoriteChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final meta = RecipeMeta.from(_recipe);

    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        title: const Text('Recettes'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Note et Catégorie
                  RatingRow(
                    rating: meta.rating,
                    reviews: meta.reviews,
                    category: _recipe.category,
                  ),
                  const SizedBox(height: 12),

                  // 2. Image principale
                  HeroImage(
                    imageUrl: _recipe.thumbnail,
                    time: meta.time,
                    emoji: meta.emoji,
                  ),
                  const SizedBox(height: 16),

                  // 3. Titre de la recette
                  Text(
                    _recipe.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppPalette.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Grille d'informations (temps, difficulté, calories)
                  InfoGrid(
                    basePortions: _recipe.basePortions,
                    cookTime: meta.time,
                    difficulty: meta.difficulty,
                    energy: meta.kcal,
                  ),
                  const SizedBox(height: 16),

                  // 5. Astuce du chef
                  ChefTipCard(tip: meta.chefTip),
                  const SizedBox(height: 16),

                  // 6. Sélecteur de portions
                  PortionAdjuster(
                    portions: _portions,
                    basePortions: _recipe.basePortions,
                    onChanged: (val) => setState(() => _portions = val),
                  ),
                  const SizedBox(height: 16),

                  // 7. Liste des ingrédients avec recalcul dynamique
                  IngredientList(
                    ingredients: _recipe.ingredients,
                    basePortions: _recipe.basePortions,
                    portions: _portions,
                  ),
                  const SizedBox(height: 16),

                  // 8. Instructions de préparation
                  PreparationList(
                    steps: _recipe.instructions
                        .split('\n')
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty)
                        .toList(),
                  ),
                ],
              ),
            ),
      // 9. Bouton favori en bas
      bottomNavigationBar: DetailBottomBar(
        isFavorite: _isFavorite,
        onFavoriteToggle: _toggleFavorite,
      ),
    );
  }
}