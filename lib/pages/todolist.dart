import 'package:flutter/material.dart';

class Todolist extends StatefulWidget {
  final List<String> todolist;
  final Function(List<String> todoList) onTodoListChanged;

  const Todolist({
    super.key,
    required this.todolist,
    required this.onTodoListChanged,
  });

  @override
  State<Todolist> createState() => _TodolistState();
}

class _TodolistState extends State<Todolist> {
  String? newTodo;
  late List<String> todoList = [...widget.todolist];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    widget.onTodoListChanged(todoList);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todolist', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.brown,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            Expanded(
              child: todoList.isEmpty
                  ? const Center(
                      child: Text(
                        'No tasks yet.\nTap + to add one',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: todoList.length,
                      itemBuilder: (context, index) {
                        return Dismissible(
                          key: ValueKey(todoList[index]),
                          onDismissed: (_) {
                            setState(() {
                              todoList.removeAt(index);
                            });
                          },
                          child: Card(
                            child: ListTile(title: Text(todoList[index])),
                          ),
                        );
                      },
                    ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Back to Main Screen'),
                  ),

                  FloatingActionButton(
                    onPressed: () {
                      newTodo = null;
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Add todo'),
                            content: TextField(
                              onChanged: (String value) {
                                newTodo = value;
                              },
                            ),
                            actions: [
                              ElevatedButton(
                                onPressed: () {
                                  if (newTodo != null &&
                                      newTodo!.trim().isNotEmpty) {
                                    setState(() {
                                      todoList.add(newTodo!.trim());
                                    });
                                  }
                                  Navigator.of(context).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.brown,
                                ),
                                child: Text(
                                  'Add',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    backgroundColor: Colors.brown,
                    child: Icon(Icons.add, color: Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
