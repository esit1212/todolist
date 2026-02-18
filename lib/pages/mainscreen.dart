import 'package:flutter/material.dart';
import 'todolist.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Mainscreen extends StatefulWidget {
  const Mainscreen({super.key});

  @override
  State<Mainscreen> createState() => _MainscreenState();
}

class _MainscreenState extends State<Mainscreen> {
  Stream<QuerySnapshot> getCategories() {
    return FirebaseFirestore.instance
        .collection('categories')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<String> addCategory(String name) async {
    DocumentReference docref = await FirebaseFirestore.instance
        .collection('categories')
        .add({'name': name, 'createdAt': FieldValue.serverTimestamp()});
    return docref.id;
  }

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
            onPressed: () async {
              if (name != null && name!.trim().isNotEmpty) {
                await addCategory(name!.trim());
              }
              Navigator.pop(context);
            },
            child: const Text("Add Category"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Categories"), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: getCategories(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No categories yet"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final name = doc['name'];
              final categoryId = doc.id;

              return Card(
                child: ListTile(
                  title: Text(name),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Todolist(categoryId: categoryId),
                      ),
                    );
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      FirebaseFirestore.instance
                          .collection('categories')
                          .doc(categoryId)
                          .delete();
                    },
                  ),
                ),
              );
            },
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
