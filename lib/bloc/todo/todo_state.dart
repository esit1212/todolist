part of 'todo_bloc.dart';

enum TodoStatus { initial, loading, loaded, error }

class TodoState {
  const TodoState({
    this.status = TodoStatus.initial,
    this.todos = const [],
    this.archivedTodos = const [],
    this.errorMessage,
  });

  final TodoStatus status;
  final List<TodoItem> todos;
  final List<TodoItem> archivedTodos;
  final String? errorMessage;

  TodoState copyWith({
    TodoStatus? status,
    List<TodoItem>? todos,
    List<TodoItem>? archivedTodos,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TodoState(
      status: status ?? this.status,
      todos: todos ?? this.todos,
      archivedTodos: archivedTodos ?? this.archivedTodos,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
