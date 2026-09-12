// Variantes d'image TheMealDB : l'API offre /small, /medium et /large en
// suffixe des URLs de recettes (voir guide de l'API). On charge la taille la
// plus adaptée pour économiser bande passante et temps de chargement.

String mealImageVariant(String url, {String size = 'small'}) {
  final trimmed = url.trim();
  if (trimmed.isEmpty || !trimmed.startsWith('http')) return trimmed;

  final withoutVariant = trimmed.replaceFirst(
    RegExp(r'/(small|medium|large)$', caseSensitive: false),
    '',
  );
  return '$withoutVariant/${size.toLowerCase()}';
}

/// URL de l'illustration d'un ingrédient TheMealDB. Le nom subit la même
/// normalisation que sur le site : minuscules et espaces remplacés par « _ »
/// (« Olive Oil » -> olive_oil.png). Renvoie '' si le nom est vide.
String ingredientImageUrl(String name, {String size = 'small'}) {
  final slug = name
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), '_')
      .replaceAll(RegExp(r'[^a-z0-9_-]'), '_');
  if (slug.isEmpty) return '';

  final base =
      'https://www.themealdb.com/images/ingredients/$slug.png';
  final variant = size.toLowerCase();
  if (variant.isEmpty || variant == 'full') return base;
  return '$base/$variant';
}