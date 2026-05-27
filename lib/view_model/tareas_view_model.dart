import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';

/// ViewModel que expone la lista de tareas guardadas en SQLite.
///
/// Es un `AsyncNotifier` porque la consulta inicial es async y queremos
/// recargar bajo demanda (después de cada escaneo).
class TareasViewModel extends AsyncNotifier<List<Map<String, Object?>>> {
  @override
  Future<List<Map<String, Object?>>> build() async {
    final dao = await ref.watch(tareasDaoProvider.future);
    return dao.listarTodas();
  }

  Future<void> recargar() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final dao = await ref.read(tareasDaoProvider.future);
      return dao.listarTodas();
    });
  }

  Future<void> eliminar(int id) async {
    final dao = await ref.read(tareasDaoProvider.future);
    await dao.eliminar(id);
    await recargar();
  }
}

final tareasViewModelProvider = AsyncNotifierProvider<TareasViewModel,
    List<Map<String, Object?>>>(TareasViewModel.new);
