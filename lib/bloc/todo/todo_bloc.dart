import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/local_storage_repository.dart';

part 'todo_event.dart';
part 'todo_state.dart';

class TodoItem {
  const TodoItem({
    required this.id,
    required this.title,
    required this.done,
    required this.note,
  });

  final String id;
  final String title;
  final bool done;
  final String note;
}

class TodoBloc extends Bloc<TodoEvent, TodoState> {
  TodoBloc({
    required this.categoryId,
    required LocalStorageRepository repository,
  }) : _repository = repository,
       super(const TodoState()) {
    on<TodosStarted>(_onStarted);
    on<TodoAdded>(_onAdded);
    on<TodoToggled>(_onToggled);
    on<TodoDeleted>(_onDeleted);
    on<TodoRestored>(_onRestored);
    on<ArchivedTodoDeleted>(_onArchivedDeleted);
    on<TodoNoteUpdated>(_onNoteUpdated);
    on<TodosChanged>(_onChanged);
    on<TodosFailed>(_onFailed);
  }

  final LocalStorageRepository _repository;
  final String categoryId;

  Future<void> _onStarted(TodosStarted event, Emitter<TodoState> emit) async {
    emit(state.copyWith(status: TodoStatus.loading, clearError: true));
    await _refreshTodos();
  }

  Future<void> _onAdded(TodoAdded event, Emitter<TodoState> emit) async {
    final title = event.title.trim();
    if (title.isEmpty) {
      return;
    }

    try {
      await _repository.addTodo(
        categoryId: categoryId,
        title: title,
        note: event.note,
      );
      await _refreshTodos();
    } catch (error) {
      emit(
        state.copyWith(
          status: TodoStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onToggled(TodoToggled event, Emitter<TodoState> emit) async {
    try {
      await _repository.toggleTodo(
        categoryId: categoryId,
        todoId: event.todoId,
        done: event.done,
      );
      await _refreshTodos();
    } catch (error) {
      emit(
        state.copyWith(
          status: TodoStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onDeleted(TodoDeleted event, Emitter<TodoState> emit) async {
    try {
      await _repository.deleteTodo(
        categoryId: categoryId,
        todoId: event.todoId,
      );
      await _refreshTodos();
    } catch (error) {
      emit(
        state.copyWith(
          status: TodoStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onRestored(TodoRestored event, Emitter<TodoState> emit) async {
    try {
      await _repository.restoreTodo(
        categoryId: categoryId,
        todoId: event.todoId,
      );
      await _refreshTodos();
    } catch (error) {
      emit(
        state.copyWith(
          status: TodoStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onArchivedDeleted(
    ArchivedTodoDeleted event,
    Emitter<TodoState> emit,
  ) async {
    try {
      await _repository.deleteArchivedTodo(
        categoryId: categoryId,
        todoId: event.todoId,
      );
      await _refreshTodos();
    } catch (error) {
      emit(
        state.copyWith(
          status: TodoStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onNoteUpdated(
    TodoNoteUpdated event,
    Emitter<TodoState> emit,
  ) async {
    try {
      await _repository.updateTodoNote(
        categoryId: categoryId,
        todoId: event.todoId,
        note: event.note,
      );
      await _refreshTodos();
    } catch (error) {
      emit(
        state.copyWith(
          status: TodoStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void _onChanged(TodosChanged event, Emitter<TodoState> emit) {
    emit(
      state.copyWith(
        status: TodoStatus.loaded,
        todos: event.todos,
        archivedTodos: event.archivedTodos,
        clearError: true,
      ),
    );
  }

  void _onFailed(TodosFailed event, Emitter<TodoState> emit) {
    emit(state.copyWith(status: TodoStatus.error, errorMessage: event.message));
  }

  Future<void> _refreshTodos() async {
    try {
      final todosData = await _repository.getTodos(categoryId);
      final archivedTodosData = await _repository.getArchivedTodos(categoryId);
      final todos = todosData
          .map(
            (item) => TodoItem(
              id: item['id'] as String,
              title: item['title'] as String? ?? '',
              done: item['done'] as bool? ?? false,
              note: item['note'] as String? ?? '',
            ),
          )
          .toList();
      final archivedTodos = archivedTodosData
          .map(
            (item) => TodoItem(
              id: item['id'] as String,
              title: item['title'] as String? ?? '',
              done: item['done'] as bool? ?? false,
              note: item['note'] as String? ?? '',
            ),
          )
          .toList();
      add(TodosChanged(todos: todos, archivedTodos: archivedTodos));
    } catch (error) {
      add(TodosFailed(error.toString()));
    }
  }
}
