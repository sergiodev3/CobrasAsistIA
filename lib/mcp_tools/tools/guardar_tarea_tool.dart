import 'package:dart_mcp/server.dart' as mcp;
import 'package:google_generative_ai/google_generative_ai.dart' as gemini;

/// Nombre canónico de la herramienta. Lo usaremos tanto del lado del servidor
/// MCP como en la declaración que se envía a Gemini, para que el LLM y el
/// servidor hablen del mismo identificador.
const String guardarTareaToolName = 'guardar_tarea_db';

/// Declaración MCP de la herramienta `guardar_tarea_db`.
///
/// El servidor MCP usa esto para validar los argumentos automáticamente antes
/// de invocar el handler (ver `ToolsSupport.registerTool`).
final mcp.Tool guardarTareaMcpTool = mcp.Tool(
  name: guardarTareaToolName,
  description:
      'Guarda una tarea escolar pendiente en la base de datos local. '
      'Úsala cuando detectes una tarea, deber o asignación en los apuntes.',
  inputSchema: mcp.Schema.object(
    properties: {
      'titulo': mcp.Schema.string(
        description: 'Título corto y descriptivo de la tarea.',
      ),
      'descripcion': mcp.Schema.string(
        description: 'Detalle o instrucciones de la tarea (opcional).',
      ),
      'materia': mcp.Schema.string(
        description: 'Materia escolar a la que pertenece la tarea (opcional).',
      ),
      'fecha_entrega': mcp.Schema.string(
        description:
            'Fecha de entrega en formato ISO-8601 (YYYY-MM-DD) si se conoce.',
      ),
    },
    required: ['titulo'],
  ),
);

/// Declaración equivalente para Gemini (google_generative_ai).
///
/// MCP y Gemini usan dos tipos `Schema` distintos, por eso mantenemos las dos
/// declaraciones juntas en este archivo: cualquier cambio se hace en un solo
/// lugar y nunca se desincronizan.
final gemini.FunctionDeclaration guardarTareaGeminiDeclaration =
    gemini.FunctionDeclaration(
  guardarTareaToolName,
  'Guarda una tarea escolar pendiente en la base de datos local.',
  gemini.Schema.object(
    properties: {
      'titulo': gemini.Schema.string(
        description: 'Título corto y descriptivo de la tarea.',
      ),
      'descripcion': gemini.Schema.string(
        description: 'Detalle o instrucciones (opcional).',
      ),
      'materia': gemini.Schema.string(
        description: 'Materia escolar (opcional).',
      ),
      'fecha_entrega': gemini.Schema.string(
        description: 'Fecha de entrega ISO-8601 (YYYY-MM-DD).',
      ),
    },
    requiredProperties: ['titulo'],
  ),
);
