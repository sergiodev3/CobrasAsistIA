import 'package:cobras_asist_ia/mcp_tools/mcp_channel.dart';
import 'package:cobras_asist_ia/mcp_tools/tools/guardar_flashcards_tool.dart';
import 'package:cobras_asist_ia/mcp_tools/tools/guardar_tarea_tool.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Tests que verifican que las declaraciones MCP y las declaraciones Gemini
  // están sincronizadas (mismos nombres, mismos parámetros). El servidor MCP
  // completo se prueba mejor con un test de integración + sqflite_common_ffi.

  group('Declaraciones de las tools MCP', () {
    test('guardar_tarea_db tiene el nombre canónico', () {
      expect(guardarTareaMcpTool.name, 'guardar_tarea_db');
      expect(guardarTareaToolName, 'guardar_tarea_db');
      expect(guardarTareaGeminiDeclaration.name, 'guardar_tarea_db');
    });

    test('guardar_flashcards_db tiene el nombre canónico', () {
      expect(guardarFlashcardsMcpTool.name, 'guardar_flashcards_db');
      expect(guardarFlashcardsToolName, 'guardar_flashcards_db');
      expect(guardarFlashcardsGeminiDeclaration.name, 'guardar_flashcards_db');
    });

    test('guardar_tarea_db expone los campos esperados', () {
      final schema = guardarTareaMcpTool.inputSchema;
      expect(schema.properties, contains('titulo'));
      expect(schema.properties, contains('descripcion'));
      expect(schema.properties, contains('materia'));
      expect(schema.properties, contains('fecha_entrega'));
    });

    test('guardar_flashcards_db expone el campo `tarjetas`', () {
      final schema = guardarFlashcardsMcpTool.inputSchema;
      expect(schema.properties, contains('tarjetas'));
    });
  });

  group('Puente a Gemini', () {
    test('obtenerToolsParaGemini expone exactamente las 2 tools', () {
      final tools = obtenerToolsParaGemini();
      expect(tools, hasLength(1));
      final decls = tools.single.functionDeclarations;
      expect(decls, isNotNull);
      expect(decls!, hasLength(2));
      final nombres = decls.map((d) => d.name).toSet();
      expect(nombres, {'guardar_tarea_db', 'guardar_flashcards_db'});
    });
  });
}
