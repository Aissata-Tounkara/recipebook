// Écran des favoris (lecture hors-ligne depuis Hive).

import 'dart:io';

import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../widgets/feedback_state.dart';
import '../widgets/home_header.dart';
import '../widgets/recipe_card.dart';
import '../widgets/responsive_grid.dart';
import '../widgets/section_header.dart';
import '../widgets/shimmer.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({
    super.key,
    required this.database,
    required this.api,
    required this.favorites,
    required this.onRemoved,
    required this.onOpenRecipe,
    this.loader,
  });

  final DatabaseService database;
  final ApiService api;
  final Set<String> favorites;
  final ValueChanged<String> onRemoved;
  final void Function(Recipe recipe) onOpenRecipe;

  /// Source des favoris (injectable pour les tests). En production, les
  /// favoris sont lus depuis [database] (Hive).
  final Future<List<Recipe>> Function()? loader;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Recipe> _recipes = [];
  final Map<String, File> _thumbFiles = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final List<Recipe> recipes;
    if (widget.loader != null) {
      recipes = await widget.loader!();
    } else {
      try {
        recipes = await widget.database.getAllFavorites();
      } catch (_) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      for (final recipe in recipes) {
        _cacheThumb(recipe);
      }
    }

    if (!mounted) return;
    setState(() {
      _recipes = List.of(recipes);
      _loading = false;
    });
  }

  // Miniatures en cache chargées sans bloquer l'affichage de la liste.
  Future<void> _cacheThumb(Recipe recipe) async {
    final File? file;
    try {
      file = await widget.database.getFavoriteThumbFile(recipe.id);
    } catch (_) {
      return;
    }
    if (file == null || !mounted) return;
    final cached = file;
    setState(() => _thumbFiles[recipe.id] = cached);
  }

  void _removeLocal(String id) {
    setState(() {
      _recipes.removeWhere((r) => r.id == id);
      _thumbFiles.remove(id);
    });
    widget.onRemoved(id);
  }

  @override
  Widget build(BuildContext context) {
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
              SectionHeader(
                title: 'Mes favoris',
                badge: _loading ? null : '${_recipes.length} recettes',
              ),
              const SizedBox(height: 14),
              _buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 600 ? 3 : 2;

        if (_loading) {
          return ResponsiveGrid(
            columns: columns,
            children: List.generate(columns * 2, (_) => const SkeletonCard()),
          );
        }

        if (_recipes.isEmpty) {
          return const EmptyState(
            icon: Icons.favorite_border,
            title: 'Votre liste de favoris est vide',
            message:
                "Touchez le cœur d'une recette pour la garder précieusement\n"
                'et la retrouver ici, même sans connexion.',
          );
        }

        return ResponsiveGrid(
          columns: columns,
          children: _recipes.map((recipe) => _buildCard(recipe)).toList(),
        );
      },
    );
  }

  Widget _buildCard(Recipe recipe) {
    return RecipeCard(
      recipe: recipe,
      isFavorite: true,
      thumbnailFile: _thumbFiles[recipe.id],
      onTap: () => widget.onOpenRecipe(recipe),
      onFavoriteToggle: (_) {
        _removeLocal(recipe.id);
        // La suppression Hive est faite en arrière-plan ; toute erreur
        // (ex. plateforme indisponible en test) est ignorée.
        widget.database.removeFavorite(recipe.id).catchError((_) {});
      },
    );
  }
}