import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/local_storage_repository.dart';

part 'category_event.dart';
part 'category_state.dart';

class CategoryItem {
  const CategoryItem({required this.id, required this.name});

  final String id;
  final String name;
}

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  CategoryBloc({required LocalStorageRepository repository})
    : _repository = repository,
      super(const CategoryState()) {
    on<CategoriesStarted>(_onStarted);
    on<CategoryAdded>(_onAdded);
    on<CategoryDeleted>(_onDeleted);
    on<CategoriesChanged>(_onChanged);
    on<CategoriesFailed>(_onFailed);
  }

  final LocalStorageRepository _repository;

  Future<void> _onStarted(
    CategoriesStarted event,
    Emitter<CategoryState> emit,
  ) async {
    emit(state.copyWith(status: CategoryStatus.loading, clearError: true));
    await _refreshCategories();
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
      await _repository.addCategory(name);
      await _refreshCategories();
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
      await _repository.deleteCategory(event.categoryId);
      await _refreshCategories();
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

  Future<void> _refreshCategories() async {
    try {
      final categoriesData = await _repository.getCategories();
      final categories = categoriesData
          .map(
            (item) => CategoryItem(
              id: item['id'] as String,
              name: item['name'] as String? ?? '',
            ),
          )
          .toList();
      add(CategoriesChanged(categories));
    } catch (error) {
      add(CategoriesFailed(error.toString()));
    }
  }
}
