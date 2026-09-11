// Écran d'accueil de RecipeBook.
//
// Cet écran est une vitrine d'interface adaptative et réactive :
//  - mise en page responsive via LayoutBuilder (2 colonnes sur téléphone,
//    3 colonnes à partir de 600 px de large / tablette) ;
//  - simulation des différents états de l'UI (vue normale, squelette de
//    chargement « shimmer », erreur réseau, résultat vide) ;
//  - bascule d'un mode hors-ligne / mode local.
//
// Les recettes tendance sont des données locales : l'écran fonctionne donc
// entièrement hors-ligne, ce qui colle au badge « Mode local » de l'en-tête.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'detail_screen.dart';

/// Palette de couleurs de l'application.
class _Palette {
  static const background = Color(0xFFFBF5EE);
  static const card = Colors.white;
  static const brown = Color(0xFF9E4A24);
  static const textDark = Color(0xFF2E2A26);
  static const textMuted = Color(0xFF8C8279);

  // Accents pastel.
  static const peachBg = Color(0xFFF7E2D2);
  static const peachText = Color(0xFFB5602A);
  static const greenBg = Color(0xFFDDEBE0);
  static const greenText = Color(0xFF3F7D5A);
  static const pinkBg = Color(0xFFF6E0E0);
  static const amber = Color(0xFFF2A93B);
  static const heart = Color(0xFFE05B4B);
}

/// États d'affichage simulables depuis la carte de démonstration.
enum _ViewState { normal, skeleton, error, empty }

/// Une recette « tendance » affichée sur l'accueil (données locales).
class _TrendingRecipe {
  final String name;
  final String description;
  final String category;
  final String time;
  final String kcal;
  final double rating;
  final String tag;
  final bool tagIsGreen;
  final String difficulty;
  final String emoji;
  final String imageUrl;

  const _TrendingRecipe({
    required this.name,
    required this.description,
    required this.category,
    required this.time,
    required this.kcal,
    required this.rating,
    required this.tag,
    required this.tagIsGreen,
    required this.difficulty,
    required this.emoji,
    required this.imageUrl,
  });
}

/// Une catégorie populaire (puce colorée).
class _Category {
  final String label;
  final IconData icon;
  final Color background;

  const _Category(this.label, this.icon, this.background);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  _ViewState _viewState = _ViewState.normal;
  int _navIndex = 0;
  String? _selectedCategory;
  final Set<String> _favorites = {};

  static const List<_Category> _categories = [
    _Category('Poulet', Icons.restaurant, _Palette.peachBg),
    _Category('Bœuf', Icons.lunch_dining, _Palette.pinkBg),
    _Category('Poisson', Icons.set_meal, _Palette.greenBg),
    _Category('Végétarien', Icons.eco, _Palette.greenBg),
  ];

  static const List<_TrendingRecipe> _recipes = [
    _TrendingRecipe(
      name: 'Poulet rôti aux herbes',
      description: 'Ail confit, romarin frais & citron',
      category: 'Poulet',
      time: '40 min',
      kcal: '420 kcal',
      rating: 4.9,
      tag: 'Portions adaptables',
      tagIsGreen: false,
      difficulty: 'Facile',
      emoji: '🍗',
      imageUrl:
          'https://images.unsplash.com/photo-1598103442097-8b74394b95c6?auto=format&fit=crop&w=600&q=60',
    ),
    _TrendingRecipe(
      name: 'Pâtes à la carbonara',
      description: 'Guanciale croustillant, œuf & pecorino',
      category: 'Pâtes',
      time: '25 min',
      kcal: '580 kcal',
      rating: 4.8,
      tag: 'Traditionnel',
      tagIsGreen: false,
      difficulty: 'Rapide',
      emoji: '🍝',
      imageUrl:
          'https://images.unsplash.com/photo-1612874742237-6526221588e3?auto=format&fit=crop&w=600&q=60',
    ),
    _TrendingRecipe(
      name: 'Gnocchi à la crème',
      description: 'Sauce onctueuse, parmesan & basilic',
      category: 'Végétarien',
      time: '30 min',
      kcal: '490 kcal',
      rating: 4.9,
      tag: 'Végétarien',
      tagIsGreen: true,
      difficulty: 'Gourmet',
      emoji: '🥟',
      imageUrl:
          'https://images.unsplash.com/photo-1481931098730-318b6f776db0?auto=format&fit=crop&w=600&q=60',
    ),
    _TrendingRecipe(
      name: 'Poulet au curry & riz',
      description: 'Riz basmati parfumé, lait de coco',
      category: 'Poulet',
      time: '35 min',
      kcal: '510 kcal',
      rating: 4.7,
      tag: 'Épicé doux',
      tagIsGreen: false,
      difficulty: 'Familial',
      emoji: '🍛',
      imageUrl:
          'https://images.unsplash.com/photo-1585937421612-70a008356fbe?auto=format&fit=crop&w=600&q=60',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Recettes filtrées par la recherche et la catégorie sélectionnée.
  List<_TrendingRecipe> get _visibleRecipes {
    final query = _searchController.text.trim().toLowerCase();
    return _recipes.where((r) {
      final matchesCategory =
          _selectedCategory == null || r.category == _selectedCategory;
      final matchesQuery =
          query.isEmpty ||
          r.name.toLowerCase().contains(query) ||
          r.description.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  void _runSearch() {
    FocusScope.of(context).unfocus();
    setState(() {
      _viewState = _visibleRecipes.isEmpty
          ? _ViewState.empty
          : _ViewState.normal;
    });
  }

  // Réaligne l'état d'affichage sur les recettes visibles sans écraser les
  // états de démonstration (squelette / erreur).
  void _syncViewState() {
    if (_viewState == _ViewState.empty || _viewState == _ViewState.normal) {
      _viewState = _visibleRecipes.isEmpty
          ? _ViewState.empty
          : _ViewState.normal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildGreeting(),
                  const SizedBox(height: 16),
                  _buildSearchBar(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Catégories populaires'),
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
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ---------------------------------------------------------------------------
  // En-tête
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    return Row(
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
        const SizedBox(width: 10),
        const Flexible(
          child: Text(
            'RecipeBook',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _Palette.textDark,
            ),
          ),
        ),
        const Spacer(),
        _buildModeChip(),
        const SizedBox(width: 8),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _Palette.card,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.tune, color: _Palette.textDark, size: 20),
        ),
      ],
    );
  }

  Widget _buildModeChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _Palette.greenBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: _Palette.greenText,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'Mode local',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _Palette.greenText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Bonjour ! 👋',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: _Palette.textDark,
          ),
        ),
        SizedBox(height: 6),
        Text(
          "Qu'est-ce qu'on cuisine aujourd'hui ?",
          style: TextStyle(fontSize: 16, color: _Palette.textMuted),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
      decoration: BoxDecoration(
        color: _Palette.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: _Palette.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _runSearch(),
              onChanged: (_) => setState(_syncViewState),
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Rechercher une recette...',
                hintStyle: TextStyle(color: _Palette.textMuted, fontSize: 15),
              ),
            ),
          ),
          GestureDetector(
            onTap: _runSearch,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _Palette.brown,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_forward, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sections
  // ---------------------------------------------------------------------------

  Widget _buildSectionHeader(String title, {String? badge}) {
    return Row(
      children: [
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _Palette.textDark,
            ),
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _Palette.greenBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _Palette.greenText,
              ),
            ),
          ),
        ],
        const Spacer(),
        Row(
          children: const [
            Text(
              'Voir tout',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _Palette.brown,
              ),
            ),
            SizedBox(width: 2),
            Icon(Icons.arrow_forward, size: 16, color: _Palette.brown),
          ],
        ),
      ],
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
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = selected ? null : category.label;
                _syncViewState();
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: category.background,
                borderRadius: BorderRadius.circular(24),
                border: selected
                    ? Border.all(color: _Palette.brown, width: 1.5)
                    : null,
              ),
              child: Row(
                children: [
                  Icon(category.icon, size: 18, color: _Palette.textDark),
                  const SizedBox(width: 8),
                  Text(
                    category.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _Palette.textDark,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrendingHeader() {
    final count = _visibleRecipes.length;
    return _buildSectionHeader('Recettes tendance', badge: '$count au menu');
  }

  // Contenu adaptatif : la grille change de nombre de colonnes selon la largeur.
  Widget _buildTrendingContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 600 ? 3 : 2;

        switch (_viewState) {
          case _ViewState.skeleton:
            return _buildGrid(
              columns,
              List.generate(columns * 2, (_) => const _SkeletonCard()),
            );
          case _ViewState.error:
            return _buildErrorState();
          case _ViewState.empty:
            return _buildEmptyState();
          case _ViewState.normal:
            final recipes = _visibleRecipes;
            if (recipes.isEmpty) return _buildEmptyState();
            return _buildGrid(
              columns,
              recipes.map((r) => _buildRecipeCard(r)).toList(),
            );
        }
      },
    );
  }

  // Grille responsive construite à la main pour éviter tout débordement
  // (les cartes d'une même ligne prennent la hauteur de la plus grande).
  Widget _buildGrid(int columns, List<Widget> cards) {
    final rows = <Widget>[];
    for (var i = 0; i < cards.length; i += columns) {
      final end = math.min(i + columns, cards.length);
      final rowCards = cards.sublist(i, end);
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = 0; j < columns; j++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: j < rowCards.length
                        ? rowCards[j]
                        : const SizedBox.shrink(),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Column(children: rows),
    );
  }

  // ---------------------------------------------------------------------------
  // Carte recette
  // ---------------------------------------------------------------------------

  // Construit la recette détaillée à partir de la carte tapée, afin que la page
  // de détail corresponde bien à la recette sélectionnée (nom, image, catégorie,
  // temps, calories, difficulté, note). Les ingrédients et les étapes détaillés
  // ne figurent pas dans les données de l'accueil : on réutilise donc ceux de la
  // recette de démonstration comme contenu générique.
  RecipeDetail _toDetail(_TrendingRecipe recipe) {
    return RecipeDetail(
      name: recipe.name,
      description: recipe.description,
      category: recipe.category,
      cookTime: recipe.time,
      difficulty: recipe.difficulty,
      energy: recipe.kcal,
      rating: recipe.rating,
      reviews: RecipeDetail.sample.reviews,
      chefTip: RecipeDetail.sample.chefTip,
      imageUrl: recipe.imageUrl,
      emoji: recipe.emoji,
      ingredients: RecipeDetail.sample.ingredients,
      steps: RecipeDetail.sample.steps,
    );
  }

  Widget _buildRecipeCard(_TrendingRecipe recipe) {
    final isFavorite = _favorites.contains(recipe.name);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DetailScreen(
              recipe: _toDetail(recipe),
              initiallyFavorite: _favorites.contains(recipe.name),
              onFavoriteChanged: (isFavorite) {
                setState(() {
                  if (isFavorite) {
                    _favorites.add(recipe.name);
                  } else {
                    _favorites.remove(recipe.name);
                  }
                });
              },
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: _Palette.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image + badge durée + bouton favori.
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 11,
                  child: _RecipeImage(recipe: recipe),
                ),
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 13,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          recipe.time,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isFavorite) {
                          _favorites.remove(recipe.name);
                        } else {
                          _favorites.add(recipe.name);
                        }
                      });
                    },
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: _Palette.heart,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tag + note.
                  Row(
                    children: [
                      Flexible(child: _buildTag(recipe)),
                      const SizedBox(width: 6),
                      const Icon(Icons.star, size: 14, color: _Palette.amber),
                      const SizedBox(width: 2),
                      Text(
                        recipe.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _Palette.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recipe.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _Palette.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    recipe.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: _Palette.textMuted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        size: 15,
                        color: _Palette.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          recipe.kcal,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: _Palette.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          recipe.difficulty,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFC65D2E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(_TrendingRecipe recipe) {
    final bg = recipe.tagIsGreen ? _Palette.greenBg : _Palette.peachBg;
    final fg = recipe.tagIsGreen ? _Palette.greenText : _Palette.peachText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        recipe.tag,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // États alternatifs
  // ---------------------------------------------------------------------------

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: _Palette.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off, size: 48, color: _Palette.heart),
          const SizedBox(height: 14),
          const Text(
            'Oups, une erreur est survenue',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _Palette.textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Impossible de contacter le serveur.\nVérifiez votre connexion et réessayez.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: _Palette.textMuted),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () => setState(() => _viewState = _ViewState.normal),
            style: ElevatedButton.styleFrom(
              backgroundColor: _Palette.brown,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: _Palette.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 48, color: _Palette.textMuted),
          const SizedBox(height: 14),
          const Text(
            'Aucune recette trouvée',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _Palette.textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Essayez un autre mot-clé ou une autre catégorie.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: _Palette.textMuted),
          ),
          const SizedBox(height: 18),
          TextButton(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _selectedCategory = null;
                _viewState = _ViewState.normal;
              });
            },
            child: const Text(
              'Réinitialiser les filtres',
              style: TextStyle(
                color: _Palette.brown,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Barre de navigation
  // ---------------------------------------------------------------------------

  Widget _buildBottomNav() {
    const items = [
      (Icons.home, 'Accueil'),
      (Icons.grid_view, 'Catégories'),
      (Icons.favorite_border, 'Favoris'),
      (Icons.person_outline, 'Profil'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: _Palette.card,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < items.length; i++)
                _buildNavItem(items[i].$1, items[i].$2, i),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final selected = _navIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _navIndex = index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? _Palette.peachBg : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 22,
                color: selected ? _Palette.brown : _Palette.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? _Palette.brown : _Palette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Image d'une recette, avec squelette de chargement et repli hors-ligne.
class _RecipeImage extends StatelessWidget {
  const _RecipeImage({required this.recipe});

  final _TrendingRecipe recipe;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      recipe.imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const _Shimmer();
      },
      errorBuilder: (context, error, stack) => _fallback(),
    );
  }

  // Repli visuel (dégradé + emoji) quand l'image n'est pas disponible.
  Widget _fallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF7E2D2), Color(0xFFEBC9AE)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(recipe.emoji, style: const TextStyle(fontSize: 40)),
    );
  }
}

/// Carte « squelette » affichée pendant le chargement.
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _Palette.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AspectRatio(aspectRatio: 16 / 11, child: _Shimmer()),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _SkeletonBar(width: 70, height: 16),
                SizedBox(height: 10),
                _SkeletonBar(width: double.infinity, height: 14),
                SizedBox(height: 6),
                _SkeletonBar(width: 120, height: 12),
                SizedBox(height: 12),
                _SkeletonBar(width: 90, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(width: width, height: height, child: const _Shimmer()),
    );
  }
}

/// Effet « shimmer » réutilisable (dégradé animé qui balaie la surface).
class _Shimmer extends StatefulWidget {
  const _Shimmer();

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 - value * 2, 0),
              end: Alignment(1 - value * 2, 0),
              colors: const [
                Color(0xFFECE4DB),
                Color(0xFFF6F1EA),
                Color(0xFFECE4DB),
              ],
              stops: const [0.35, 0.5, 0.65],
            ),
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}
