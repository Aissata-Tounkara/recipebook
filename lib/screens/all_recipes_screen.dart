// Liste complète « Toutes les recettes » : toutes les recettes composées
// par catégorie. Simple écran de consultation lié à la section d'accueil.

import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../theme/app_palette.dart';
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
    required this.offline,
    required this.favorites,
    required this.onRetry,
    required this.onOpenRecipe,
    required this.onToggleFavorite,
  });

  final List<Recipe> recipes;
  final bool loading;
  final bool error;
  final bool offline;

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
              child: Icon(Icons.arrow_back, size: 22, color: AppPalette.textDark),
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
          constraints: const BoxConstraints(maxWidth: 900),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 600 ? 3 : 2;

              if (loading) {
                return ResponsiveGrid(
                  columns: columns,
                  children: List.generate(columns * 3, (_) => const SkeletonCard()),
                );
              }
              if (error) {
                return ErrorState(onRetry: onRetry);
              }
              if (recipes.isEmpty) {
                return EmptyState(
                  title: 'Aucune recette disponible',
                  message: 'Réessayez dans un instant pour parcourir '
                      'toutes les recettes.',
                  actionLabel: 'Réessayer',
                  onAction: onRetry,
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (offline) ...[
                    _buildOfflineNotice(),
                    const SizedBox(height: 16),
                  ],
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

  // Avis discret quand la liste provient du cache hors-ligne.
  Widget _buildOfflineNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.thinBorder),
      ),
      child: const Row(
        children: [
          Icon(Icons.cloud_off, size: 16, color: AppPalette.textMuted),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Connexion indisponible — recettes chargées précédemment.',
              style: TextStyle(fontSize: 12.5, color: AppPalette.textMuted),
            ),
          ),
        ],
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