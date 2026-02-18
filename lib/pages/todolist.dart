import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Todolist extends StatefulWidget {
  final String categoryId;

  const Todolist({super.key, required this.categoryId});

  @override
  State<Todolist> createState() => _TodolistState();
}

class _TodolistState extends State<Todolist> {
  Stream<QuerySnapshot> getTodos() {
    return FirebaseFirestore.instance
        .collection('categories')
        .doc(widget.categoryId)
        .collection('todos')
        .orderBy('done')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> addTodo(String title) async {
    await FirebaseFirestore.instance
        .collection('categories')
        .doc(widget.categoryId)
        .collection('todos')
        .add({
          'title': title,
          'done': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> toggleTodo(String todoId, bool done) async {
    await FirebaseFirestore.instance
        .collection('categories')
        .doc(widget.categoryId)
        .collection('todos')
        .doc(todoId)
        .update({'done': done});
  }

  Future<void> deleteTodo(String todoId) async {
    await FirebaseFirestore.instance
        .collection('categories')
        .doc(widget.categoryId)
        .collection('todos')
        .doc(todoId)
        .delete();
  }

  @override
  void initState() {
    super.initState();
  }

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
                await addTodo(newTodo!.trim());
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
      body: StreamBuilder<QuerySnapshot>(
        stream: getTodos(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No tasks yet"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title'] ?? '';
              final done = (data['done'] ?? false) as bool;
              final todoId = doc.id;

              return Dismissible(
                key: ValueKey(todoId),
                direction: DismissDirection.horizontal,
                confirmDismiss: (direction) async {
                  await toggleTodo(todoId, !done);
                  return false;
                },
                background: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  color: done ? Colors.orange : Colors.green,
                  child: Icon(
                    done ? Icons.undo : Icons.check,
                    color: Colors.white,
                  ),
                ),
                secondaryBackground: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  color: done ? Colors.orange : Colors.green,
                  child: Icon(
                    done ? Icons.undo : Icons.check,
                    color: Colors.white,
                  ),
                ),
                child: Card(
                  child: ListTile(
                    title: Text(
                      title,
                      style: TextStyle(
                        decoration: done ? TextDecoration.lineThrough : null,
                        color: done
                            ? Theme.of(context).colorScheme.outline
                            : null,
                      ),
                    ),
                    leading: Checkbox(
                      value: done,
                      onChanged: (value) {
                        if (value != null) {
                          toggleTodo(todoId, value);
                        }
                      },
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => deleteTodo(todoId),
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
