// Liste complète « Toutes les recettes » : toutes les recettes composées
// par catégorie. Simple écran de consultation lié à la section d'accueil.

import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../theme/app_palette.dart';
import '../utils/responsive.dart';
import '../widgets/feedback_state.dart';
import '../widgets/recipe_card.dart';
import '../widgets/responsive_grid.dart';
import '../widgets/shimmer.dart';

class AllRecipesScreen extends StatelessWidget {
  const AllRecipesScreen({
    super.key,
    required this.recipes,
    required this.loading,
    required this.error,
    required this.favorites,
    required this.onRetry,
    required this.onOpenRecipe,
    required this.onToggleFavorite,
  });

  final List<Recipe> recipes;
  final bool loading;
  final bool error;

  /// Identifiants des recettes favorites (pour les cœurs des cartes).
  final Set<String> favorites;

  final VoidCallback onRetry;
  final void Function(Recipe recipe) onOpenRecipe;
  final void Function(Recipe recipe) onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(child: _buildContent(context)),
          ],
        ),
      ),
    );
  }

  // Barre supérieure : retour + titre + compteur.
  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                Icons.arrow_back,
                size: 22,
                color: AppPalette.textDark,
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'Toutes les recettes',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppPalette.textDark,
            ),
          ),
          const Spacer(),
          if (recipes.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppPalette.peachBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${recipes.length} recettes',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.peachText,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: contentMaxWidth(MediaQuery.sizeOf(context).width),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = gridColumnsFor(constraints.maxWidth);

              if (loading) {
                return ResponsiveGrid(
                  columns: columns,
                  children: List.generate(
                    columns * 3,
                    (_) => const SkeletonCard(),
                  ),
                );
              }
              if (error) {
                return ErrorState(onRetry: onRetry);
              }
              if (recipes.isEmpty) {
                return EmptyState(
                  title: 'Aucune recette disponible',
                  message:
                      'Réessayez dans un instant pour parcourir '
                      'toutes les recettes.',
                  actionLabel: 'Réessayer',
                  onAction: onRetry,
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveGrid(
                    columns: columns,
                    children: recipes.map((r) => _buildCard(r)).toList(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Recipe recipe) {
    return RecipeCard(
      recipe: recipe,
      isFavorite: favorites.contains(recipe.id),
      onTap: () => onOpenRecipe(recipe),
      onFavoriteToggle: (_) => onToggleFavorite(recipe),
    );
  }
}
