import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'category_event.dart';
part 'category_state.dart';

class CategoryItem {
  const CategoryItem({required this.id, required this.name});

  final String id;
  final String name;
}

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

  final FirebaseFirestore _firestore;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

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
                .map(
                  (doc) =>
                      CategoryItem(id: doc.id, name: doc.data()['name'] ?? ''),
                )
                .toList();
            add(CategoriesChanged(categories));
          },
          onError: (Object error) {
            add(CategoriesFailed(error.toString()));
          },
        );
  }

  Future<void> _onAdded(
    CategoryAdded event,
    Emitter<CategoryState> emit,
  ) async {
    final name = event.name.trim();
    if (name.isEmpty) {
      return;
    }

    try {
      await _firestore.collection('categories').add({
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      emit(
        state.copyWith(
          status: CategoryStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onDeleted(
    CategoryDeleted event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      await _firestore.collection('categories').doc(event.categoryId).delete();
    } catch (error) {
      emit(
        state.copyWith(
          status: CategoryStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void _onChanged(CategoriesChanged event, Emitter<CategoryState> emit) {
    emit(
      state.copyWith(
        status: CategoryStatus.loaded,
        categories: event.categories,
        clearError: true,
      ),
    );
  }

  void _onFailed(CategoriesFailed event, Emitter<CategoryState> emit) {
    emit(
      state.copyWith(status: CategoryStatus.error, errorMessage: event.message),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
