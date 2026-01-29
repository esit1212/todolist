import 'package:flutter/material.dart';
import 'todolist.dart';

class Category {
  String name;
  List<String> todos;

  Category({required this.name, required this.todos});
}

class Mainscreen extends StatefulWidget {
  const Mainscreen({super.key});

  @override
  State<Mainscreen> createState() => _MainscreenState();
}

class _MainscreenState extends State<Mainscreen> {
  List<Category> categories = [];

  void _addCategoryDialog() {
    String? name;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("New Category"),
        content: TextField(
          onChanged: (v) => name = v,
          decoration: const InputDecoration(hintText: "Category name"),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (name != null && name!.trim().isNotEmpty) {
                setState(() {
                  categories.add(Category(name: name!.trim(), todos: []));
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
      appBar: AppBar(title: const Text("Categories"), centerTitle: true),
      body: categories.isEmpty
          ? const Center(child: Text("No categories yet"))
          : ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];

                return Card(
                  child: ListTile(
                    title: Text(category.name),
                    subtitle: Text("${category.todos.length} tasks"),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Todolist(category: category),
                        ),
                      );
                      setState(() {}); // обновить количество задач
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategoryDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
