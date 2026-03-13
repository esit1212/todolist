import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageRepository {
  LocalStorageRepository._();

  static final LocalStorageRepository instance = LocalStorageRepository._();

  static const String _storageKey = 'local_storage_v1';

  Future<List<Map<String, dynamic>>> getCategories() async {
    final data = await _readData();
    final categories = _categoriesRef(data)
        .whereType<Map>()
        .map((item) => item.map((key, value) => MapEntry('$key', value)))
        .toList();
    categories.sort(
      (a, b) => _asInt(b['createdAt']).compareTo(_asInt(a['createdAt'])),
    );
    return categories
        .map((category) => {'id': category['id'], 'name': category['name']})
        .toList();
  }

  Future<void> addCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final data = await _readData();
    final categories = _categoriesRef(data);
    categories.add({
      'id': _newId(),
      'name': trimmed,
      'createdAt': DateTime.now().microsecondsSinceEpoch,
    });
    await _writeData(data);
  }

  Future<void> deleteCategory(String categoryId) async {
    final data = await _readData();
    final categories = _categoriesRef(data);
    categories.removeWhere(
      (category) => category is Map && category['id'] == categoryId,
    );

    final todosByCategory = _todosByCategoryRef(data);
    todosByCategory.remove(categoryId);
    final archivedByCategory = _todosBucketRef(data, 'archivedTodosByCategory');
    archivedByCategory.remove(categoryId);

    await _writeData(data);
  }

  Future<List<Map<String, dynamic>>> getTodos(String categoryId) async {
    final data = await _readData();
    final todos = _todosRef(
      data,
      categoryId,
    ).whereType<Map>().map((item) => _toStringDynamicMap(item)).toList();
    todos.sort(
      (a, b) => _asInt(b['createdAt']).compareTo(_asInt(a['createdAt'])),
    );
    return todos.map(_toTodoView).toList();
  }

  Future<List<Map<String, dynamic>>> getArchivedTodos(String categoryId) async {
    final data = await _readData();
    final todos = _archivedTodosRef(
      data,
      categoryId,
    ).whereType<Map>().map((item) => _toStringDynamicMap(item)).toList();
    todos.sort(
      (a, b) => _asInt(b['archivedAt']).compareTo(_asInt(a['archivedAt'])),
    );
    return todos.map(_toTodoView).toList();
  }

  Future<void> addTodo({
    required String categoryId,
    required String title,
    String note = '',
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final data = await _readData();
    final todos = _todosRef(data, categoryId);
    todos.add({
      'id': _newId(),
      'title': trimmed,
      'note': note.trim(),
      'done': false,
      'subtasks': <dynamic>[],
      'createdAt': DateTime.now().microsecondsSinceEpoch,
    });
    await _writeData(data);
  }

  Future<void> archiveTodo({
    required String categoryId,
    required String todoId,
  }) async {
    final data = await _readData();
    final active = _todosRef(data, categoryId);
    final archived = _archivedTodosRef(data, categoryId);

    Map<String, dynamic>? movedTodo;
    active.removeWhere((todo) {
      final isMatch = todo is Map && todo['id'] == todoId;
      if (isMatch) {
        movedTodo = _toStringDynamicMap(todo);
      }
      return isMatch;
    });

    if (movedTodo != null) {
      movedTodo!['archivedAt'] = DateTime.now().microsecondsSinceEpoch;
      archived.add(movedTodo!);
      await _writeData(data);
    }
  }

  Future<void> restoreTodo({
    required String categoryId,
    required String todoId,
  }) async {
    final data = await _readData();
    final active = _todosRef(data, categoryId);
    final archived = _archivedTodosRef(data, categoryId);

    Map<String, dynamic>? restoredTodo;
    archived.removeWhere((todo) {
      final isMatch = todo is Map && todo['id'] == todoId;
      if (isMatch) {
        restoredTodo = _toStringDynamicMap(todo);
      }
      return isMatch;
    });

    if (restoredTodo != null) {
      restoredTodo!.remove('archivedAt');
      active.add(restoredTodo!);
      await _writeData(data);
    }
  }

  Future<void> deleteArchivedTodo({
    required String categoryId,
    required String todoId,
  }) async {
    final data = await _readData();
    final archived = _archivedTodosRef(data, categoryId);
    archived.removeWhere((todo) => todo is Map && todo['id'] == todoId);
    await _writeData(data);
  }

  Future<void> toggleTodo({
    required String categoryId,
    required String todoId,
    required bool done,
  }) async {
    final data = await _readData();
    final todos = _todosRef(data, categoryId);
    for (final todo in todos) {
      if (todo is Map && todo['id'] == todoId) {
        todo['done'] = done;
        break;
      }
    }
    await _writeData(data);
  }

  Future<void> updateTodoNote({
    required String categoryId,
    required String todoId,
    required String note,
  }) async {
    final data = await _readData();
    final todo = _findTodo(_todosRef(data, categoryId), todoId);
    if (todo == null) {
      return;
    }
    todo['note'] = note.trim();
    await _writeData(data);
  }

  Future<void> addSubtask({
    required String categoryId,
    required String todoId,
    required String title,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final data = await _readData();
    final todo = _findTodo(_todosRef(data, categoryId), todoId);
    if (todo == null) {
      return;
    }

    final subtasks = _subtasksRef(todo);
    subtasks.add({'id': _newId(), 'title': trimmed, 'done': false});
    await _writeData(data);
  }

  Future<void> toggleSubtask({
    required String categoryId,
    required String todoId,
    required String subtaskId,
    required bool done,
  }) async {
    final data = await _readData();
    final todo = _findTodo(_todosRef(data, categoryId), todoId);
    if (todo == null) {
      return;
    }

    final subtasks = _subtasksRef(todo);
    for (final subtask in subtasks) {
      if (subtask is Map && subtask['id'] == subtaskId) {
        subtask['done'] = done;
        break;
      }
    }

    await _writeData(data);
  }

  Future<void> deleteSubtask({
    required String categoryId,
    required String todoId,
    required String subtaskId,
  }) async {
    final data = await _readData();
    final todo = _findTodo(_todosRef(data, categoryId), todoId);
    if (todo == null) {
      return;
    }

    final subtasks = _subtasksRef(todo);
    subtasks.removeWhere(
      (subtask) => subtask is Map && subtask['id'] == subtaskId,
    );
    await _writeData(data);
  }

  Future<void> deleteTodo({
    required String categoryId,
    required String todoId,
  }) async {
    await archiveTodo(categoryId: categoryId, todoId: todoId);
  }

  Future<Map<String, dynamic>> _readData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null || jsonString.isEmpty) {
      return {
        'categories': <dynamic>[],
        'todosByCategory': <String, dynamic>{},
        'archivedTodosByCategory': <String, dynamic>{},
      };
    }

    final decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      return {
        'categories': <dynamic>[],
        'todosByCategory': <String, dynamic>{},
        'archivedTodosByCategory': <String, dynamic>{},
      };
    }

    decoded.putIfAbsent('categories', () => <dynamic>[]);
    decoded.putIfAbsent('todosByCategory', () => <String, dynamic>{});
    decoded.putIfAbsent('archivedTodosByCategory', () => <String, dynamic>{});
    return decoded;
  }

  Future<void> _writeData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(data));
  }

  List<dynamic> _categoriesRef(Map<String, dynamic> data) {
    final raw = data['categories'];
    if (raw is List) {
      return raw;
    }

    final created = <dynamic>[];
    data['categories'] = created;
    return created;
  }

  Map<String, dynamic> _todosByCategoryRef(Map<String, dynamic> data) {
    final raw = data['todosByCategory'];
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      final normalized = raw.map((key, value) => MapEntry('$key', value));
      data['todosByCategory'] = normalized;
      return normalized;
    }

    final created = <String, dynamic>{};
    data['todosByCategory'] = created;
    return created;
  }

  List<dynamic> _todosRef(Map<String, dynamic> data, String categoryId) {
    return _todosListFromBucket(
      data: data,
      bucketKey: 'todosByCategory',
      categoryId: categoryId,
    );
  }

  List<dynamic> _archivedTodosRef(
    Map<String, dynamic> data,
    String categoryId,
  ) {
    return _todosListFromBucket(
      data: data,
      bucketKey: 'archivedTodosByCategory',
      categoryId: categoryId,
    );
  }

  List<dynamic> _todosListFromBucket({
    required Map<String, dynamic> data,
    required String bucketKey,
    required String categoryId,
  }) {
    final todosByCategory = _todosBucketRef(data, bucketKey);
    final existing = todosByCategory[categoryId];

    if (existing is List) {
      return existing;
    }

    final created = <dynamic>[];
    todosByCategory[categoryId] = created;
    data[bucketKey] = todosByCategory;
    return created;
  }

  Map<String, dynamic> _todosBucketRef(Map<String, dynamic> data, String key) {
    final raw = data[key];
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      final normalized = raw.map(
        (bucketKey, value) => MapEntry('$bucketKey', value),
      );
      data[key] = normalized;
      return normalized;
    }

    final created = <String, dynamic>{};
    data[key] = created;
    return created;
  }

  Map<String, dynamic>? _findTodo(List<dynamic> todos, String todoId) {
    for (final todo in todos) {
      if (todo is Map && todo['id'] == todoId) {
        return _mapRef(todo);
      }
    }
    return null;
  }

  List<dynamic> _subtasksRef(Map<String, dynamic> todo) {
    final raw = todo['subtasks'];
    if (raw is List) {
      return raw;
    }

    final created = <dynamic>[];
    todo['subtasks'] = created;
    return created;
  }

  Map<String, dynamic> _toTodoView(Map<String, dynamic> todo) {
    final subtasks = _subtasksRef(todo)
        .whereType<Map>()
        .map((subtask) => _toStringDynamicMap(subtask))
        .map(
          (subtask) => {
            'id': subtask['id'],
            'title': subtask['title'] ?? '',
            'done': subtask['done'] == true,
          },
        )
        .toList();

    return {
      'id': todo['id'],
      'title': todo['title'] ?? '',
      'done': todo['done'] == true,
      'note': todo['note'] ?? '',
      'subtasks': subtasks,
    };
  }

  Map<String, dynamic> _mapRef(Map raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }

    final normalized = raw.map((key, value) => MapEntry('$key', value));
    raw
      ..clear()
      ..addAll(normalized);
    return raw.cast<String, dynamic>();
  }

  Map<String, dynamic> _toStringDynamicMap(Map raw) {
    return raw.map((key, value) => MapEntry('$key', value));
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  int _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }
}
