import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../view_model/tareas_view_model.dart';

class TareasPage extends ConsumerWidget {
  const TareasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTareas = ref.watch(tareasViewModelProvider);
    return RefreshIndicator(
      onRefresh: () => ref.read(tareasViewModelProvider.notifier).recargar(),
      child: asyncTareas.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: $e'),
            ),
          ],
        ),
        data: (tareas) {
          if (tareas.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 80),
                Center(child: Text('Aún no hay tareas. Escanea unos apuntes.')),
              ],
            );
          }
          return ListView.separated(
            itemCount: tareas.length,
            separatorBuilder: (_, _) => const Divider(height: 0),
            itemBuilder: (context, i) {
              final t = tareas[i];
              return ListTile(
                leading: const Icon(Icons.assignment),
                title: Text(t['titulo'] as String),
                subtitle: Text(
                  [
                    if (t['materia'] != null) 'Materia: ${t['materia']}',
                    if (t['fecha_entrega'] != null)
                      'Entrega: ${t['fecha_entrega']}',
                    if (t['descripcion'] != null) t['descripcion'] as String,
                  ].join('\n'),
                ),
                isThreeLine: t['descripcion'] != null,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => ref
                      .read(tareasViewModelProvider.notifier)
                      .eliminar(t['id'] as int),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
