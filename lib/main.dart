import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
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
