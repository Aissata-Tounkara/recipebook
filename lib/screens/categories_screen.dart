// Onglet « Catégories » : liste toutes les catégories de TheMealDB, puis
// affiche les recettes de la catégorie sélectionnée.

import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../services/api_service.dart';
import '../theme/app_palette.dart';
import '../utils/responsive.dart';
import '../widgets/feedback_state.dart';
import '../widgets/home_header.dart';
import '../widgets/recipe_card.dart';
import '../widgets/responsive_grid.dart';
import '../widgets/section_header.dart';
import '../widgets/shimmer.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({
    super.key,
    required this.api,
    required this.favorites,
    required this.onOpenRecipe,
    required this.onToggleFavorite,
  });

  final ApiService api;

  /// Identifiants des recettes favorites (pour les cœurs des cartes).
  final Set<String> favorites;

  final void Function(Recipe recipe) onOpenRecipe;
  final void Function(Recipe recipe) onToggleFavorite;

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<String> _categories = [];
  bool _loading = true;
  bool _error = false;

  // Catégorie actuellement ouverte (null = on affiche la grille).
  String? _selectedCategory;
  List<Recipe> _recipes = [];
  bool _recipesLoading = false;
  bool _recipesError = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final categories = await widget.api.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  Future<void> _selectCategory(String category) async {
    setState(() {
      _selectedCategory = category;
      _recipes = [];
      _recipesLoading = true;
      _recipesError = false;
    });
    try {
      final recipes = await widget.api.getRecipesByCategory(category);
      if (!mounted) return;
      setState(() {
        _recipes = recipes;
        _recipesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _recipesLoading = false;
        _recipesError = true;
      });
    }
  }

  void _clearSelection() => setState(() => _selectedCategory = null);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: contentMaxWidth(MediaQuery.sizeOf(context).width),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grand écran : la marque est portée par le rail latéral.
              if (MediaQuery.sizeOf(context).width < Breakpoints.navRail) ...[
                const HomeHeader(),
                const SizedBox(height: 20),
              ],
              _selectedCategory == null
                  ? _buildCategoryList()
                  : _buildCategoryRecipes(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Grille des catégories
  // ---------------------------------------------------------------------------

  Widget _buildCategoryList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Catégories',
          badge: _loading ? null : '${_categories.length}',
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = gridColumnsFor(constraints.maxWidth);

            if (_loading) {
              return ResponsiveGrid(
                columns: columns,
                children: List.generate(
                  columns * 3,
                  (_) => const SkeletonCard(),
                ),
              );
            }
            if (_error) {
              return ErrorState(onRetry: _loadCategories);
            }
            if (_categories.isEmpty) {
              return EmptyState(
                icon: Icons.grid_view,
                title: 'Aucune catégorie disponible',
                message: 'Réessayez dans un instant.',
                actionLabel: 'Réessayer',
                onAction: _loadCategories,
              );
            }

            return ResponsiveGrid(
              columns: columns,
              children: _categories
                  .map(
                    (name) => _CategoryTile(
                      name: name,
                      onTap: () => _selectCategory(name),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Recettes de la catégorie sélectionnée
  // ---------------------------------------------------------------------------

  Widget _buildCategoryRecipes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: _clearSelection,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                width: 32,
                height: 32,
                child: Icon(
                  Icons.arrow_back,
                  size: 20,
                  color: AppPalette.textDark,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: SectionHeader(
                title: _selectedCategory!,
                badge: _recipesLoading ? null : '${_recipes.length} recettes',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = gridColumnsFor(constraints.maxWidth);

            if (_recipesLoading) {
              return ResponsiveGrid(
                columns: columns,
                children: List.generate(
                  columns * 3,
                  (_) => const SkeletonCard(),
                ),
              );
            }
            if (_recipesError) {
              return ErrorState(
                onRetry: () => _selectCategory(_selectedCategory!),
              );
            }
            if (_recipes.isEmpty) {
              return EmptyState(
                title: 'Aucune recette dans cette catégorie',
                message: 'Essayez une autre catégorie.',
                actionLabel: 'Retour aux catégories',
                onAction: _clearSelection,
              );
            }

            return ResponsiveGrid(
              columns: columns,
              children: _recipes
                  .map((recipe) => _buildRecipeCard(recipe))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return RecipeCard(
      recipe: recipe,
      isFavorite: widget.favorites.contains(recipe.id),
      onTap: () => widget.onOpenRecipe(recipe),
      onFavoriteToggle: (_) => widget.onToggleFavorite(recipe),
    );
  }
}

// Icônes évocatrices pour les catégories connues de TheMealDB ; les
// catégories inconnues retombent sur une icône générique.
const Map<String, IconData> _categoryIcons = {
  'Beef': Icons.lunch_dining,
  'Chicken': Icons.restaurant,
  'Dessert': Icons.icecream,
  'Lamb': Icons.kebab_dining,
  'Miscellaneous': Icons.dining,
  'Pasta': Icons.ramen_dining,
  'Pork': Icons.tapas,
  'Seafood': Icons.set_meal,
  'Side': Icons.rice_bowl,
  'Starter': Icons.soup_kitchen,
  'Vegan': Icons.eco,
  'Vegetarian': Icons.eco,
  'Breakfast': Icons.free_breakfast,
  'Goat': Icons.grass,
};

const List<Color> _categoryColors = [
  AppPalette.peachBg,
  AppPalette.greenBg,
  AppPalette.pinkBg,
];

/// Une tuile de catégorie dans la grille (icône + nom, fond pastel).
class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background =
        _categoryColors[name.hashCode.abs() % _categoryColors.length];
    final icon = _categoryIcons[name] ?? Icons.restaurant_menu;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: AppPalette.textDark),
            const SizedBox(height: 10),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppPalette.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
