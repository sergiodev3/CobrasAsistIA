import 'package:sqflite/sqflite.dart';

/// DAO (Data Access Object) para la tabla `tareas`.
///
/// Usamos SQL crudo (rawInsert / rawQuery) para que el alumno vea exactamente
/// la consulta que se envía a SQLite, sin ORMs intermedios.
class TareasDao {
  TareasDao(this._db);

  final Database _db;

  /// Inserta una tarea y devuelve el `id` autogenerado.
  Future<int> insertar({
    required String titulo,
    String? descripcion,
    String? materia,
    String? fechaEntrega,
  }) {
    final ahora = DateTime.now().toIso8601String();
    return _db.rawInsert(
      '''
      INSERT INTO tareas (titulo, descripcion, materia, fecha_entrega, creada_en)
      VALUES (?, ?, ?, ?, ?);
      ''',
      [titulo, descripcion, materia, fechaEntrega, ahora],
    );
  }

  /// Lista todas las tareas, las más recientes primero.
  Future<List<Map<String, Object?>>> listarTodas() {
    return _db.rawQuery('SELECT * FROM tareas ORDER BY creada_en DESC;');
  }

  /// Elimina una tarea por su id.
  Future<int> eliminar(int id) {
    return _db.rawDelete('DELETE FROM tareas WHERE id = ?;', [id]);
  }
}
