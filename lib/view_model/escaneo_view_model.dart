import 'dart:typed_data';

import 'package:dart_mcp/client.dart' as mcp;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';

import '../core/providers.dart';

/// Estado posible del flujo de escaneo de apuntes.
enum EstadoEscaneo {
  /// Listo esperando que el usuario tome una foto.
  inicial,

  /// Mostrando la cámara / picker del sistema.
  capturando,

  /// Esperando respuesta del LLM.
  pensando,

  /// Ejecutando una o más tool calls vía MCP.
  ejecutandoHerramienta,

  /// El flujo terminó correctamente.
  exito,

  /// Ocurrió un error.
  error,
}

/// Estado inmutable del ViewModel de escaneo.
class EscaneoState {
  const EscaneoState({
    this.estado = EstadoEscaneo.inicial,
    this.imagenBytes,
    this.mensajeModelo,
    this.resultadosHerramientas = const [],
    this.error,
  });

  final EstadoEscaneo estado;
  final Uint8List? imagenBytes;
  final String? mensajeModelo;
  final List<String> resultadosHerramientas;
  final String? error;

  EscaneoState copyWith({
    EstadoEscaneo? estado,
    Uint8List? imagenBytes,
    String? mensajeModelo,
    List<String>? resultadosHerramientas,
    String? error,
  }) {
    return EscaneoState(
      estado: estado ?? this.estado,
      imagenBytes: imagenBytes ?? this.imagenBytes,
      mensajeModelo: mensajeModelo ?? this.mensajeModelo,
      resultadosHerramientas:
          resultadosHerramientas ?? this.resultadosHerramientas,
      error: error,
    );
  }
}

/// ViewModel del flujo de escaneo de apuntes.
///
/// Orquesta: cámara → Gemini (multimodal + tool use) → MCP → SQLite.
class EscaneoViewModel extends Notifier<EscaneoState> {
  final ImagePicker _picker = ImagePicker();

  @override
  EscaneoState build() => const EscaneoState();

  /// Toma una foto con la cámara y dispara el pipeline completo.
  Future<void> escanearConCamara() => _escanear(ImageSource.camera);

  /// Selecciona una imagen de la galería y dispara el pipeline completo.
  Future<void> escanearDesdeGaleria() => _escanear(ImageSource.gallery);

  Future<void> _escanear(ImageSource source) async {
    state = state.copyWith(estado: EstadoEscaneo.capturando, error: null);

    try {
      final foto = await _picker.pickImage(
        source: source,
        imageQuality: 70, // comprimimos antes de enviarla al LLM
      );
      if (foto == null) {
        // El usuario canceló la captura.
        state = state.copyWith(estado: EstadoEscaneo.inicial);
        return;
      }

      final bytes = await foto.readAsBytes();
      state = state.copyWith(
        estado: EstadoEscaneo.pensando,
        imagenBytes: bytes,
        mensajeModelo: null,
        resultadosHerramientas: const [],
      );

      // --- Llamada multimodal a Gemini con herramientas habilitadas ---
      final model = ref.read(geminiModelProvider);
      final prompt = TextPart(
        'Analiza esta imagen de los apuntes de un estudiante. '
        'Si encuentras tareas/deberes, llama a guardar_tarea_db. '
        'Si encuentras definiciones o conceptos clave, genera flashcards '
        'útiles y llama a guardar_flashcards_db. '
        'Después, dame un resumen breve en español.',
      );
      final imagePart = DataPart('image/jpeg', bytes);

      final respuesta = await model.generateContent([
        Content.multi([prompt, imagePart]),
      ]);

      // --- Despacho de tool calls a través de MCP ---
      final llamadas = respuesta.functionCalls.toList(growable: false);

      if (llamadas.isNotEmpty) {
        state = state.copyWith(estado: EstadoEscaneo.ejecutandoHerramienta);
        final conn = await ref.read(mcpConnectionProvider.future);
        final resultados = <String>[];
        for (final fc in llamadas) {
          final mcp.CallToolResult r = await conn.callTool(fc.name, fc.args);
          final texto = r.content
              .whereType<mcp.TextContent>()
              .map((c) => c.text)
              .join('\n');
          resultados.add(
            r.isError == true
                ? 'ERROR en ${fc.name}: $texto'
                : '${fc.name} → $texto',
          );
        }
        state = state.copyWith(
          estado: EstadoEscaneo.exito,
          mensajeModelo: respuesta.text,
          resultadosHerramientas: resultados,
        );
      } else {
        state = state.copyWith(
          estado: EstadoEscaneo.exito,
          mensajeModelo: respuesta.text ??
              'El modelo no detectó tareas ni material de estudio.',
        );
      }
    } catch (e, st) {
      state = state.copyWith(
        estado: EstadoEscaneo.error,
        error: '$e\n$st',
      );
    }
  }

  /// Resetea el estado para hacer otro escaneo.
  void reiniciar() {
    state = const EscaneoState();
  }
}

final escaneoViewModelProvider =
    NotifierProvider<EscaneoViewModel, EscaneoState>(EscaneoViewModel.new);
