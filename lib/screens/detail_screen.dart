// Écran de détail d'une recette de RecipeBook.
//
// Reçoit une recette (pleine ou partielle). Si le contenu détaillé manque
// (cas d'une carte issue d'une catégorie), il est rechargé par id depuis
// l'API TheMealDB. Layout et design inchangés.

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
import '../widgets/detail/status_banner.dart';
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
            const StatusBanner(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
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

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RatingRow(
          rating: _meta.rating,
          reviews: _meta.reviews,
          category: _recipe.category,
        ),
        const SizedBox(height: 12),
        HeroImage(
          imageUrl: _recipe.thumbnail,
          time: _meta.time,
          emoji: _meta.emoji,
        ),
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
            'Recipes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppPalette.textDark,
            ),
          ),
          const Spacer(),
          _circleIconButton(Icons.share_outlined),
          const SizedBox(width: 4),
          _circleIconButton(
            _favorite ? Icons.favorite : Icons.favorite_border,
            color: _favorite ? AppPalette.heart : AppPalette.textDark,
            onTap: _toggleFavorite,
          ),
          const SizedBox(width: 4),
          _circleIconButton(Icons.more_vert),
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