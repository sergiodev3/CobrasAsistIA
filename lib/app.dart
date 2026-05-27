import 'package:flutter/material.dart';

import 'view/home_page.dart';

class CobrasApp extends StatelessWidget {
  const CobrasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CobrasAsistIA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
