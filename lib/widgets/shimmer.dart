// Effet « shimmer » réutilisable (dégradé animé qui balaie la surface).

import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

class Shimmer extends StatefulWidget {
  const Shimmer({super.key});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
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

class ShimmerBar extends StatelessWidget {
  const ShimmerBar({super.key, required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(width: width, height: height, child: const Shimmer()),
    );
  }
}

/// Carte « squelette » affichée pendant le chargement des recettes.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          const AspectRatio(aspectRatio: 16 / 11, child: Shimmer()),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBar(width: 70, height: 16),
                SizedBox(height: 10),
                ShimmerBar(width: double.infinity, height: 14),
                SizedBox(height: 6),
                ShimmerBar(width: 120, height: 12),
                SizedBox(height: 12),
                ShimmerBar(width: 90, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}