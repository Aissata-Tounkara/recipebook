// ============================================================================
// FICHIER : portion_calculator.dart
// RÔLE    : Recalculer les quantités d'ingrédients selon les portions.
// ============================================================================

class PortionCalculator {
  // Recalcule la quantité d'un ingrédient selon le nombre de portions
  static String scaleMeasure(
    String measure, {
    required int basePortions,
    required int targetPortions,
  }) {
    final text = measure.trim();

    // 1. Si vide ou si les portions ne changent pas
    if (text.isEmpty || basePortions <= 0 || targetPortions <= 0 || basePortions == targetPortions) {
      return text;
    }

    final ratio = targetPortions / basePortions;

    // 2. Trouve une fraction (ex: "1/2", "1 1/2") ou un nombre (ex: "200", "1.5")
    final match = RegExp(r'(?:\d+\s+)?\d+/\d+|\d+(?:\.\d+)?').firstMatch(text);
    if (match == null) return text; // Pas de chiffre (ex: "Pinch")

    final str = match.group(0)!;
    double? val;

    // 3. Conversion du texte en nombre
    if (str.contains(' ') && str.contains('/')) {
      final parts = str.split(RegExp(r'\s+'));
      final whole = double.tryParse(parts[0]) ?? 0;
      val = whole + (_parseFraction(parts[1]) ?? 0);
    } else if (str.contains('/')) {
      val = _parseFraction(str);
    } else {
      val = double.tryParse(str);
    }

    if (val == null) return text;

    // 4. Calcul de la nouvelle valeur et formatage
    final formatted = _format(val * ratio);

    // 5. Remplacement dans le texte
    return text.replaceRange(match.start, match.end, formatted);
  }

  // Calcule la fraction (ex: "1/2" -> 0.5)
  static double? _parseFraction(String f) {
    final parts = f.split('/');
    final a = double.tryParse(parts[0]) ?? 0;
    final b = double.tryParse(parts[1]) ?? 1;
    return b != 0 ? a / b : null;
  }

  // Formate proprement le résultat (ex: 2.0 -> "2", 0.5 -> "1/2", 1.5 -> "1 1/2")
  static String _format(double v) {
    if ((v - v.round()).abs() < 0.01) return '${v.round()}';

    final whole = v.floor();
    final rem = v - whole;

    String? frac;
    if ((rem - 0.5).abs() < 0.05) {
      frac = '1/2';
    } else if ((rem - 0.25).abs() < 0.05) {
      frac = '1/4';
    } else if ((rem - 0.75).abs() < 0.05) {
      frac = '3/4';
    } else if ((rem - 0.33).abs() < 0.05) {
      frac = '1/3';
    } else if ((rem - 0.67).abs() < 0.05) {
      frac = '2/3';
    }

    if (frac != null) return whole > 0 ? '$whole $frac' : frac;
    return v.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
  }
}
