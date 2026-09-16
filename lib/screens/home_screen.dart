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
import '../utils/responsive.dart';
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

  // Sur grand écran : rail latéral dépliable (réduit = icônes seules).
  bool _railExpanded = true;

  // Navigateur interne du contenu : le rail / la barre du bas restent
  // affichés pendant que les écrans secondaires (détail, toutes les recettes)
  // se poussent dans la zone de contenu.
  final GlobalKey<NavigatorState> _contentKey = GlobalKey<NavigatorState>();

  List<Recipe> _trendingCache = [];
  List<Recipe> _baseRecipes = [];

  List<Recipe> _allRecipes = [];
  bool _allLoading = false;
  bool _allError = false;

  bool _loading = true;
  bool _error = false;

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

  // « Toutes les recettes » : composition par catégorie via l'API. Si
  // l'appel échoue, la section affiche son état d'erreur.
  Future<void> _loadAllRecipes() async {
    setState(() {
      _allLoading = true;
      _allError = false;
    });

    final List<Recipe> recipes;
    try {
      final categories = await _api.getCategories();
      recipes = categories.isEmpty
          ? []
          : await _api.getRecipesByCategories(categories);
    } on ApiException {
      if (!mounted) return;
      setState(() {
        _allError = true;
        _allLoading = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _allRecipes = recipes;
      _allLoading = false;
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
      _baseRecipes = _trendingCache.isNotEmpty ? _trendingCache : _baseRecipes;
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
    _contentKey.currentState?.push(
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
    _contentKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => AllRecipesScreen(
          recipes: _allRecipes,
          loading: _allLoading,
          error: _allError,
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
    if (MediaQuery.sizeOf(context).width >= Breakpoints.navRail) {
      return _buildDesktopLayout();
    }
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: SafeArea(bottom: false, child: _contentArea()),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _navIndex,
        onSelect: _selectTab,
      ),
    );
  }

  // Grand écran : rail de navigation latéral + contenu à côté.
  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildNavigationRail(),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: AppPalette.thinBorder,
            ),
            Expanded(child: _contentArea()),
          ],
        ),
      ),
    );
  }

  // Zone de contenu : un navigateur dédié pour que le rail / la barre du bas
  // restent visibles sur toutes les pages (onglets + écrans secondaires).
  Widget _contentArea() {
    return Navigator(
      key: _contentKey,
      onGenerateInitialRoutes: (navigator, initialRoute) {
        return [
          MaterialPageRoute(
            settings: const RouteSettings(name: '/tab'),
            builder: (_) => _buildTab(_navIndex),
          ),
        ];
      },
    );
  }

  // Changement d'onglet : on referme les écrans secondaires puis on remplace
  // la page racine par l'onglet choisi.
  void _selectTab(int index) {
    final nav = _contentKey.currentState;
    if (nav == null) return;
    nav.popUntil((route) => route.isFirst);
    if (index == _navIndex) return;
    nav.pushReplacement(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/tab'),
        builder: (_) => _buildTab(index),
      ),
    );
    setState(() => _navIndex = index);
  }

  Widget _buildTab(int index) {
    return switch (index) {
      1 => _buildCategoriesTab(),
      2 => _buildFavoritesTab(),
      _ => _buildHomeBody(),
    };
  }

  Widget _buildNavigationRail() {
    return NavigationRail(
      backgroundColor: AppPalette.card,
      extended: _railExpanded,
      selectedIndex: _navIndex,
      onDestinationSelected: _selectTab,
      // Déplié : le label est affiché à côté de l'icône (extended).
      // Replié : seules les icônes restent visibles.
      labelType: NavigationRailLabelType.none,
      leading: _buildRailBranding(),
      trailing: _buildRailToggle(),
      selectedIconTheme: const IconThemeData(color: AppPalette.brown),
      unselectedIconTheme: const IconThemeData(color: AppPalette.textMuted),
      selectedLabelTextStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppPalette.brown,
      ),
      unselectedLabelTextStyle: const TextStyle(
        fontSize: 13,
        color: AppPalette.textMuted,
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text('Accueil'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.grid_view_outlined),
          selectedIcon: Icon(Icons.grid_view),
          label: Text('Catégories'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.favorite_border),
          selectedIcon: Icon(Icons.favorite),
          label: Text('Favoris'),
        ),
      ],
    );
  }

// Marque du rail : icône seule quand repliée, icône + nom quand dépliée.
  Widget _buildRailBranding() {
    final brand = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF2A93B), Color(0xFFD9662B)],
            ),
          ),
          child: const Icon(
            Icons.restaurant_menu,
            color: Colors.white,
            size: 22,
          ),
        ),
        if (_railExpanded) ...[
          const SizedBox(width: 10),
          Text(
            'RecipeBook',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppPalette.textDark,
            ),
          ),
        ],
      ],
    );

    // Déplié : logo aligné à gauche comme les icônes des destinations.
    // Replié : centré, comme les icônes dans le rail réduit.
    return Align(
      heightFactor: 1.0,
      alignment: _railExpanded ? Alignment.centerLeft : Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: brand,
      ),
    );
  }

  // Bouton en bas du rail : déplie / replie la barre latérale.
  Widget _buildRailToggle() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1, thickness: 1, color: AppPalette.thinBorder),
        IconButton(
          tooltip: _railExpanded
              ? 'Réduire la barre latérale'
              : 'Agrandir la barre latérale',
          onPressed: () => setState(() => _railExpanded = !_railExpanded),
          icon: Icon(
            _railExpanded
                ? Icons.keyboard_double_arrow_left
                : Icons.keyboard_double_arrow_right,
          ),
          color: AppPalette.textMuted,
        ),
      ],
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
    // Grand écran : la marque RecipeBook est portée par le rail latéral, le
    // contenu commence donc directement par le message de bienvenue.
    final isWide = MediaQuery.sizeOf(context).width >= Breakpoints.navRail;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: contentMaxWidth(MediaQuery.sizeOf(context).width),
        ),
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            if (!isWide) ...[
              SliverToBoxAdapter(child: _pad(const HomeHeader())),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
            SliverToBoxAdapter(child: _pad(const HomeGreeting())),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickySearchHeaderDelegate(
                child: _buildStickySearchHeader(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(child: _pad(_buildTrendingHeader())),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(child: _pad(_buildTrendingContent())),
            if (_showAllRecipesSection) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(child: _pad(_buildAllRecipesSection())),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  // Marge latérale commune du contenu défilant (16 px, comme la barre
  // collante ci-dessous).
  Widget _pad(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: child,
    );
  }

  // Barre épinglée en haut : recherche + catégories populaires (puces).
  Widget _buildStickySearchHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        color: AppPalette.background,
        border: Border(
          bottom: BorderSide(color: AppPalette.thinBorder, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 56,
            child: HomeSearchBar(
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
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(height: 48, child: _buildCategories()),
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
    return SectionHeader(title: 'Recettes tendance', badge: '$count au menu');
  }

  Widget _buildTrendingContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = gridColumnsFor(constraints.maxWidth);

        if (_loading) {
          return ResponsiveGrid(
            columns: columns,
            children: List.generate(columns * 2, (_) => const SkeletonCard()),
          );
        }
        if (_error) {
          return ErrorState(
            onRetry: () {
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
            },
          );
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
            final columns = gridColumnsFor(constraints.maxWidth);

            if (_allLoading) {
              return ResponsiveGrid(
                columns: columns,
                children: List.generate(
                  columns * 2,
                  (_) => const SkeletonCard(),
                ),
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
                ResponsiveGrid(
                  columns: columns,
                  children: preview.map((r) => _buildRecipeCard(r)).toList(),
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
      message:
          'Essayez un autre mot-clé ou explorez une autre catégorie '
          'pour trouver votre prochaine recette préférée.',
      actionLabel: 'Réinitialiser les filtres',
      onAction: _resetFilters,
    );
  }
}

// En-tête épinglé de l'accueil : barre de recherche + catégories
// populaires. Reste collé en haut de l'écran pendant le défilement.
class _StickySearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  _StickySearchHeaderDelegate({required this.child});

  final Widget child;

  // Recherche (56) + écart (12) + puces (48), plus les marges (10+10),
  // la bordure basse (1) et une petite marge de sécurité (2).
  static const double extent = 56 + 12 + 48 + 10 + 10 + 1 + 2;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // SizedBox.expand force l'en-tête à occuper toute la hauteur épinglée :
    // la géométrie (paintExtent == layoutExtent) reste ainsi valide.
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_StickySearchHeaderDelegate oldDelegate) =>
      child != oldDelegate.child;
}
