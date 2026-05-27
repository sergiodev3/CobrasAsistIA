import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carga las variables de entorno desde el archivo .env empaquetado como asset.
  // Contiene la GEMINI_API_KEY (ver .env.example).
  await dotenv.load(fileName: '.env');

  runApp(const ProviderScope(child: CobrasApp()));
}
