import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../view_model/flashcards_view_model.dart';

class FlashcardsPage extends ConsumerWidget {
  const FlashcardsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCards = ref.watch(flashcardsViewModelProvider);
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(flashcardsViewModelProvider.notifier).recargar(),
      child: asyncCards.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(
          children: [Padding(padding: const EdgeInsets.all(16), child: Text('Error: $e'))],
        ),
        data: (cards) {
          if (cards.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 80),
                Center(
                  child: Text('Aún no hay flashcards. Escanea unos apuntes.'),
                ),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: cards.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final c = cards[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${c['dificultad'] ?? 1}')),
                  title: Text(c['pregunta'] as String),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(c['respuesta'] as String),
                      if (c['materia'] != null || c['tema'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            [
                              if (c['materia'] != null) '${c['materia']}',
                              if (c['tema'] != null) '${c['tema']}',
                            ].join(' • '),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => ref
                        .read(flashcardsViewModelProvider.notifier)
                        .eliminar(c['id'] as int),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
