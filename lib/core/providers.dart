import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/database/app_database.dart';
import '../data/database/flashcards_dao.dart';
import '../data/database/tareas_dao.dart';
import '../mcp_tools/mcp_channel.dart';

// ------------------------------------------------------------------
// Capa de datos (SQLite)
// ------------------------------------------------------------------

/// Abre la base de datos local una sola vez por sesión.
final databaseProvider = FutureProvider<Database>((ref) async {
  final db = await AppDatabase.open();
  ref.onDispose(() async => db.close());
  return db;
});

/// DAO de tareas, depende de que la BD esté abierta.
final tareasDaoProvider = FutureProvider<TareasDao>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return TareasDao(db);
});

/// DAO de flashcards.
final flashcardsDaoProvider = FutureProvider<FlashcardsDao>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return FlashcardsDao(db);
});

// ------------------------------------------------------------------
// Capa MCP (servidor local in-process + cliente)
// ------------------------------------------------------------------

/// Conexión MCP totalmente inicializada (handshake completado).
///
/// Depende de los DAOs porque el servidor necesita inyectarlos a sus tools.
final mcpConnectionProvider = FutureProvider<CobrasMcpConnection>((ref) async {
  final tareasDao = await ref.watch(tareasDaoProvider.future);
  final flashcardsDao = await ref.watch(flashcardsDaoProvider.future);

  final conn = await conectarMcpEnMemoria(
    tareasDao: tareasDao,
    flashcardsDao: flashcardsDao,
  );
  ref.onDispose(() async => conn.close());
  return conn;
});

// ------------------------------------------------------------------
// Capa de IA (Gemini)
// ------------------------------------------------------------------

/// Modelo Gemini multimodal, configurado con las herramientas MCP.
///
/// La API key se carga desde `.env` (ver main.dart).
final geminiModelProvider = Provider<GenerativeModel>((ref) {
  final apiKey = dotenv.env['GEMINI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty || apiKey == 'tu_api_key_aqui') {
    throw StateError(
      'Falta GEMINI_API_KEY en el archivo .env. '
      'Copia .env.example a .env y agrega tu API key.',
    );
  }
  return GenerativeModel(
    // Modelo rápido y económico que soporta entrada multimodal y tool use.
    model: 'gemini-1.5-flash',
    apiKey: apiKey,
    tools: obtenerToolsParaGemini(),
    systemInstruction: Content.system(
      'Eres un asistente educativo para estudiantes de preparatoria. '
      'Cuando recibas la foto de un apunte o pizarrón: '
      '1) Si detectas una tarea/deber pendiente, llama a `guardar_tarea_db`. '
      '2) Si detectas conceptos, definiciones o material de estudio, '
      'genera flashcards y llama a `guardar_flashcards_db`. '
      'Puedes llamar a las dos herramientas si aplican. '
      'Responde siempre en español.',
    ),
  );
});

// ------------------------------------------------------------------
// Backend remoto (Supabase) — placeholder para iteración futura
// ------------------------------------------------------------------

/// Cliente de Supabase. Por ahora devuelve `null`: el provider está listo para
/// extenderse, pero la funcionalidad remota no es parte del MVP.
final supabaseClientProvider = Provider<SupabaseClient?>((ref) => null);
