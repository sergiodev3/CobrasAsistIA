import 'package:dart_mcp/client.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as gemini;
import 'package:stream_channel/stream_channel.dart';

import '../data/database/flashcards_dao.dart';
import '../data/database/tareas_dao.dart';
import 'cobras_mcp_server.dart';
import 'tools/guardar_flashcards_tool.dart';
import 'tools/guardar_tarea_tool.dart';

/// Conexión MCP totalmente inicializada y lista para usarse.
///
/// Contiene tanto el cliente como la referencia al servidor (`connection`)
/// que ya completó el handshake `initialize` + `notifyInitialized`.
class CobrasMcpConnection {
  CobrasMcpConnection({
    required this.client,
    required this.server,
    required this.serverImpl,
  });

  final MCPClient client;
  final ServerConnection server;
  final CobrasMcpServer serverImpl;

  /// Atajo para invocar una herramienta MCP por nombre con sus argumentos.
  Future<CallToolResult> callTool(
    String name,
    Map<String, Object?> arguments,
  ) {
    return server.callTool(
      CallToolRequest(name: name, arguments: arguments),
    );
  }

  Future<void> close() => client.shutdown();
}

/// Crea un par cliente/servidor MCP **dentro del mismo proceso**, conectados
/// por un `StreamChannelController<String>` (no usamos stdio ni red, porque
/// esta app corre en un móvil y todo vive en el mismo proceso Dart).
///
/// Después del handshake, devuelve una `CobrasMcpConnection` lista para
/// invocar herramientas.
Future<CobrasMcpConnection> conectarMcpEnMemoria({
  required TareasDao tareasDao,
  required FlashcardsDao flashcardsDao,
}) async {
  // El controller expone dos extremos del mismo canal: `local` (cliente)
  // y `foreign` (servidor). Lo que se escribe en uno se lee en el otro.
  final controller = StreamChannelController<String>();

  // 1) Levantamos el servidor con sus dependencias (los DAOs).
  final servidor = CobrasMcpServer.fromStreamChannel(
    controller.foreign,
    tareasDao: tareasDao,
    flashcardsDao: flashcardsDao,
  );

  // 2) Creamos el cliente y lo conectamos al otro extremo del canal.
  final cliente = MCPClient(
    Implementation(name: 'CobrasAsistIA-mcp-client', version: '0.1.0'),
  );
  final conexionServidor = cliente.connectServer(controller.local);

  // 3) Handshake estándar MCP.
  final init = await conexionServidor.initialize(
    InitializeRequest(
      protocolVersion: ProtocolVersion.latestSupported,
      capabilities: cliente.capabilities,
      clientInfo: cliente.implementation,
    ),
  );
  if (init.capabilities.tools == null) {
    await conexionServidor.shutdown();
    throw StateError('El servidor MCP local no expone la capability `tools`.');
  }
  conexionServidor.notifyInitialized();

  return CobrasMcpConnection(
    client: cliente,
    server: conexionServidor,
    serverImpl: servidor,
  );
}

/// Devuelve la lista de declaraciones de herramientas en el formato que espera
/// Gemini. Esta función es el "puente" entre nuestras tools MCP y la API del
/// LLM: lo que el LLM ve son `FunctionDeclaration`, pero cuando decide
/// invocarlas, nosotros las despachamos al servidor MCP.
List<gemini.Tool> obtenerToolsParaGemini() {
  return [
    gemini.Tool(functionDeclarations: [
      guardarTareaGeminiDeclaration,
      guardarFlashcardsGeminiDeclaration,
    ]),
  ];
}
