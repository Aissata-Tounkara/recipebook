// Écran de détail d'une recette de RecipeBook.
//
// Reçoit une recette (pleine ou partielle). Si le contenu détaillé manque
// (cas d'une carte issue d'une catégorie), il est rechargé par id depuis
// l'API TheMealDB. Sur grand écran, le contenu passe en deux colonnes.

import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../theme/app_palette.dart';
import '../utils/recipe_meta.dart';
import '../utils/responsive.dart';
import '../widgets/detail/chef_tip_card.dart';
import '../widgets/detail/detail_bottom_bar.dart';
import '../widgets/detail/hero_image.dart';
import '../widgets/detail/info_grid.dart';
import '../widgets/detail/ingredient_list.dart';
import '../widgets/detail/portion_adjuster.dart';
import '../widgets/detail/preparation_list.dart';
import '../widgets/detail/rating_row.dart';
import '../widgets/shimmer.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({
    super.key,
    required this.recipe,
    this.initiallyFavorite = false,
    this.onFavoriteChanged,
    this.api,
    this.database,
  });

  final Recipe recipe;

  /// État initial du favori (repris de la liste).
  final bool initiallyFavorite;

  /// Notifié à chaque changement de favori pour synchroniser la liste.
  final ValueChanged<bool>? onFavoriteChanged;

  final ApiService? api;
  final DatabaseService? database;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  Recipe _recipe = const Recipe(
    id: '',
    name: '',
    category: '',
    instructions: '',
    thumbnail: '',
    ingredients: [],
  );

  late bool _favorite = widget.initiallyFavorite;
  late int _portions;
  bool _loading = false;

  RecipeMeta get _meta => RecipeMeta.from(_recipe);

  @override
  void initState() {
    super.initState();
    _recipe = widget.recipe;
    _portions = widget.recipe.basePortions;

    final missingDetails =
        _recipe.ingredients.isEmpty && _recipe.instructions.isEmpty;
    if (missingDetails && widget.api != null) {
      _loadRecipe();
    }
    _loadFavoriteState();
  }

  Future<void> _loadFavoriteState() async {
    final database = widget.database;
    if (database == null || _recipe.id.isEmpty) return;
    try {
      final saved = await database.isFavorite(_recipe.id);
      if (mounted && saved != _favorite) {
        setState(() => _favorite = saved);
      }
    } catch (_) {}
  }

  Future<void> _loadRecipe() async {
    setState(() => _loading = true);
    try {
      final full = await widget.api!.getRecipeById(_recipe.id);
      if (mounted && full != null) {
        setState(() {
          _recipe = full;
          if (_portions <= 1) _portions = full.basePortions;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggleFavorite() async {
    final next = !_favorite;
    setState(() => _favorite = next);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          backgroundColor: next ? AppPalette.greenText : AppPalette.textMuted,
          content: Row(
            children: [
              Icon(
                next ? Icons.favorite : Icons.favorite_border,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  next ? 'Ajoutée à vos favoris' : 'Retirée de vos favoris',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

    final database = widget.database;
    if (database != null && _recipe.id.isNotEmpty) {
      try {
        if (next) {
          await database.addFavorite(_recipe);
        } else {
          await database.removeFavorite(_recipe.id);
        }
      } catch (_) {}
    }
    widget.onFavoriteChanged?.call(next);
  }

  void _setPortions(int value) {
    if (value != _portions) setState(() => _portions = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(_edge, 8, _edge, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: _isWide
                          ? Breakpoints.contentWide
                          : _compactMaxWidth,
                    ),
                    child: _loading ? _buildLoadingBody() : _buildBody(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DetailBottomBar(
        isFavorite: _favorite,
        onFavoriteToggle: _toggleFavorite,
      ),
    );
  }

  // Largeur de page compacte (mobile) et marges latérales associées.
  static const double _compactMaxWidth = 640;

  double get _edge => _isWide ? 24 : 16;

  bool get _isWide => MediaQuery.sizeOf(context).width >= Breakpoints.navRail;

  Widget _buildBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < Breakpoints.detailTwoColumns) {
          return _buildCompactBody();
        }
        return _buildWideBody();
      },
    );
  }

  // Version mobile : une seule colonne (comportement historique).
  Widget _buildCompactBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RatingRow(
          rating: _meta.rating,
          reviews: _meta.reviews,
          category: _recipe.category,
        ),
        const SizedBox(height: 12),
        HeroImage(imageUrl: _recipe.thumbnail, time: _meta.time),
        const SizedBox(height: 16),
        Text(
          _recipe.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppPalette.textDark,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _meta.description,
          style: const TextStyle(
            fontSize: 14.5,
            color: AppPalette.textMuted,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 18),
        InfoGrid(
          basePortions: _recipe.basePortions,
          cookTime: _meta.time,
          difficulty: _meta.difficulty,
          energy: _meta.kcal,
        ),
        const SizedBox(height: 18),
        ChefTipCard(tip: _meta.chefTip),
        const SizedBox(height: 20),
        PortionAdjuster(
          portions: _portions,
          basePortions: _recipe.basePortions,
          onChanged: _setPortions,
        ),
        const SizedBox(height: 20),
        IngredientList(
          ingredients: _recipe.ingredients,
          basePortions: _recipe.basePortions,
          portions: _portions,
        ),
        const SizedBox(height: 20),
        PreparationList(steps: _splitInstructions(_recipe.instructions)),
      ],
    );
  }

  // Version grand écran : le contenu est réparti en deux colonnes. La
  // gauche contient l'image et la présentation (note, titre, description,
  // infos, astuce) ; la droite l'ajusteur de portions, les ingrédients et
  // la préparation.
  Widget _buildWideBody() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 5, child: _buildWideLeftColumn()),
        const SizedBox(width: 28),
        Expanded(flex: 6, child: _buildWideRightColumn()),
      ],
    );
  }

  Widget _buildWideLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RatingRow(
          rating: _meta.rating,
          reviews: _meta.reviews,
          category: _recipe.category,
        ),
        const SizedBox(height: 12),
        HeroImage(imageUrl: _recipe.thumbnail, time: _meta.time),
        const SizedBox(height: 16),
        Text(
          _recipe.name,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: AppPalette.textDark,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _meta.description,
          style: const TextStyle(
            fontSize: 15,
            color: AppPalette.textMuted,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 22),
        InfoGrid(
          basePortions: _recipe.basePortions,
          cookTime: _meta.time,
          difficulty: _meta.difficulty,
          energy: _meta.kcal,
        ),
        const SizedBox(height: 22),
        ChefTipCard(tip: _meta.chefTip),
      ],
    );
  }

  Widget _buildWideRightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PortionAdjuster(
          portions: _portions,
          basePortions: _recipe.basePortions,
          onChanged: _setPortions,
        ),
        const SizedBox(height: 20),
        IngredientList(
          ingredients: _recipe.ingredients,
          basePortions: _recipe.basePortions,
          portions: _portions,
        ),
        const SizedBox(height: 20),
        PreparationList(steps: _splitInstructions(_recipe.instructions)),
      ],
    );
  }

  // Corps de chargement : on garde la structure mais on remplace le contenu
  // non encore disponible par des blocs « shimmer ».
  Widget _buildLoadingBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 30,
          width: 140,
          decoration: BoxDecoration(
            color: AppPalette.peachBg,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 12),
        const AspectRatio(aspectRatio: 16 / 11, child: Shimmer()),
        const SizedBox(height: 16),
        const ShimmerBar(width: double.infinity, height: 24),
        const SizedBox(height: 8),
        const ShimmerBar(width: 240, height: 14),
        const SizedBox(height: 24),
        const ShimmerBar(width: double.infinity, height: 120),
        const SizedBox(height: 18),
        const ShimmerBar(width: double.infinity, height: 160),
        const SizedBox(height: 18),
        const ShimmerBar(width: double.infinity, height: 220),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Barre supérieure
  // ---------------------------------------------------------------------------

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          _circleIconButton(
            Icons.arrow_back,
            onTap: () {
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            },
          ),
          const SizedBox(width: 4),
          const Text(
            'Recettes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppPalette.textDark,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _circleIconButton(IconData icon, {Color? color, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(icon, size: 22, color: color ?? AppPalette.textDark),
      ),
    );
  }

  // Découpe les instructions en étapes lisibles (paragraphe par paragraphe).
  static List<String> _splitInstructions(String instructions) {
    final raw = instructions.replaceAll('\r\n', '\n');
    final lines = raw
        .split(RegExp(r'\n+'))
        .map((line) => line.trim().replaceFirst(RegExp(r'^\d+[.)]\s*'), ''))
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty && raw.trim().isNotEmpty) return [raw.trim()];
    return lines;
  }
}
