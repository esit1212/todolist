# Руководство по архитектуре BLoC в этом проекте

Этот документ описывает, как в проекте применена архитектура BLoC: с гайдами, пояснениями и фрагментами кода.

## 1) Цели и ключевые идеи

- Держать UI-виджеты сфокусированными на рендере и пользовательском вводе.
- Вынести доступ к Firestore и бизнес-логику в классы BLoC.
- Использовать события для запросов действий, а состояния — для доставки данных и статуса UI.
- Сделать так, чтобы каждый экран читал состояние через `BlocBuilder` и отправлял действия через `Bloc.add`.

## 2) Структура папок

```
lib/
  bloc/
    category/
      category_bloc.dart
      category_event.dart
      category_state.dart
    todo/
      todo_bloc.dart
      todo_event.dart
      todo_state.dart
  pages/
    mainscreen.dart
    todolist.dart
```

## 3) Общая схема потока данных

```
UI -> Event -> Bloc -> (Firestore) -> State -> UI
```

- UI отправляет событие (например, `CategoryAdded`).
- BLoC выполняет операции Firestore и подписывается на snapshots.
- BLoC эмитит состояние с новыми данными (`CategoryState` или `TodoState`).
- UI перестраивается через `BlocBuilder`.

## 4) Category BLoC (экран категорий)

### 4.1 События (category_event.dart)

События — это классы намерений. UI не вызывает Firestore напрямую.

```dart
sealed class CategoryEvent {
  const CategoryEvent();
}

final class CategoriesStarted extends CategoryEvent {
  const CategoriesStarted();
}

final class CategoryAdded extends CategoryEvent {
  const CategoryAdded(this.name);
  final String name;
}

final class CategoryDeleted extends CategoryEvent {
  const CategoryDeleted(this.categoryId);
  final String categoryId;
}
```

### 4.2 Состояние (category_state.dart)

Состояние содержит все данные экрана и флаг статуса.

```dart
enum CategoryStatus { initial, loading, loaded, error }

class CategoryState {
  const CategoryState({
    this.status = CategoryStatus.initial,
    this.categories = const [],
    this.errorMessage,
  });

  final CategoryStatus status;
  final List<CategoryItem> categories;
  final String? errorMessage;
}
```

### 4.3 Блок (category_bloc.dart)

Ключевые обязанности:

- Запустить подписку на Firestore в `CategoriesStarted`.
- Преобразовать snapshots Firestore в простые объекты `CategoryItem`.
- Эмитить обновления `CategoryState` для UI.

```dart
class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  CategoryBloc({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      super(const CategoryState()) {
    on<CategoriesStarted>(_onStarted);
    on<CategoryAdded>(_onAdded);
    on<CategoryDeleted>(_onDeleted);
    on<CategoriesChanged>(_onChanged);
    on<CategoriesFailed>(_onFailed);
  }

  Future<void> _onStarted(
    CategoriesStarted event,
    Emitter<CategoryState> emit,
  ) async {
    emit(state.copyWith(status: CategoryStatus.loading, clearError: true));

    await _subscription?.cancel();
    _subscription = _firestore
        .collection('categories')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            final categories = snapshot.docs
                .map((doc) => CategoryItem(id: doc.id, name: doc.data()['name'] ?? ''))
                .toList();
            add(CategoriesChanged(categories));
          },
          onError: (Object error) {
            add(CategoriesFailed(error.toString()));
          },
        );
  }
}
```

## 5) Todo BLoC (экран задач)

### 5.1 События (todo_event.dart)

```dart
final class TodoAdded extends TodoEvent {
  const TodoAdded(this.title);
  final String title;
}

final class TodoToggled extends TodoEvent {
  const TodoToggled({required this.todoId, required this.done});
  final String todoId;
  final bool done;
}

final class TodoDeleted extends TodoEvent {
  const TodoDeleted(this.todoId);
  final String todoId;
}
```

### 5.2 Состояние (todo_state.dart)

```dart
enum TodoStatus { initial, loading, loaded, error }

class TodoState {
  const TodoState({
    this.status = TodoStatus.initial,
    this.todos = const [],
    this.errorMessage,
  });

  final TodoStatus status;
  final List<TodoItem> todos;
  final String? errorMessage;
}
```

### 5.3 Блок (todo_bloc.dart)

```dart
class TodoBloc extends Bloc<TodoEvent, TodoState> {
  TodoBloc({required this.categoryId, FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      super(const TodoState()) {
    on<TodosStarted>(_onStarted);
    on<TodoAdded>(_onAdded);
    on<TodoToggled>(_onToggled);
    on<TodoDeleted>(_onDeleted);
    on<TodosChanged>(_onChanged);
    on<TodosFailed>(_onFailed);
  }

  CollectionReference<Map<String, dynamic>> get _todosRef => _firestore
      .collection('categories')
      .doc(categoryId)
      .collection('todos');
}
```

## 6) Интеграция с UI

### 6.1 Экран категорий

Экран владеет bloc и передает его через `BlocProvider.value`.

```dart
@override
void initState() {
  super.initState();
  _categoryBloc = CategoryBloc()..add(const CategoriesStarted());
}

@override
Widget build(BuildContext context) {
  return BlocProvider.value(
    value: _categoryBloc,
    child: BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        if (state.status == CategoryStatus.loading ||
            state.status == CategoryStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.categories.isEmpty) {
          return const Center(child: Text("No categories yet"));
        }
        return ListView.builder(
          itemCount: state.categories.length,
          itemBuilder: (context, index) {
            final category = state.categories[index];
            return ListTile(
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
            );
          },
        );
      },
    ),
  );
}
```

### 6.2 Экран задач

Экран читает bloc из контекста и отправляет события при действиях пользователя.

```dart
TodoBloc get _todoBloc => context.read<TodoBloc>();

onPressed: () {
  _todoBloc.add(TodoAdded(newTodo));
}

confirmDismiss: (direction) async {
  _todoBloc.add(TodoToggled(todoId: todo.id, done: !todo.done));
  return false;
}
```

## 7) Шаблон обработки ошибок

- Каждый bloc эмитит `status: error` вместе с `errorMessage`.
- UI показывает сообщение, когда `status == error`.
- Пример в экране категорий:

```dart
if (state.status == CategoryStatus.error) {
  return Center(
    child: Text(state.errorMessage ?? 'Failed to load categories'),
  );
}
```

## 8) Как добавить новую фичу по этому шаблону

Пример: переименование категории.

1) Добавить новое событие в `category_event.dart`:

```dart
final class CategoryRenamed extends CategoryEvent {
  const CategoryRenamed({required this.categoryId, required this.name});
  final String categoryId;
  final String name;
}
```

2) Обработать его в `category_bloc.dart`:

```dart
on<CategoryRenamed>(_onRenamed);

Future<void> _onRenamed(
  CategoryRenamed event,
  Emitter<CategoryState> emit,
) async {
  final name = event.name.trim();
  if (name.isEmpty) {
    return;
  }

  try {
    await _firestore.collection('categories')
        .doc(event.categoryId)
        .update({'name': name});
  } catch (error) {
    emit(state.copyWith(
      status: CategoryStatus.error,
      errorMessage: error.toString(),
    ));
  }
}
```

3) Отправить его из UI:

```dart
_context.read<CategoryBloc>().add(
  CategoryRenamed(categoryId: category.id, name: newName),
);
```

## 9) Частые ошибки

- Забывать отменять подписки Firestore в `close()`.
- Триггерить события из `build()` (вместо этого используйте `initState`).
- Создавать несколько bloc для одного жизненного цикла экрана (держите владение ясным).
- Выполнять логику Firestore напрямую внутри виджета.

## 10) Следующие улучшения (опционально)

- Ввести репозитории для абстракции доступа к Firestore.
- Добавить кеширование или оффлайн-поддержку в блоках.
- Добавить тесты на логику bloc через `bloc_test`.
