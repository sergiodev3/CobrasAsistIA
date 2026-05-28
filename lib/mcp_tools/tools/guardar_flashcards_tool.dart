import 'package:dart_mcp/server.dart' as mcp;
import 'package:google_generative_ai/google_generative_ai.dart' as gemini;

const String guardarFlashcardsToolName = 'guardar_flashcards_db';

/// Declaración MCP de `guardar_flashcards_db`.
///
/// Acepta un array de flashcards para permitir que el LLM cree varias tarjetas
/// de estudio en una sola llamada (por ejemplo, todas las definiciones que
/// detectó en un apunte).
final mcp.Tool guardarFlashcardsMcpTool = mcp.Tool(
  name: guardarFlashcardsToolName,
  description:
      'Guarda una o varias flashcards (pregunta/respuesta) en la base de datos '
      'local. Úsala cuando detectes definiciones, conceptos clave o material '
      'de estudio en los apuntes.',
  inputSchema: mcp.Schema.object(
    properties: {
      'tarjetas': mcp.Schema.list(
        description: 'Lista de flashcards a guardar.',
        items: mcp.Schema.object(
          properties: {
            'pregunta': mcp.Schema.string(
              description: 'Pregunta o concepto al frente de la tarjeta.',
            ),
            'respuesta': mcp.Schema.string(
              description: 'Respuesta o definición al reverso.',
            ),
            'materia': mcp.Schema.string(
              description: 'Materia escolar (opcional).',
            ),
            'tema': mcp.Schema.string(
              description: 'Tema específico dentro de la materia (opcional).',
            ),
            'dificultad': mcp.Schema.int(
              description: 'Dificultad estimada de 1 (fácil) a 5 (difícil).',
            ),
          },
          required: ['pregunta', 'respuesta'],
        ),
      ),
    },
    required: ['tarjetas'],
  ),
);

/// Declaración equivalente para Gemini.
final gemini.FunctionDeclaration
guardarFlashcardsGeminiDeclaration = gemini.FunctionDeclaration(
  guardarFlashcardsToolName,
  'Guarda una o varias flashcards en la base de datos local.',
  gemini.Schema.object(
    properties: {
      'tarjetas': gemini.Schema.array(
        description: 'Lista de flashcards a guardar.',
        items: gemini.Schema.object(
          properties: {
            'pregunta': gemini.Schema.string(description: 'Pregunta.'),
            'respuesta': gemini.Schema.string(description: 'Respuesta.'),
            'materia': gemini.Schema.string(description: 'Materia (opcional).'),
            'tema': gemini.Schema.string(description: 'Tema (opcional).'),
            'dificultad': gemini.Schema.integer(description: 'Dificultad 1-5.'),
          },
          requiredProperties: ['pregunta', 'respuesta'],
        ),
      ),
    },
    requiredProperties: ['tarjetas'],
  ),
);
