part of 'todo_bloc.dart';

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

  TodoState copyWith({
    TodoStatus? status,
    List<TodoItem>? todos,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TodoState(
      status: status ?? this.status,
      todos: todos ?? this.todos,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
