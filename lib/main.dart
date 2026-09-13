import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialise Hive avec le bon backend selon la plateforme : dossier
  // applicatif sur mobile/desktop, IndexedDB sur le web (où path_provider
  // n'est pas supporté). Sans cet appel, l'ouverture des box échoue
  // silencieusement sur le web et les favoris ne sont jamais persistés.
  await Hive.initFlutter();
  runApp(const RecipeBookApp());
}

class RecipeBookApp extends StatelessWidget {
  const RecipeBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RecipeBook',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFBF5EE),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9E4A24),
          brightness: Brightness.light,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
