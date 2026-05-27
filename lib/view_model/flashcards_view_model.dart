import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';

/// ViewModel que expone la lista de flashcards guardadas.
class FlashcardsViewModel
    extends AsyncNotifier<List<Map<String, Object?>>> {
  @override
  Future<List<Map<String, Object?>>> build() async {
    final dao = await ref.watch(flashcardsDaoProvider.future);
    return dao.listarTodas();
  }

  Future<void> recargar() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final dao = await ref.read(flashcardsDaoProvider.future);
      return dao.listarTodas();
    });
  }

  Future<void> eliminar(int id) async {
    final dao = await ref.read(flashcardsDaoProvider.future);
    await dao.eliminar(id);
    await recargar();
  }
}

final flashcardsViewModelProvider = AsyncNotifierProvider<FlashcardsViewModel,
    List<Map<String, Object?>>>(FlashcardsViewModel.new);
