// Écran d'accueil de RecipeBook.
//
// Recettes réelles chargées depuis TheMealDB :
//  - à l'ouverture : recettes au hasard (« recettes tendance ») ;
//  - recherche : l'API est interrogée par nom, avec filtrage local en direct ;
//  - catégories : vrai filtrage par catégorie de l'API ;
//  - favoris persistés localement via DatabaseService (Hive).

import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../theme/app_palette.dart';
import '../utils/recipe_meta.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/category_chip.dart';
import '../widgets/feedback_state.dart';
import '../widgets/home_greeting.dart';
import '../widgets/home_header.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/recipe_card.dart';
import '../widgets/responsive_grid.dart';
import '../widgets/section_header.dart';
import '../widgets/shimmer.dart';
import 'detail_screen.dart';
import 'favorites_screen.dart';

/// Une catégorie populaire : libellé affiché + nom de l'API MealDB.
class _Category {
  final String label;
  final IconData icon;
  final Color background;
  final String apiName;

  const _Category(this.label, this.icon, this.background, this.apiName);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.api, this.database});

  final ApiService? api;
  final DatabaseService? database;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const List<_Category> _categories = [
    _Category('Poulet', Icons.restaurant, AppPalette.peachBg, 'Chicken'),
    _Category('Bœuf', Icons.lunch_dining, AppPalette.pinkBg, 'Beef'),
    _Category('Poisson', Icons.set_meal, AppPalette.greenBg, 'Seafood'),
    _Category('Végétarien', Icons.eco, AppPalette.greenBg, 'Vegetarian'),
  ];

  late final ApiService _api = widget.api ?? ApiService();
  late final DatabaseService _database = widget.database ?? DatabaseService();

  final TextEditingController _searchController = TextEditingController();

  final Set<String> _favorites = {};

  int _navIndex = 0;
  String? _selectedCategory;

  List<Recipe> _trendingCache = [];
  List<Recipe> _baseRecipes = [];

  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadTrending();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _api.dispose();
    _database.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Chargement des données
  // ---------------------------------------------------------------------------

  Future<void> _loadFavorites() async {
    try {
      final favorites = await _database.getAllFavorites();
      if (mounted) {
        setState(() {
          _favorites
            ..clear()
            ..addAll(favorites.map((r) => r.id));
        });
      }
    } catch (_) {}
  }

  Future<void> _loadTrending() async {
    setState(() {
      _loading = true;
      _error = false;
    });

    final List<Recipe> recipes;
    try {
      recipes = await _api.getRandomMeals(6);
    } on ApiException {
      if (mounted) setState(() => _error = true);
      if (mounted) setState(() => _loading = false);
      return;
    }

    if (!mounted) return;
    setState(() {
      _trendingCache = recipes;
      if (_selectedCategory == null && _searchController.text.trim().isEmpty) {
        _baseRecipes = recipes;
      }
      _loading = false;
    });
  }

  Future<void> _loadCategory(String apiName) async {
    setState(() {
      _loading = true;
      _error = false;
    });

    final List<Recipe> recipes;
    try {
      recipes = await _api.getRecipesByCategory(apiName);
    } on ApiException {
      if (mounted) setState(() => _error = true);
      if (mounted) setState(() => _loading = false);
      return;
    }

    if (!mounted) return;
    setState(() {
      _baseRecipes = recipes;
      _loading = false;
    });
  }

  Future<void> _searchRecipes(String query) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = false;
    });

    final List<Recipe> recipes;
    try {
      recipes = await _api.searchRecipesByName(query);
    } on ApiException {
      if (mounted) setState(() => _error = true);
      if (mounted) setState(() => _loading = false);
      return;
    }

    if (!mounted) return;
    setState(() {
      _baseRecipes = recipes;
      _selectedCategory = null;
      _loading = false;
    });
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = null;
      _baseRecipes = _trendingCache.isNotEmpty
          ? _trendingCache
          : _baseRecipes;
    });
    if (_trendingCache.isEmpty) _loadTrending();
  }

  void _onCategoryTap(_Category category) {
    if (_selectedCategory == category.label) {
      setState(() {
        _selectedCategory = null;
        _baseRecipes = _trendingCache.isNotEmpty
            ? _trendingCache
            : _baseRecipes;
      });
      if (_trendingCache.isEmpty) _loadTrending();
      return;
    }
    setState(() => _selectedCategory = category.label);
    _loadCategory(category.apiName);
  }

  // Recherche en direct : filtre local du contenu déjà chargé.
  List<Recipe> get _visibleRecipes {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _baseRecipes;

    return _baseRecipes.where((recipe) {
      final description = RecipeMeta.from(recipe).description.toLowerCase();
      return recipe.name.toLowerCase().contains(query) ||
          description.contains(query);
    }).toList();
  }

  void _syncViewState() => setState(() {});

  // ---------------------------------------------------------------------------
  // Favoris
  // ---------------------------------------------------------------------------

  Future<void> _toggleFavorite(Recipe recipe) async {
    final isFavorite = _favorites.contains(recipe.id);
    setState(() {
      if (isFavorite) {
        _favorites.remove(recipe.id);
      } else {
        _favorites.add(recipe.id);
      }
    });

    try {
      if (isFavorite) {
        await _database.removeFavorite(recipe.id);
      } else {
        await _database.addFavorite(recipe);
      }
    } catch (_) {}
  }

  void _openDetail(Recipe recipe) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetailScreen(
          recipe: recipe,
          initiallyFavorite: _favorites.contains(recipe.id),
          api: _api,
          database: _database,
          onFavoriteChanged: (isFavorite) {
            setState(() {
              if (isFavorite) {
                _favorites.add(recipe.id);
              } else {
                _favorites.remove(recipe.id);
              }
            });
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: SafeArea(
        bottom: false,
        child: _navIndex == 2 ? _buildFavoritesTab() : _buildHomeBody(),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _navIndex,
        onSelect: (index) => setState(() => _navIndex = index),
      ),
    );
  }

  Widget _buildFavoritesTab() {
    return FavoritesScreen(
      database: _database,
      api: _api,
      favorites: _favorites,
      onRemoved: (id) => setState(() => _favorites.remove(id)),
      onOpenRecipe: _openDetail,
    );
  }

  Widget _buildHomeBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HomeHeader(),
              const SizedBox(height: 20),
              const HomeGreeting(),
              const SizedBox(height: 16),
              HomeSearchBar(
                controller: _searchController,
                onSubmitted: () {
                  final query = _searchController.text.trim();
                  if (query.isNotEmpty) {
                    _searchRecipes(query);
                  } else {
                    setState(() => _baseRecipes = _trendingCache);
                    if (_trendingCache.isEmpty) _loadTrending();
                  }
                },
                onChanged: (_) => _syncViewState(),
              ),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Catégories populaires',
                showSeeAll: false,
              ),
              const SizedBox(height: 14),
              _buildCategories(),
              const SizedBox(height: 24),
              _buildTrendingHeader(),
              const SizedBox(height: 14),
              _buildTrendingContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final selected = _selectedCategory == category.label;
          return CategoryChip(
            label: category.label,
            icon: category.icon,
            background: category.background,
            selected: selected,
            onTap: () => _onCategoryTap(category),
          );
        },
      ),
    );
  }

  Widget _buildTrendingHeader() {
    final count = _visibleRecipes.length;
    return SectionHeader(title: 'Recettes tendance', badge: '$count au menu');
  }

  Widget _buildTrendingContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 600 ? 3 : 2;

        if (_loading) {
          return ResponsiveGrid(
            columns: columns,
            children: List.generate(columns * 2, (_) => const SkeletonCard()),
          );
        }
        if (_error) {
          return ErrorState(onRetry: () {
            if (_selectedCategory != null) {
              final category = _categories.firstWhere(
                (c) => c.label == _selectedCategory,
              );
              _loadCategory(category.apiName);
            } else if (_searchController.text.trim().isNotEmpty) {
              _searchRecipes(_searchController.text.trim());
            } else {
              _loadTrending();
            }
          });
        }

        final recipes = _visibleRecipes;
        if (recipes.isEmpty) return _buildEmptyState();

        return ResponsiveGrid(
          columns: columns,
          children: recipes.map((r) => _buildRecipeCard(r)).toList(),
        );
      },
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return RecipeCard(
      recipe: recipe,
      isFavorite: _favorites.contains(recipe.id),
      onTap: () => _openDetail(recipe),
      onFavoriteToggle: (_) => _toggleFavorite(recipe),
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      title: 'Aucune recette trouvée',
      message: 'Essayez un autre mot-clé ou une autre catégorie.',
      actionLabel: 'Réinitialiser les filtres',
      onAction: _resetFilters,
    );
  }
}