// Constantes et aides pour l'adaptation des écrans grands formats.

/// Points de rupture et largeurs de contenu partagés par tous les écrans.
abstract final class Breakpoints {
  /// À partir de cette largeur, les grilles de cartes passent à 3 colonnes.
  static const double gridTablet = 600;

  /// À partir de cette largeur, les grilles de cartes passent à 4 colonnes.
  static const double gridDesktop = 1000;

  /// À partir de cette largeur, la page de recette passe en deux colonnes.
  static const double detailTwoColumns = 900;

  /// À partir de cette largeur, la navigation devient un rail latéral.
  static const double navRail = 1024;

  /// Largeur maximale des contenus sur petit / tablette.
  static const double contentCompact = 900;

  /// Largeur maximale des contenus sur grand écran.
  static const double contentWide = 1180;
}

/// Nombre de colonnes des grilles de cartes selon la largeur disponible.
int gridColumnsFor(double width) {
  if (width >= Breakpoints.gridDesktop) return 4;
  if (width >= Breakpoints.gridTablet) return 3;
  return 2;
}

/// Largeur maximale de contenu selon la largeur de l'écran.
double contentMaxWidth(double screenWidth) {
  return screenWidth >= Breakpoints.navRail
      ? Breakpoints.contentWide
      : Breakpoints.contentCompact;
}
