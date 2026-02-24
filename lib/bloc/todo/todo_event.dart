part of 'todo_bloc.dart';

sealed class TodoEvent {
  const TodoEvent();
}

final class TodosStarted extends TodoEvent {
  const TodosStarted();
}

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

final class TodosChanged extends TodoEvent {
  const TodosChanged(this.todos);

  final List<TodoItem> todos;
}

final class TodosFailed extends TodoEvent {
  const TodosFailed(this.message);

  final String message;
}
