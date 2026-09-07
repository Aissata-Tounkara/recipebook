// ============================================================================
// FICHIER : detail_screen_test.dart
// ROLE    : Test de widget Flutter pour valider le comportement de DetailScreen :
//           1. Affichage du spinner de chargement
//           2. Affichage des informations de la recette après chargement
//           3. Incrémentation des portions (+1) et recalcul
//           4. Décrémentation des portions (-1) et respect de la limite minimale (1)
// ============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipebook/screens/detail_screen.dart';

void main() {
  // Configuration du faux client HTTP pour simuler l'API TheMealDB et les images en local.
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  group('Tests du Widget DetailScreen', () {
    testWidgets(
        '1. Affiche un CircularProgressIndicator pendant le chargement initial',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DetailScreen(recipeId: '52771'),
        ),
      );

      // Le spinner doit être visible dès le démarrage
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
        '2. Affiche les détails de la recette (titre, portions, ingrédients) après chargement',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DetailScreen(recipeId: '52771'),
        ),
      );

      // On attend la fin de l'appel asynchrone simulé
      await tester.pumpAndSettle();

      // Vérification du titre de la recette
      expect(find.text('Spicy Arrabiata Penne'), findsAtLeastNWidgets(1));

      // Vérification de la catégorie
      expect(find.text('Vegetarian'), findsOneWidget);

      // Vérification du nombre initial de portions (4 par défaut)
      expect(find.text('4'), findsOneWidget);

      // Vérification de l'ingrédient initial (200g penne rigate)
      expect(find.textContaining('200g penne rigate'), findsOneWidget);
    });

    testWidgets(
        '3. Le bouton (+) augmente les portions et met à jour les quantités d\'ingrédients',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DetailScreen(recipeId: '52771'),
        ),
      );

      await tester.pumpAndSettle();

      // État initial : 4 portions -> 200g
      expect(find.text('4'), findsOneWidget);
      expect(find.textContaining('200g penne rigate'), findsOneWidget);

      // On fait défiler jusqu'au bouton "+" et on clique
      final addButton = find.widgetWithIcon(IconButton, Icons.add);
      await tester.ensureVisible(addButton);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // 5 portions -> 250g (200g * 5/4)
      expect(find.text('5'), findsOneWidget);
      expect(find.textContaining('250g penne rigate'), findsOneWidget);
    });

    testWidgets(
        '4. Le bouton (-) réduit les portions et se désactive à 1 portion minimum',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DetailScreen(recipeId: '52771'),
        ),
      );

      await tester.pumpAndSettle();

      final minusButton = find.widgetWithIcon(IconButton, Icons.remove);
      await tester.ensureVisible(minusButton);

      // 4 -> 3 portions (200g * 3/4 = 150g)
      await tester.tap(minusButton);
      await tester.pumpAndSettle();
      expect(find.text('3'), findsOneWidget);
      expect(find.textContaining('150g penne rigate'), findsOneWidget);

      // 3 -> 2 portions (200g * 2/4 = 100g)
      await tester.tap(minusButton);
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);
      expect(find.textContaining('100g penne rigate'), findsOneWidget);

      // 2 -> 1 portion (200g * 1/4 = 50g)
      await tester.tap(minusButton);
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);
      expect(find.textContaining('50g penne rigate'), findsOneWidget);

      // Vérification que le bouton "-" est bien désactivé à 1 portion (onPressed == null)
      final iconButton = tester.widget<IconButton>(minusButton);
      expect(iconButton.onPressed, isNull);
    });
  });
}

// ============================================================================
// CLIENT HTTP SIMULÉ (AVEC LES 8 VRAIS INGRÉDIENTS D'ARRABIATA)
// ============================================================================

const _mockRecipeJson = {
  'meals': [
    {
      'idMeal': '52771',
      'strMeal': 'Spicy Arrabiata Penne',
      'strCategory': 'Vegetarian',
      'strInstructions': 'Cuire les pâtes et mélanger avec la sauce.',
      'strMealThumb':
          'https://www.themealdb.com/images/media/meals/ustsqw1468250014.jpg',
      'strIngredient1': 'penne rigate',
      'strMeasure1': '200g',
      'strIngredient2': 'olive oil',
      'strMeasure2': '1/4 cup',
      'strIngredient3': 'garlic',
      'strMeasure3': '3 cloves',
      'strIngredient4': 'chopped tomatoes',
      'strMeasure4': '1 tin',
      'strIngredient5': 'red chilli flakes',
      'strMeasure5': '1/2 teaspoon',
      'strIngredient6': 'italian seasoning',
      'strMeasure6': '1/2 teaspoon',
      'strIngredient7': 'basil',
      'strMeasure7': '6 leaves',
      'strIngredient8': 'Parmigiano-Reggiano',
      'strMeasure8': 'sprinkling',
    }
  ]
};

final List<int> _transparentPngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _FakeHttpClient();
}

class _FakeHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _FakeHttpClientRequest(url);

  @override
  Future<HttpClientRequest> getUrl(Uri url) async =>
      _FakeHttpClientRequest(url);

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpClientRequest implements HttpClientRequest {
  final Uri url;
  _FakeHttpClientRequest(this.url);

  @override
  bool followRedirects = true;
  @override
  int maxRedirects = 5;
  @override
  int contentLength = -1;
  @override
  bool persistentConnection = true;
  @override
  bool bufferOutput = true;

  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  void add(List<int> data) {}

  @override
  void write(Object? obj) {}

  @override
  void writeln([Object? obj = ""]) {}

  @override
  void writeAll(Iterable objects, [String separator = ""]) {}

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future addStream(Stream<List<int>> stream) async {}

  @override
  Future flush() async {}

  @override
  Future abort([Object? exception, StackTrace? stackTrace]) async {}

  @override
  Future<HttpClientResponse> close() async {
    if (url.path.endsWith('.jpg') || url.path.endsWith('.png')) {
      return _FakeHttpClientResponse(_transparentPngBytes, 200);
    }
    final responseBody = jsonEncode(_mockRecipeJson);
    return _FakeHttpClientResponse(utf8.encode(responseBody), 200);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpClientResponse extends StreamView<List<int>>
    implements HttpClientResponse {
  @override
  final int statusCode;
  @override
  final String reasonPhrase = 'OK';
  @override
  final int contentLength;
  @override
  final bool isRedirect = false;
  @override
  final bool persistentConnection = true;
  @override
  final List<RedirectInfo> redirects = const [];
  @override
  final HttpClientResponseCompressionState compressionState =
      HttpClientResponseCompressionState.notCompressed;

  _FakeHttpClientResponse(List<int> bytes, this.statusCode)
      : contentLength = bytes.length,
        super(Stream.value(bytes));

  @override
  HttpHeaders get headers => _FakeHttpHeaders();

  @override
  Future<Socket> detachSocket() => throw UnsupportedError('detachSocket');

  @override
  X509Certificate? get certificate => null;

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  List<Cookie> get cookies => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _headers = {
    'content-type': ['application/json; charset=utf-8'],
  };

  @override
  bool chunkedTransferEncoding = false;

  @override
  int contentLength = -1;

  @override
  ContentType? contentType = ContentType.json;

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _headers.putIfAbsent(name.toLowerCase(), () => []).add(value.toString());
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _headers[name.toLowerCase()] = [value.toString()];
  }

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _headers.forEach(action);
  }

  @override
  List<String>? operator [](String name) => _headers[name.toLowerCase()];

  @override
  String? value(String name) => _headers[name.toLowerCase()]?.first;

  @override
  void remove(String name, Object value) {
    _headers[name.toLowerCase()]?.remove(value.toString());
  }

  @override
  void removeAll(String name) {
    _headers.remove(name.toLowerCase());
  }

  @override
  void clear() {
    _headers.clear();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
