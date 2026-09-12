// Carte de recette utilisée sur l'accueil et dans les favoris.

import 'dart:io';

import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../theme/app_palette.dart';
import '../utils/meal_image.dart';
import '../utils/recipe_meta.dart';
import 'shimmer.dart';

class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.recipe,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggle,
    this.thumbnailFile,
  });

  final Recipe recipe;
  final bool isFavorite;
  final VoidCallback onTap;
  final ValueChanged<bool> onFavoriteToggle;

  /// Miniature en cache (hors-ligne), si elle existe.
  final File? thumbnailFile;

  @override
  Widget build(BuildContext context) {
    final meta = RecipeMeta.from(recipe);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppPalette.card,
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
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 11,
                  child: _RecipeImage(
                    imageUrl: recipe.thumbnail,
                    thumbnailFile: thumbnailFile,
                    emoji: meta.emoji,
                  ),
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
                          meta.time,
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
                    onTap: () => onFavoriteToggle(!isFavorite),
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
                        color: AppPalette.heart,
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
                  Row(
                    children: [
                      Flexible(child: _Tag(tag: meta.tag, isGreen: meta.tagIsGreen)),
                      const SizedBox(width: 6),
                      const Icon(Icons.star, size: 14, color: AppPalette.amber),
                      const SizedBox(width: 2),
                      Text(
                        meta.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppPalette.textDark,
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
                      color: AppPalette.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppPalette.textMuted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        size: 15,
                        color: AppPalette.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          meta.kcal,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppPalette.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          meta.difficulty,
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
}

class _Tag extends StatelessWidget {
  const _Tag({required this.tag, required this.isGreen});

  final String tag;
  final bool isGreen;

  @override
  Widget build(BuildContext context) {
    final bg = isGreen ? AppPalette.greenBg : AppPalette.peachBg;
    final fg = isGreen ? AppPalette.greenText : AppPalette.peachText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        tag,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

/// Image d'une recette, avec squelette de chargement et repli hors-ligne.
class _RecipeImage extends StatelessWidget {
  const _RecipeImage({
    required this.imageUrl,
    required this.emoji,
    this.thumbnailFile,
  });

  final String imageUrl;
  final String emoji;
  final File? thumbnailFile;

  @override
  Widget build(BuildContext context) {
    if (thumbnailFile != null) {
      return Image.file(
        thumbnailFile!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => _fallback(),
      );
    }

    if (imageUrl.isEmpty) return _fallback();

    return Image.network(
      mealImageVariant(imageUrl, size: 'small'),
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Shimmer();
      },
      errorBuilder: (context, error, stack) => _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppPalette.imageGradient,
        ),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 40)),
    );
  }
}