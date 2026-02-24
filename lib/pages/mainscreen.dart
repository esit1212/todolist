import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'todolist.dart';
import '../bloc/category/category_bloc.dart';
import '../bloc/todo/todo_bloc.dart';

class Mainscreen extends StatefulWidget {
  const Mainscreen({
    super.key,
    required this.toggleTheme,
    required this.themeMode,
  });

  final void Function() toggleTheme;
  final ThemeMode themeMode;

  @override
  State<Mainscreen> createState() => _MainscreenState();
}

class _MainscreenState extends State<Mainscreen> {
  late final CategoryBloc _categoryBloc;

  @override
  void initState() {
    super.initState();
    _categoryBloc = CategoryBloc()..add(const CategoriesStarted());
  }

  @override
  void dispose() {
    _categoryBloc.close();
    super.dispose();
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
                _categoryBloc.add(CategoryAdded(name!.trim()));
              }
              Navigator.pop(context);
            },
            child: const Text("Add Category"),
          ),
        ],
      ),
    );
  }

  void _deleteCategoryDialog(String categoryId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Category"),
        content: const Text("Are you sure you want to delete this category?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              _categoryBloc.add(CategoryDeleted(categoryId));
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _categoryBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Categories"),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: widget.toggleTheme,
              icon: Icon(
                widget.themeMode == ThemeMode.light
                    ? Icons.dark_mode
                    : Icons.light_mode,
              ),
            ),
          ],
        ),
        body: BlocBuilder<CategoryBloc, CategoryState>(
          builder: (context, state) {
            if (state.status == CategoryStatus.loading ||
                state.status == CategoryStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == CategoryStatus.error) {
              return Center(
                child: Text(state.errorMessage ?? 'Failed to load categories'),
              );
            }

            if (state.categories.isEmpty) {
              return const Center(child: Text("No categories yet"));
            }

            return ListView.builder(
              itemCount: state.categories.length,
              itemBuilder: (context, index) {
                final category = state.categories[index];

                return Card(
                  child: ListTile(
                    title: Text(category.name),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider(
                            create: (_) =>
                                TodoBloc(categoryId: category.id)
                                  ..add(const TodosStarted()),
                            child: Todolist(categoryId: category.id),
                          ),
                        ),
                      );
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteCategoryDialog(category.id),
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
      ),
    );
  }
}
