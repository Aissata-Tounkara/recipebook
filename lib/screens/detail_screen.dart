// Écran de détail d'une recette de RecipeBook.
//
// Fonctionnalités mises en avant :
//  - en-tête « enregistré en local (SQLite) / mode hors-ligne » ;
//  - ajusteur de portions dynamique : les quantités des ingrédients sont
//    recalculées en temps réel par une règle de trois à partir de la recette
//    de base (4 personnes) ;
//  - liste d'ingrédients cochables (« cochez au fur et à mesure ») ;
//  - préparation pas-à-pas avec durée par étape.
//
// L'écran est autonome : il embarque par défaut la recette de démonstration
// (poulet au curry), mais accepte une recette personnalisée via le constructeur.

import 'package:flutter/material.dart';

/// Palette partagée avec l'accueil.
class _Palette {
  static const background = Color(0xFFFBF5EE);
  static const card = Colors.white;
  static const brown = Color(0xFF9E4A24);
  static const textDark = Color(0xFF2E2A26);
  static const textMuted = Color(0xFF8C8279);
  static const peachBg = Color(0xFFF7E2D2);
  static const peachText = Color(0xFFB5602A);
  static const greenBg = Color(0xFFDDEBE0);
  static const greenText = Color(0xFF3F7D5A);
  static const amber = Color(0xFFF2A93B);
  static const heart = Color(0xFFE05B4B);
}

/// Un ingrédient dont la quantité peut être mise à l'échelle (règle de trois).
class DetailIngredient {
  final String name;

  /// Quantité de base pour [RecipeDetail.basePortions] personnes.
  final double baseAmount;

  /// Unité affichée après la quantité (« g », « ml », « c. à soupe »…).
  final String unit;

  /// Arrondi appliqué à la quantité mise à l'échelle (ex. 5 pour « au gramme
  /// près ce n'est pas utile »). 0 → pas d'arrondi particulier.
  final double roundTo;

  const DetailIngredient({
    required this.name,
    required this.baseAmount,
    required this.unit,
    this.roundTo = 0,
  });

  /// Quantité formatée pour [portions] convives.
  String scaledLabel(int portions, int basePortions) {
    final ratio = portions / basePortions;
    var value = baseAmount * ratio;

    if (roundTo > 0) {
      value = (value / roundTo).round() * roundTo;
    }

    final text = _formatNumber(value);
    return unit.isEmpty ? text : '$text $unit';
  }

  static String _formatNumber(double value) {
    // Entier ? on retire les décimales. Sinon une seule décimale.
    if ((value - value.roundToDouble()).abs() < 0.05) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
  }
}

/// Une étape de préparation.
class PreparationStep {
  final String title;
  final String description;

  /// Libellé de durée / service affiché à droite (« 5 min », « Service à chaud »).
  final String meta;
  final Color accent;

  const PreparationStep({
    required this.title,
    required this.description,
    required this.meta,
    required this.accent,
  });
}

/// Toutes les données d'une recette détaillée.
class RecipeDetail {
  final String name;
  final String description;
  final String category;
  final String cookTime;
  final String difficulty;
  final String energy;
  final double rating;
  final int reviews;
  final String chefTip;
  final int basePortions;
  final List<DetailIngredient> ingredients;
  final List<PreparationStep> steps;

  /// Image d'illustration (même URL que sur la carte d'accueil).
  final String imageUrl;

  /// Emoji de repli affiché si l'image n'est pas disponible.
  final String emoji;

  const RecipeDetail({
    required this.name,
    required this.description,
    required this.category,
    required this.cookTime,
    required this.difficulty,
    required this.energy,
    required this.rating,
    required this.reviews,
    required this.chefTip,
    required this.ingredients,
    required this.steps,
    this.basePortions = 4,
    this.imageUrl = '',
    this.emoji = '🍛',
  });

  /// Recette de démonstration (poulet au curry & lait de coco).
  static const RecipeDetail sample = RecipeDetail(
    name: 'Poulet au curry & lait de coco parfumé',
    description:
        'Un classique réconfortant mijoté au lait de coco onctueux, parfumé '
        'aux épices douces et relevé d\'une touche de coriandre fraîche.',
    category: 'Poulet',
    cookTime: '35 min',
    difficulty: 'Épicé doux',
    energy: '510 kcal',
    rating: 4.8,
    reviews: 142,
    imageUrl:
        'https://images.unsplash.com/photo-1585937421612-70a008356fbe?auto=format&fit=crop&w=800&q=60',
    emoji: '🍛',
    chefTip:
        'Pour une sauce encore plus veloutée, ajoutez une cuillère à soupe de '
        'beurre de cacahuète crémeux ou une pincée de curcuma en début de cuisson.',
    ingredients: [
      DetailIngredient(
        name: 'Blancs de poulet coupés en dés',
        baseAmount: 600,
        unit: 'g',
        roundTo: 5,
      ),
      DetailIngredient(
        name: 'Lait de coco onctueux',
        baseAmount: 400,
        unit: 'ml',
        roundTo: 5,
      ),
      DetailIngredient(
        name: 'Pâte de curry jaune doux',
        baseAmount: 2,
        unit: 'c. à soupe',
      ),
      DetailIngredient(name: 'Oignon émincé', baseAmount: 1, unit: 'gros'),
      DetailIngredient(
        name: 'Ail frais écrasé',
        baseAmount: 2,
        unit: 'gousses',
      ),
      DetailIngredient(
        name: 'Gingembre frais râpé',
        baseAmount: 1,
        unit: 'c. à café',
      ),
      DetailIngredient(
        name: 'Riz basmati parfumé',
        baseAmount: 200,
        unit: 'g',
        roundTo: 5,
      ),
      DetailIngredient(
        name: 'Coriandre fraîche & citron vert',
        baseAmount: 1,
        unit: 'bouquet',
      ),
    ],
    steps: [
      PreparationStep(
        title: 'Faire dorer le poulet',
        meta: '5 min',
        accent: _Palette.brown,
        description:
            'Faire chauffer un filet d\'huile dans une cocotte et saisir les '
            'morceaux de poulet 5 minutes jusqu\'à légère coloration dorée sur '
            'toutes les faces.',
      ),
      PreparationStep(
        title: 'Suer les aromates',
        meta: '3 min',
        accent: _Palette.amber,
        description:
            'Ajouter l\'oignon émincé, l\'ail et le gingembre frais râpé. '
            'Laisser fondre 3 minutes, puis incorporer la pâte de curry jaune '
            'en remuant bien.',
      ),
      PreparationStep(
        title: 'Mijoter au lait de coco',
        meta: '20 min',
        accent: _Palette.brown,
        description:
            'Verser le lait de coco onctueux, mélanger délicatement pour '
            'décoller les sucs de cuisson et laisser mijoter à feu doux pendant '
            '20 minutes en remuant régulièrement.',
      ),
      PreparationStep(
        title: 'Dressage & Dégustation',
        meta: 'Service à chaud',
        accent: _Palette.greenText,
        description:
            'Parsemer généreusement de coriandre fraîche ciselée et servir '
            'immédiatement accompagné du riz basmati bien chaud et d\'un '
            'quartier de citron vert pressé.',
      ),
    ],
  );
}

class DetailScreen extends StatefulWidget {
  final RecipeDetail recipe;

  /// État initial du favori (repris de la carte d'accueil).
  final bool initiallyFavorite;

  /// Notifié à chaque changement de favori pour synchroniser l'accueil.
  final ValueChanged<bool>? onFavoriteChanged;

  const DetailScreen({
    super.key,
    this.recipe = RecipeDetail.sample,
    this.initiallyFavorite = true,
    this.onFavoriteChanged,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late int _portions = widget.recipe.basePortions;
  late bool _favorite = widget.initiallyFavorite;
  final Set<int> _checked = {};

  static const List<int> _presets = [2, 4, 6, 8];

  RecipeDetail get _recipe => widget.recipe;

  void _toggleFavorite() {
    setState(() => _favorite = !_favorite);
    widget.onFavoriteChanged?.call(_favorite);
  }

  void _setPortions(int value) {
    final clamped = value.clamp(1, 20);
    if (clamped != _portions) setState(() => _portions = clamped);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildAppBar(),
            _buildStatusBanner(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRatingRow(),
                        const SizedBox(height: 12),
                        _buildHeroImage(),
                        const SizedBox(height: 16),
                        Text(
                          _recipe.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: _Palette.textDark,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _recipe.description,
                          style: const TextStyle(
                            fontSize: 14.5,
                            color: _Palette.textMuted,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _buildInfoGrid(),
                        const SizedBox(height: 18),
                        _buildChefTip(),
                        const SizedBox(height: 20),
                        _buildPortionAdjuster(),
                        const SizedBox(height: 20),
                        _buildIngredients(),
                        const SizedBox(height: 20),
                        _buildPreparation(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ---------------------------------------------------------------------------
  // Barre supérieure + bandeau de statut
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
              color: _Palette.textDark,
            ),
          ),
          const Spacer(),
          _circleIconButton(Icons.share_outlined),
          const SizedBox(width: 4),
          _circleIconButton(
            _favorite ? Icons.favorite : Icons.favorite_border,
            color: _favorite ? _Palette.heart : _Palette.textDark,
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
        child: Icon(icon, size: 22, color: color ?? _Palette.textDark),
      ),
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _Palette.greenBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.save_alt, size: 16, color: _Palette.greenText),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Enregistré en local (SQLite) • Mode hors-ligne',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _Palette.greenText,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _Palette.greenText,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'ACTIF',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingRow() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _Palette.card,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, size: 15, color: _Palette.amber),
              const SizedBox(width: 4),
              Text(
                _recipe.rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _Palette.textDark,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${_recipe.reviews} avis)',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: _Palette.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _Palette.peachBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _recipe.category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: _Palette.peachText,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 11,
            child: _recipe.imageUrl.isEmpty
                ? _imageFallback()
                : Image.network(
                    _recipe.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) =>
                        progress == null ? child : _imageFallback(),
                    errorBuilder: (context, error, stack) => _imageFallback(),
                  ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _Palette.card,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 14,
                    color: _Palette.textDark,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _recipe.cookTime,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _Palette.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF7E2D2), Color(0xFFEBC9AE)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(_recipe.emoji, style: const TextStyle(fontSize: 56)),
    );
  }

  // ---------------------------------------------------------------------------
  // Grille d'informations
  // ---------------------------------------------------------------------------

  Widget _buildInfoGrid() {
    final items = [
      (Icons.restaurant, 'Base recette', '${_recipe.basePortions} portions'),
      (Icons.schedule, 'Cuisson', _recipe.cookTime),
      (Icons.signal_cellular_alt, 'Niveau', _recipe.difficulty),
      (Icons.local_fire_department, 'Énergie', _recipe.energy),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _infoTile(items[0])),
            const SizedBox(width: 12),
            Expanded(child: _infoTile(items[1])),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _infoTile(items[2])),
            const SizedBox(width: 12),
            Expanded(child: _infoTile(items[3])),
          ],
        ),
      ],
    );
  }

  Widget _infoTile((IconData, String, String) item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _Palette.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _Palette.peachBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.$1, size: 18, color: _Palette.peachText),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.$2,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _Palette.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.$3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _Palette.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChefTip() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Palette.greenBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _Palette.greenText,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.emoji_objects_outlined,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Astuce du Chef',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: _Palette.greenText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _recipe.chefTip,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF3C5A48),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Ajusteur de portions dynamique
  // ---------------------------------------------------------------------------

  Widget _buildPortionAdjuster() {
    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _Palette.peachBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tune,
                  size: 18,
                  color: _Palette.peachText,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ajusteur de portions dynamique',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _Palette.textDark,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Règle de trois en temps réel',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: _Palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _Palette.greenBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Affichage : $_portions convives',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _Palette.greenText,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _stepperButton(Icons.remove, () => _setPortions(_portions - 1)),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$_portions',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: _Palette.brown,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'pers.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _Palette.textDark,
                      ),
                    ),
                    const Text(
                      'portions ajustées',
                      style: TextStyle(fontSize: 12, color: _Palette.textMuted),
                    ),
                  ],
                ),
              ),
              _stepperButton(Icons.add, () => _setPortions(_portions + 1)),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Préréglages rapides :',
            style: TextStyle(fontSize: 12.5, color: _Palette.textMuted),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < _presets.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: _presetChip(_presets[i])),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _Palette.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.sync, size: 16, color: _Palette.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Les quantités ci-dessous se recalculent instantanément '
                    'sur la base originale de ${_recipe.basePortions} personnes.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _Palette.textMuted,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepperButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: _Palette.peachBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: _Palette.brown, size: 26),
      ),
    );
  }

  Widget _presetChip(int value) {
    final selected = _portions == value;
    final isDefault = value == _recipe.basePortions;
    return GestureDetector(
      onTap: () => _setPortions(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _Palette.greenText : _Palette.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _Palette.greenText : const Color(0xFFEDE3D8),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : _Palette.textDark,
              ),
            ),
            Text(
              isDefault ? 'pers.\n(défaut)' : 'pers.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                height: 1.1,
                color: selected ? Colors.white : _Palette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Ingrédients
  // ---------------------------------------------------------------------------

  Widget _buildIngredients() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Flexible(
                child: Text(
                  'Ingrédients',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _Palette.textDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _Palette.peachBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_recipe.ingredients.length} éléments',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _Palette.peachText,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Spacer(),
              const Flexible(
                child: Text(
                  'Cochez au fur et à mesure',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 11.5, color: _Palette.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < _recipe.ingredients.length; i++)
            _ingredientRow(i, _recipe.ingredients[i]),
        ],
      ),
    );
  }

  Widget _ingredientRow(int index, DetailIngredient ingredient) {
    final checked = _checked.contains(index);
    return InkWell(
      onTap: () {
        setState(() {
          if (checked) {
            _checked.remove(index);
          } else {
            _checked.add(index);
          }
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: checked ? _Palette.greenText : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: checked ? _Palette.greenText : const Color(0xFFCFC4B8),
                  width: 1.5,
                ),
              ),
              child: checked
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                ingredient.name,
                style: TextStyle(
                  fontSize: 14,
                  color: checked ? _Palette.textMuted : _Palette.textDark,
                  decoration: checked
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _Palette.peachBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                ingredient.scaledLabel(_portions, _recipe.basePortions),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _Palette.peachText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Préparation
  // ---------------------------------------------------------------------------

  Widget _buildPreparation() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Flexible(
                child: Text(
                  'Préparation',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _Palette.textDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _Palette.greenBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_recipe.steps.length} étapes pas-à-pas',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _Palette.greenText,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < _recipe.steps.length; i++)
            _stepRow(
              i + 1,
              _recipe.steps[i],
              isLast: i == _recipe.steps.length - 1,
            ),
        ],
      ),
    );
  }

  Widget _stepRow(int number, PreparationStep step, {required bool isLast}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: step.accent,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        step.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _Palette.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 12,
                          color: _Palette.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          step.meta,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: _Palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  step.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _Palette.textMuted,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Barre inférieure
  // ---------------------------------------------------------------------------

  Widget _buildBottomBar() {
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
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _Palette.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.share_outlined,
                  color: _Palette.textDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _toggleFavorite,
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _Palette.brown,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _favorite ? Icons.favorite : Icons.favorite_border,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _favorite
                                ? 'Sauvegardé dans mes favoris'
                                : 'Ajouter à mes favoris',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
