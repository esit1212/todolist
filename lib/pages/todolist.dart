import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/todo/todo_bloc.dart';

class Todolist extends StatefulWidget {
  final String categoryId;

  const Todolist({super.key, required this.categoryId});

  @override
  State<Todolist> createState() => _TodolistState();
}

class _TodolistState extends State<Todolist> {
  TodoBloc get _todoBloc => context.read<TodoBloc>();

  void _addTodoDialog() {
    final titleController = TextEditingController();
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Новая задача'),
        content: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  isDense: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите название задачи';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: noteController,
                maxLines: 2,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Комментарий',
                  hintText: 'Короткая заметка',
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) {
                return;
              }
              _todoBloc.add(
                TodoAdded(
                  title: titleController.text.trim(),
                  note: noteController.text.trim(),
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  void _editNoteDialog(TodoItem todo) {
    final noteController = TextEditingController(text: todo.note);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Комментарий'),
        content: TextFormField(
          controller: noteController,
          autofocus: true,
          maxLines: 3,
          maxLength: 120,
          decoration: const InputDecoration(
            labelText: 'Комментарий к задаче',
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              _todoBloc.add(
                TodoNoteUpdated(todoId: todo.id, note: noteController.text),
              );
              Navigator.pop(context);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _showTrashSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: BlocBuilder<TodoBloc, TodoState>(
          bloc: _todoBloc,
          builder: (context, state) {
            final archived = state.archivedTodos;
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Корзина',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Удалённые задачи можно восстановить',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  if (archived.isEmpty)
                    const Expanded(child: Center(child: Text('Корзина пуста')))
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: archived.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final todo = archived[index];
                          return Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 2,
                              ),
                              title: Text(todo.title),
                              subtitle: todo.note.trim().isEmpty
                                  ? null
                                  : Text(
                                      todo.note,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                              leading: IconButton(
                                tooltip: 'Восстановить',
                                onPressed: () =>
                                    _todoBloc.add(TodoRestored(todo.id)),
                                icon: const Icon(Icons.restore),
                              ),
                              trailing: IconButton(
                                tooltip: 'Удалить навсегда',
                                onPressed: () =>
                                    _todoBloc.add(ArchivedTodoDeleted(todo.id)),
                                icon: const Icon(Icons.delete_forever),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TodoBloc, TodoState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Text(
              'Задачи',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            actions: [
              IconButton(
                onPressed: _showTrashSheet,
                icon: Badge.count(
                  count: state.archivedTodos.length,
                  isLabelVisible: state.archivedTodos.isNotEmpty,
                  child: const Icon(Icons.archive_outlined),
                ),
              ),
            ],
          ),
          body: Builder(
            builder: (context) {
              if (state.status == TodoStatus.loading ||
                  state.status == TodoStatus.initial) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.status == TodoStatus.error) {
                return Center(
                  child: Text(state.errorMessage ?? 'Failed to load todos'),
                );
              }

              if (state.todos.isEmpty) {
                return const Center(child: Text('Список задач пуст'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.todos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final todo = state.todos[index];

                  return Dismissible(
                    key: Key(todo.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => _todoBloc.add(TodoDeleted(todo.id)),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                      ),
                    ),
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        leading: Checkbox(
                          value: todo.done,
                          onChanged: (value) {
                            if (value != null) {
                              _todoBloc.add(
                                TodoToggled(todoId: todo.id, done: value),
                              );
                            }
                          },
                        ),
                        title: Text(
                          todo.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                decoration: todo.done
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: todo.done
                                    ? Theme.of(context).colorScheme.outline
                                    : null,
                              ),
                        ),
                        subtitle: todo.note.trim().isEmpty
                            ? null
                            : Text(
                                todo.note,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                        trailing: IconButton(
                          tooltip: 'Комментарий',
                          onPressed: () => _editNoteDialog(todo),
                          icon: const Icon(Icons.sticky_note_2_outlined),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _addTodoDialog,
            icon: const Icon(Icons.add),
            label: const Text('Задача'),
          ),
        );
      },
    );
  }
}
