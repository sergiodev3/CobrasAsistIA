import 'package:flutter/material.dart';

import 'view/home_page.dart';

class CobrasApp extends StatelessWidget {
  const CobrasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cobras Task Asist',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7B1D2B),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF7B1D2B),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
          titleLarge: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
          titleMedium: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
          bodyLarge: TextStyle(fontSize: 16, height: 1.5),
          bodyMedium: TextStyle(fontSize: 14, height: 1.4),
          labelLarge: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
      ),
      home: const HomePage(),
    );
  }
}
