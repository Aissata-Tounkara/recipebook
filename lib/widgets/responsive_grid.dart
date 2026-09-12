// Grille responsive de cartes (hauteur égale sur une même ligne).

import 'dart:math' as math;

import 'package:flutter/material.dart';

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({super.key, required this.columns, required this.children});

  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final end = math.min(i + columns, children.length);
      final rowCards = children.sublist(i, end);
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
}