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
import 'all_recipes_screen.dart';
import 'categories_screen.dart';
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

  List<Recipe> _allRecipes = [];
  bool _allLoading = false;
  bool _allError = false;
  bool _allOffline = false;

  bool _loading = true;
  bool _error = false;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadTrending();
    _loadAllRecipes();
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
      _offline = false;
    });

    // 1) Cache : on évite de marteler /random.php à chaque lancement.
    final cached = await _database.getTrendingCache();
    if (cached != null &&
        cached.recipes.isNotEmpty &&
        DateTime.now().difference(cached.savedAt) <
            DatabaseService.trendingCacheDuration) {
      if (!mounted) return;
      setState(() {
        _trendingCache = cached.recipes;
        if (_selectedCategory == null &&
            _searchController.text.trim().isEmpty) {
          _baseRecipes = cached.recipes;
        }
        _loading = false;
      });
      return;
    }

    // 2) Appel réseau.
    final List<Recipe> recipes;
    try {
      recipes = await _api.getRandomMeals(6);
    } on ApiException {
      // Sans connexion : on retombe sur la liste en cache, même ancienne.
      if (cached != null && cached.recipes.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _trendingCache = cached.recipes;
          if (_selectedCategory == null &&
              _searchController.text.trim().isEmpty) {
            _baseRecipes = cached.recipes;
          }
          _loading = false;
          _offline = true;
        });
        return;
      }
      if (mounted) setState(() => _error = true);
      if (mounted) setState(() => _loading = false);
      return;
    }

    if (!mounted) return;
    await _database.saveTrendingCache(recipes);
    if (!mounted) return;
    setState(() {
      _trendingCache = recipes;
      if (_selectedCategory == null && _searchController.text.trim().isEmpty) {
        _baseRecipes = recipes;
      }
      _loading = false;
      _offline = false;
    });
  }

  // « Toutes les recettes » : cache d'abord (24 h), sinon composition par
  // catégorie via l'API. En cas d'échec réseau, on retombe sur le cache,
  // même ancien, en signalant le mode hors-ligne.
  Future<void> _loadAllRecipes() async {
    setState(() {
      _allLoading = true;
      _allError = false;
      _allOffline = false;
    });

    final cached = await _database.getAllRecipesCache();
    if (cached != null &&
        cached.recipes.isNotEmpty &&
        DateTime.now().difference(cached.savedAt) <
            DatabaseService.allRecipesCacheDuration) {
      if (!mounted) return;
      setState(() {
        _allRecipes = cached.recipes;
        _allLoading = false;
      });
      return;
    }

    final List<Recipe> recipes;
    try {
      final categories = await _api.getCategories();
      recipes =
          categories.isEmpty ? [] : await _api.getRecipesByCategories(categories);
    } on ApiException {
      if (cached != null && cached.recipes.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _allRecipes = cached.recipes;
          _allLoading = false;
          _allOffline = true;
        });
        return;
      }
      if (!mounted) return;
      setState(() {
        _allError = true;
        _allLoading = false;
      });
      return;
    }

    if (!mounted) return;
    await _database.saveAllRecipesCache(recipes);
    if (!mounted) return;
    setState(() {
      _allRecipes = recipes;
      _allLoading = false;
      _allOffline = false;
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

  // Recherche en direct : le contenu affiché est celui chargé depuis l'API.
  List<Recipe> get _visibleRecipes => _baseRecipes;

  // La section « Toutes les recettes » est un bloc de navigation dédié :
  // on ne l'affiche que sur l'accueil, hors recherche/filtre, pour ne pas
  // mélanger deux listes différentes au même écran.
  bool get _showAllRecipesSection =>
      _selectedCategory == null && _searchController.text.trim().isEmpty;

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

  // Écran pleine page listant toutes les recettes chargées.
  void _openAllRecipes() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AllRecipesScreen(
          recipes: _allRecipes,
          loading: _allLoading,
          error: _allError,
          offline: _allOffline,
          favorites: _favorites,
          onRetry: _loadAllRecipes,
          onOpenRecipe: _openDetail,
          onToggleFavorite: _toggleFavorite,
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
        child: switch (_navIndex) {
          1 => _buildCategoriesTab(),
          2 => _buildFavoritesTab(),
          _ => _buildHomeBody(),
        },
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

  Widget _buildCategoriesTab() {
    return CategoriesScreen(
      api: _api,
      favorites: _favorites,
      onOpenRecipe: _openDetail,
      onToggleFavorite: _toggleFavorite,
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
              ),  // fin HomeSearchBar
              if (_offline) ...[
                const SizedBox(height: 14),
                _buildOfflineNotice(),
              ],
              const SizedBox(height: 24),
              const SectionHeader(title: 'Catégories populaires'),
              const SizedBox(height: 14),
              _buildCategories(),
              const SizedBox(height: 24),
              _buildTrendingHeader(),
              const SizedBox(height: 14),
              _buildTrendingContent(),
              if (_showAllRecipesSection) ...[
                const SizedBox(height: 24),
                _buildAllRecipesSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Avis discret quand la liste affichée provient du cache hors-ligne.
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
    return SectionHeader(
      title: 'Recettes tendance',
      badge: '$count au menu',
    );
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

  // Section « Toutes les recettes » : aperçu des premières recettes + accès
  // à la liste complète en pleine page.
  Widget _buildAllRecipesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Toutes les recettes',
          badge: _allRecipes.isEmpty ? null : '${_allRecipes.length} recettes',
          actionLabel: 'Voir tout',
          onAction: _openAllRecipes,
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 600 ? 3 : 2;

            if (_allLoading) {
              return ResponsiveGrid(
                columns: columns,
                children: List.generate(columns * 2, (_) => const SkeletonCard()),
              );
            }
            if (_allError) {
              return ErrorState(onRetry: _loadAllRecipes);
            }
            if (_allRecipes.isEmpty) return const SizedBox.shrink();

            final preview = _allRecipes.take(6).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_allOffline) ...[
                  _buildOfflineNotice(),
                  const SizedBox(height: 16),
                ],
                ResponsiveGrid(
                  columns: columns,
                  children:
                      preview.map((r) => _buildRecipeCard(r)).toList(),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      title: 'Aucune recette trouvée',
      message: 'Essayez un autre mot-clé ou explorez une autre catégorie '
          'pour trouver votre prochaine recette préférée.',
      actionLabel: 'Réinitialiser les filtres',
      onAction: _resetFilters,
    );
  }
}