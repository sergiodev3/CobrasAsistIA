import 'package:sqflite/sqflite.dart';

/// DAO para la tabla `flashcards`.
///
/// Una flashcard es una tarjeta de estudio con pregunta y respuesta. La IA
/// puede generar varias en una sola llamada, por eso ofrecemos `insertarVarias`.
class FlashcardsDao {
  FlashcardsDao(this._db);

  final Database _db;

  /// Inserta una flashcard y devuelve su id.
  Future<int> insertar({
    required String pregunta,
    required String respuesta,
    String? materia,
    String? tema,
    int dificultad = 1,
  }) {
    final ahora = DateTime.now().toIso8601String();
    return _db.rawInsert(
      '''
      INSERT INTO flashcards (pregunta, respuesta, materia, tema, dificultad, creada_en)
      VALUES (?, ?, ?, ?, ?, ?);
      ''',
      [pregunta, respuesta, materia, tema, dificultad, ahora],
    );
  }

  /// Inserta varias flashcards dentro de una sola transacción.
  /// Devuelve la lista de ids generados, en el mismo orden que la entrada.
  Future<List<int>> insertarVarias(List<Map<String, Object?>> tarjetas) async {
    final ids = <int>[];
    await _db.transaction((txn) async {
      final ahora = DateTime.now().toIso8601String();
      for (final t in tarjetas) {
        final id = await txn.rawInsert(
          '''
          INSERT INTO flashcards (pregunta, respuesta, materia, tema, dificultad, creada_en)
          VALUES (?, ?, ?, ?, ?, ?);
          ''',
          [
            t['pregunta'],
            t['respuesta'],
            t['materia'],
            t['tema'],
            t['dificultad'] ?? 1,
            ahora,
          ],
        );
        ids.add(id);
      }
    });
    return ids;
  }

  Future<List<Map<String, Object?>>> listarTodas() {
    return _db.rawQuery('SELECT * FROM flashcards ORDER BY creada_en DESC;');
  }

  Future<int> eliminar(int id) {
    return _db.rawDelete('DELETE FROM flashcards WHERE id = ?;', [id]);
  }
}
