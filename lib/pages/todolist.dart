import 'package:flutter/material.dart';

class Todolist extends StatefulWidget {
  const Todolist({super.key});

  @override
  State<Todolist> createState() => _TodolistState();
}

class _TodolistState extends State<Todolist> {
  String? newTodo;
  List<String> todoList = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todolist', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.brown,
      ),
      body: Column(
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

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FloatingActionButton(
                onPressed: () {
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
                              setState(() {
                                todoList.add(newTodo!);
                              });
                              Navigator.of(context).pop();
                            },
                            child: Text('Add'),
                          ),
                        ],
                      );
                    },
                  );
                },
                backgroundColor: Colors.brown,
                child: Icon(Icons.add, color: Colors.white),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Back to Main Screen'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
