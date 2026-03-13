import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'todolist.dart';
import '../bloc/category/category_bloc.dart';
import '../bloc/todo/todo_bloc.dart';
import '../data/local_storage_repository.dart';

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
  late final LocalStorageRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = LocalStorageRepository.instance;
    _categoryBloc = CategoryBloc(repository: _repository)
      ..add(const CategoriesStarted());
  }

  @override
  void dispose() {
    _categoryBloc.close();
    super.dispose();
  }

  void _addCategoryDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Новая категория'),
        content: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: TextFormField(
            controller: nameController,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Название',
              isDense: true,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Введите название категории';
              }
              return null;
            },
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
              _categoryBloc.add(CategoryAdded(nameController.text.trim()));
              Navigator.pop(context);
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  void _deleteCategoryDialog(String categoryId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить категорию'),
        content: const Text('Вы уверены, что хотите удалить эту категорию?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              _categoryBloc.add(CategoryDeleted(categoryId));
              Navigator.pop(context);
            },
            child: const Text('Удалить'),
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
          title: Text(
            'Категории',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
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
              return const Center(child: Text('Категорий пока нет'));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final category = state.categories[index];

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    title: Text(
                      category.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      'Открыть список задач',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider(
                            create: (_) => TodoBloc(
                              categoryId: category.id,
                              repository: _repository,
                            )..add(const TodosStarted()),
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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addCategoryDialog,
          icon: const Icon(Icons.add),
          label: const Text('Категория'),
        ),
      ),
    );
  }
}
