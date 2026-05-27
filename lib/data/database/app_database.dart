import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Helper de la base de datos local de la app.
///
/// Mantenemos las consultas en SQL puro a propósito: el objetivo del proyecto es
/// pedagógico, así que el alumno ve exactamente qué se ejecuta contra SQLite.
class AppDatabase {
  AppDatabase._();

  static const String _fileName = 'cobras_asist_ia.db';
  static const int _version = 1;

  /// Abre (o crea por primera vez) la base de datos local de la app.
  static Future<Database> open() async {
    // Obtenemos el directorio de documentos del dispositivo (Android/iOS).
    final docsDir = await getApplicationDocumentsDirectory();
    final fullPath = p.join(docsDir.path, _fileName);

    return openDatabase(
      fullPath,
      version: _version,
      onCreate: _onCreate,
    );
  }

  /// Se ejecuta UNA sola vez, la primera vez que se abre la BD.
  /// Aquí creamos las tablas iniciales con SQL crudo.
  static Future<void> _onCreate(Database db, int version) async {
    // Tabla de tareas escolares detectadas por la IA.
    await db.execute('''
      CREATE TABLE tareas (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo          TEXT    NOT NULL,
        descripcion     TEXT,
        materia         TEXT,
        fecha_entrega   TEXT,
        creada_en       TEXT    NOT NULL
      );
    ''');

    // Tabla de flashcards (pregunta/respuesta) generadas a partir de apuntes.
    await db.execute('''
      CREATE TABLE flashcards (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        pregunta    TEXT    NOT NULL,
        respuesta   TEXT    NOT NULL,
        materia     TEXT,
        tema        TEXT,
        dificultad  INTEGER DEFAULT 1,
        creada_en   TEXT    NOT NULL
      );
    ''');
  }
}
