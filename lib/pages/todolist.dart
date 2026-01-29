import 'package:flutter/material.dart';
import 'mainscreen.dart';

class Todolist extends StatefulWidget {
  final Category category;

  const Todolist({super.key, required this.category});

  @override
  State<Todolist> createState() => _TodolistState();
}

class _TodolistState extends State<Todolist> {
  late List<String> todoList;

  @override
  void initState() {
    super.initState();
    todoList = widget.category.todos;
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
            onPressed: () {
              if (newTodo != null && newTodo!.trim().isNotEmpty) {
                setState(() {
                  todoList.add(newTodo!.trim());
                });
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
      appBar: AppBar(title: Text(widget.category.name), centerTitle: true),
      body: todoList.isEmpty
          ? const Center(child: Text("No tasks yet"))
          : ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: todoList.length,
              itemBuilder: (context, index) {
                return Dismissible(
                  key: ValueKey('$index-${todoList[index]}'),
                  onDismissed: (_) {
                    setState(() {
                      todoList.removeAt(index);
                    });
                  },
                  child: Card(
                    child: ListTile(
                      leading: ReorderableDragStartListener(
                        child: Icon(Icons.list),
                        index: index,
                      ),
                      title: Center(child: Text(todoList[index])),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: (){
                          setState(() {
                            todoList.removeAt(index);
                          });
                        },
                      ),
                    ),
                  ),
                );
              },
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final String item = todoList.removeAt(oldIndex);
                  todoList.insert(newIndex, item);
                });
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTodoDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
