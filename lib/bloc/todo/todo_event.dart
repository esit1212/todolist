part of 'todo_bloc.dart';

abstract class TodoEvent {
  const TodoEvent();
}

class TodosStarted extends TodoEvent {
  const TodosStarted();
}

class TodoAdded extends TodoEvent {
  const TodoAdded({required this.title, this.note = ''});

  final String title;
  final String note;
}

class TodoToggled extends TodoEvent {
  const TodoToggled({required this.todoId, required this.done});

  final String todoId;
  final bool done;
}

class TodoDeleted extends TodoEvent {
  const TodoDeleted(this.todoId);

  final String todoId;
}

class TodoRestored extends TodoEvent {
  const TodoRestored(this.todoId);

  final String todoId;
}

class ArchivedTodoDeleted extends TodoEvent {
  const ArchivedTodoDeleted(this.todoId);

  final String todoId;
}

class TodoNoteUpdated extends TodoEvent {
  const TodoNoteUpdated({required this.todoId, required this.note});

  final String todoId;
  final String note;
}

class TodosChanged extends TodoEvent {
  const TodosChanged({required this.todos, required this.archivedTodos});

  final List<TodoItem> todos;
  final List<TodoItem> archivedTodos;
}

class TodosFailed extends TodoEvent {
  const TodosFailed(this.message);

  final String message;
}
