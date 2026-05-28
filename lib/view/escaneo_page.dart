import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../view_model/escaneo_view_model.dart';
import '../view_model/flashcards_view_model.dart';
import '../view_model/tareas_view_model.dart';

/// Pantalla de escaneo de apuntes.
///
/// La View es "tonta": solo lee el estado del ViewModel y dispara acciones.
/// Toda la lógica vive en `EscaneoViewModel`.
class EscaneoPage extends ConsumerWidget {
  const EscaneoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(escaneoViewModelProvider);
    final vm = ref.read(escaneoViewModelProvider.notifier);

    // Cuando el escaneo termina con éxito, refrescamos los listados.
    ref.listen(escaneoViewModelProvider, (prev, next) {
      if (prev?.estado != EstadoEscaneo.exito &&
          next.estado == EstadoEscaneo.exito) {
        ref.read(tareasViewModelProvider.notifier).recargar();
        ref.read(flashcardsViewModelProvider.notifier).recargar();
      }
    });

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BotonesAccion(state: state, vm: vm),
          const SizedBox(height: 16),
          Expanded(child: _Contenido(state: state)),
        ],
      ),
    );
  }
}

class _BotonesAccion extends StatelessWidget {
  const _BotonesAccion({required this.state, required this.vm});

  final EscaneoState state;
  final EscaneoViewModel vm;

  @override
  Widget build(BuildContext context) {
    final ocupado = state.estado == EstadoEscaneo.capturando ||
        state.estado == EstadoEscaneo.pensando ||
        state.estado == EstadoEscaneo.ejecutandoHerramienta;
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: ocupado ? null : vm.escanearConCamara,
            icon: const Icon(Icons.photo_camera),
            label: const Text('Cámara'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: ocupado ? null : vm.escanearDesdeGaleria,
            icon: const Icon(Icons.photo_library),
            label: const Text('Galería'),
          ),
        ),
      ],
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.state});

  final EscaneoState state;

  @override
  Widget build(BuildContext context) {
    switch (state.estado) {
      case EstadoEscaneo.inicial:
        return Column(
          children: [
            Expanded(
              flex: 4,
              child: Image.asset(
                'assets/cobras-task-asist-logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Toma una foto de tus apuntes o del pizarrón.\n'
              'La IA detectará tareas y generará flashcards.',
              textAlign: TextAlign.center,
            ),
            const Spacer(flex: 1),
          ],
        );
      case EstadoEscaneo.capturando:
        return const Center(child: Text('Abriendo cámara...'));
      case EstadoEscaneo.pensando:
        return const _CargandoConMensaje(mensaje: 'La IA está analizando la imagen...');
      case EstadoEscaneo.ejecutandoHerramienta:
        return const _CargandoConMensaje(
          mensaje: 'Ejecutando herramientas MCP y guardando en SQLite...',
        );
      case EstadoEscaneo.exito:
        return _ResultadoExito(state: state);
      case EstadoEscaneo.error:
        return _ResultadoError(mensaje: state.error ?? 'Error desconocido');
    }
  }
}

class _CargandoConMensaje extends StatelessWidget {
  const _CargandoConMensaje({required this.mensaje});
  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(mensaje, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ResultadoExito extends StatelessWidget {
  const _ResultadoExito({required this.state});
  final EscaneoState state;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.imagenBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(state.imagenBytes!, height: 200, fit: BoxFit.cover),
            ),
          const SizedBox(height: 16),
          if (state.mensajeModelo != null) ...[
            Text('Respuesta del modelo:',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(state.mensajeModelo!),
            const SizedBox(height: 16),
          ],
          if (state.resultadosHerramientas.isNotEmpty) ...[
            Text('Herramientas MCP ejecutadas:',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            for (final r in state.resultadosHerramientas)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('• $r'),
              ),
          ],
        ],
      ),
    );
  }
}

class _ResultadoError extends StatelessWidget {
  const _ResultadoError({required this.mensaje});
  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(mensaje, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
