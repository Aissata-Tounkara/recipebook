// ============================================================================
// FICHIER : portion_calculator.dart
// ROLE    : Utilitaire pour recalculer et formater les quantités d'ingrédients
//           selon le nombre de portions choisi par l'utilisateur.
// ============================================================================

/// Classe utilitaire contenant les fonctions pures pour le calcul des portions.
///
/// Dans l'API TheMealDB, les quantités (`measure`) sont stockées sous forme de texte
/// libre, par exemple :
/// - Nombres entiers : "200g", "2 eggs", "4 cloves"
/// - Nombres décimaux : "1.5 tbsp", "0.5 cup"
/// - Fractions simples : "1/2 tsp", "3/4 cup"
/// - Fractions mixtes : "1 1/2 cups", "2 1/4 tsp"
/// - Plages de valeurs : "1-2 tbsp"
/// - Termes non numériques : "Pinch", "to taste", "Dash"
class PortionCalculator {
  // Constructeur privé pour empêcher l'instanciation (classe d'utilitaires statiques).
  const PortionCalculator._();

  /// Recalcule et adapte une mesure d'ingrédient en fonction du ratio de portions.
  ///
  /// Paramètres :
  /// - [measure]        : La chaîne d'origine (ex: "200g", "1/2 tsp", "Pinch").
  /// - [basePortions]   : Le nombre de portions de référence de la recette (ex: 4).
  /// - [targetPortions] : Le nombre de portions souhaité par l'utilisateur (ex: 2 ou 6).
  ///
  /// Retourne la mesure recalculée sous forme de texte (ex: "100g", "1/4 tsp", "Pinch").
  static String scaleMeasure(
    String measure, {
    required int basePortions,
    required int targetPortions,
  }) {
    final cleanMeasure = measure.trim();

    // 1. Cas de base : si la chaîne est vide ou si les portions sont invalides/égales,
    //    on renvoie directement le texte d'origine sans modification.
    if (cleanMeasure.isEmpty ||
        basePortions <= 0 ||
        targetPortions <= 0 ||
        basePortions == targetPortions) {
      return cleanMeasure;
    }

    // 2. Calcul du facteur multiplicateur (ex: 6 portions pour 4 initiales -> ratio = 1.5)
    final double ratio = targetPortions / basePortions;

    // 3. Expression régulière pour identifier les nombres au début ou dans la mesure :
    //    - Fraction mixte : "1 1/2" ou "2  3/4"
    //    - Fraction simple : "1/2" ou "3/4"
    //    - Décimal ou entier : "200", "1.5", "0.25"
    //
    //    Regex expliquée :
    //    `(?:\d+\s+)?\d+\/\d+|\d+(?:\.\d+)?`
    //    - `(?:\d+\s+)?\d+\/\d+` : correspond à une fraction avec ou sans entier devant (ex: "1 1/2" ou "1/2")
    //    - `|\d+(?:\.\d+)?`      : OU un entier / nombre à virgule (ex: "200", "1.5")
    final regex = RegExp(r'(?:\d+\s+)?\d+\/\d+|\d+(?:\.\d+)?');

    // On cherche la première occurrence d'un nombre ou d'une fraction
    final match = regex.firstMatch(cleanMeasure);

    // Si aucun nombre n'est détecté (ex: "Pinch", "to taste", "Salt"),
    // on conserve le texte original tel quel.
    if (match == null) {
      return cleanMeasure;
    }

    final numberStr = match.group(0)!;
    final double? parsedValue = _parseNumericValue(numberStr);

    // Si l'extraction mathématique a échoué, on garde l'original.
    if (parsedValue == null) {
      return cleanMeasure;
    }

    // 4. Calcul de la nouvelle quantité
    final double scaledValue = parsedValue * ratio;

    // 5. Formatage propre du nombre (ex: 1.5 -> "1 1/2" ou "1.5", 2.0 -> "2")
    final String formattedNumber = _formatValue(scaledValue);

    // 6. Remplacement du nombre d'origine par le nouveau nombre dans la chaîne
    //    (ce qui conserve les unités comme "g", "ml", "tbsp", "cups", etc.)
    return cleanMeasure.replaceRange(match.start, match.end, formattedNumber);
  }

  /// Convertit une chaîne représentant un nombre (entier, décimal, fraction) en `double`.
  static double? _parseNumericValue(String str) {
    final trimmed = str.trim();

    // Cas A : Fraction mixte (ex: "1 1/2")
    if (trimmed.contains(' ') && trimmed.contains('/')) {
      final parts = trimmed.split(RegExp(r'\s+'));
      if (parts.length == 2) {
        final whole = double.tryParse(parts[0]);
        final fraction = _parseSimpleFraction(parts[1]);
        if (whole != null && fraction != null) {
          return whole + fraction;
        }
      }
    }

    // Cas B : Fraction simple (ex: "1/2", "3/4")
    if (trimmed.contains('/')) {
      return _parseSimpleFraction(trimmed);
    }

    // Cas C : Nombre décimal ou entier standard (ex: "200", "1.5")
    return double.tryParse(trimmed);
  }

  /// Convertit une fraction simple de type "1/2" en valeur numérique (0.5).
  static double? _parseSimpleFraction(String fractionStr) {
    final parts = fractionStr.split('/');
    if (parts.length == 2) {
      final numerator = double.tryParse(parts[0].trim());
      final denominator = double.tryParse(parts[1].trim());
      if (numerator != null && denominator != null && denominator != 0) {
        return numerator / denominator;
      }
    }
    return null;
  }

  /// Formate un `double` pour un affichage culinaire agréable à lire.
  ///
  /// Exemples :
  /// - `2.0`   -> `"2"`
  /// - `0.5`   -> `"1/2"`
  /// - `1.5`   -> `"1 1/2"`
  /// - `0.25`  -> `"1/4"`
  /// - `0.75`  -> `"3/4"`
  /// - `0.33`  -> `"1/3"`
  /// - `2.333` -> `"2.3"`
  static String _formatValue(double value) {
    // Si c'est un nombre entier exact (ou très proche d'un entier)
    if ((value - value.roundToDouble()).abs() < 0.001) {
      return value.round().toString();
    }

    // Vérification des fractions culinaires classiques
    final wholePart = value.floor();
    final remainder = value - wholePart;

    String? fractionText;
    if ((remainder - 0.5).abs() < 0.05) {
      fractionText = '1/2';
    } else if ((remainder - 0.25).abs() < 0.05) {
      fractionText = '1/4';
    } else if ((remainder - 0.75).abs() < 0.05) {
      fractionText = '3/4';
    } else if ((remainder - 0.333).abs() < 0.05) {
      fractionText = '1/3';
    } else if ((remainder - 0.666).abs() < 0.05) {
      fractionText = '2/3';
    }

    if (fractionText != null) {
      if (wholePart > 0) {
        return '$wholePart $fractionText';
      }
      return fractionText;
    }

    // Si ce n'est pas une fraction connue, on arrondit à 1 ou 2 décimales au maximum
    // en supprimant les zéros superflus à la fin (ex: 2.50 -> 2.5).
    final formatted = value.toStringAsFixed(1);
    if (formatted.endsWith('.0')) {
      return formatted.substring(0, formatted.length - 2);
    }
    return formatted;
  }
}
