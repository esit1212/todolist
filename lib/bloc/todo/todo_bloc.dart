import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'todo_event.dart';
part 'todo_state.dart';

class TodoItem {
  const TodoItem({required this.id, required this.title, required this.done});

  final String id;
  final String title;
  final bool done;
}

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

  final FirebaseFirestore _firestore;
  final String categoryId;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  CollectionReference<Map<String, dynamic>> get _todosRef =>
      _firestore.collection('categories').doc(categoryId).collection('todos');

  Future<void> _onStarted(TodosStarted event, Emitter<TodoState> emit) async {
    emit(state.copyWith(status: TodoStatus.loading, clearError: true));

    await _subscription?.cancel();
    _subscription = _todosRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            final todos = snapshot.docs
                .map(
                  (doc) => TodoItem(
                    id: doc.id,
                    title: doc.data()['title'] ?? '',
                    done: doc.data()['done'] ?? false,
                  ),
                )
                .toList();
            add(TodosChanged(todos));
          },
          onError: (Object error) {
            add(TodosFailed(error.toString()));
          },
        );
  }

  Future<void> _onAdded(TodoAdded event, Emitter<TodoState> emit) async {
    final title = event.title.trim();
    if (title.isEmpty) {
      return;
    }

    try {
      await _todosRef.add({
        'title': title,
        'done': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
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
      await _todosRef.doc(event.todoId).update({'done': event.done});
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
      await _todosRef.doc(event.todoId).delete();
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
        clearError: true,
      ),
    );
  }

  void _onFailed(TodosFailed event, Emitter<TodoState> emit) {
    emit(state.copyWith(status: TodoStatus.error, errorMessage: event.message));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
