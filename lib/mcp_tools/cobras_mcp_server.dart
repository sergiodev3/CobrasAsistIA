import 'package:dart_mcp/server.dart';

import '../data/database/flashcards_dao.dart';
import '../data/database/tareas_dao.dart';
import 'tools/guardar_flashcards_tool.dart';
import 'tools/guardar_tarea_tool.dart';

/// Servidor MCP local de CobrasAsistIA.
///
/// Importante (pedagogía): el LLM nunca ejecuta código directamente — solo
/// declara, por nombre, qué herramienta quiere invocar y con qué argumentos.
/// Este servidor expone esas herramientas y, cuando el cliente MCP las llama,
/// es aquí donde se ejecuta la lógica real (insertar en SQLite).
base class CobrasMcpServer extends MCPServer with ToolsSupport {
  CobrasMcpServer.fromStreamChannel(
    super.channel, {
    required TareasDao tareasDao,
    required FlashcardsDao flashcardsDao,
  })  : _tareasDao = tareasDao,
        _flashcardsDao = flashcardsDao,
        super.fromStreamChannel(
          implementation: Implementation(
            name: 'CobrasAsistIA-mcp-server',
            version: '0.1.0',
          ),
          instructions:
              'Servidor MCP local con herramientas para guardar tareas '
              'escolares y flashcards detectadas por la IA.',
        ) {
    // Registramos las dos herramientas con sus handlers.
    // ToolsSupport valida automáticamente los args contra el inputSchema
    // antes de invocar el handler.
    registerTool(guardarTareaMcpTool, _onGuardarTarea);
    registerTool(guardarFlashcardsMcpTool, _onGuardarFlashcards);
  }

  final TareasDao _tareasDao;
  final FlashcardsDao _flashcardsDao;

  Future<CallToolResult> _onGuardarTarea(CallToolRequest request) async {
    try {
      final args = request.arguments ?? const {};
      final id = await _tareasDao.insertar(
        titulo: args['titulo'] as String,
        descripcion: args['descripcion'] as String?,
        materia: args['materia'] as String?,
        fechaEntrega: args['fecha_entrega'] as String?,
      );
      return CallToolResult(
        content: [
          TextContent(text: 'Tarea guardada correctamente con id=$id.'),
        ],
      );
    } catch (e, st) {
      return CallToolResult(
        isError: true,
        content: [
          TextContent(text: 'Error al guardar la tarea: $e\n$st'),
        ],
      );
    }
  }

  Future<CallToolResult> _onGuardarFlashcards(CallToolRequest request) async {
    try {
      final args = request.arguments ?? const {};
      final tarjetasRaw = (args['tarjetas'] as List).cast<Map>();
      final tarjetas = tarjetasRaw
          .map((m) => m.cast<String, Object?>())
          .toList(growable: false);

      final ids = await _flashcardsDao.insertarVarias(tarjetas);
      return CallToolResult(
        content: [
          TextContent(
            text: 'Se guardaron ${ids.length} flashcards (ids=$ids).',
          ),
        ],
      );
    } catch (e, st) {
      return CallToolResult(
        isError: true,
        content: [
          TextContent(text: 'Error al guardar flashcards: $e\n$st'),
        ],
      );
    }
  }
}
