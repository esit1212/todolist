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
    String? newTodo;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add task"),
        content: TextField(
          onChanged: (v) => newTodo = v,
          decoration: const InputDecoration(hintText: "Task name"),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              if (newTodo != null && newTodo!.trim().isNotEmpty) {
                _todoBloc.add(TodoAdded(newTodo!.trim()));
              }
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tasks'), centerTitle: true),
      body: BlocBuilder<TodoBloc, TodoState>(
        builder: (context, state) {
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
            return const Center(child: Text("No tasks yet"));
          }

          return ListView.builder(
            itemCount: state.todos.length,
            itemBuilder: (context, index) {
              final todo = state.todos[index];

              return Dismissible(
                key: ValueKey(todo.id),
                direction: DismissDirection.horizontal,
                confirmDismiss: (direction) async {
                  _todoBloc.add(TodoToggled(todoId: todo.id, done: !todo.done));
                  return false;
                },
                background: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  color: todo.done ? Colors.orange : Colors.green,
                  child: Icon(
                    todo.done ? Icons.undo : Icons.check,
                    color: Colors.white,
                  ),
                ),
                secondaryBackground: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  color: todo.done ? Colors.orange : Colors.green,
                  child: Icon(
                    todo.done ? Icons.undo : Icons.check,
                    color: Colors.white,
                  ),
                ),
                child: Card(
                  child: ListTile(
                    title: Text(
                      todo.title,
                      style: TextStyle(
                        decoration: todo.done
                            ? TextDecoration.lineThrough
                            : null,
                        color: todo.done
                            ? Theme.of(context).colorScheme.outline
                            : null,
                      ),
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
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _todoBloc.add(TodoDeleted(todo.id)),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTodoDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
