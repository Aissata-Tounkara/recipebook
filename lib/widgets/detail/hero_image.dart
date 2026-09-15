// Grande image de la recette (avec badge durée et repli).

import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';
import '../../utils/meal_image.dart';

class HeroImage extends StatelessWidget {
  const HeroImage({super.key, required this.imageUrl, required this.time, required this.emoji});

  final String imageUrl;
  final String time;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 11,
            child: imageUrl.isEmpty
                ? _imageFallback()
                : Image.network(
                    mealImageVariant(imageUrl, size: 'medium'),
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
                color: AppPalette.card,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 14,
                    color: AppPalette.textDark,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.textDark,
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
          colors: AppPalette.imageGradient,
        ),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 56)),
    );
  }
}