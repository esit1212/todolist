part of 'category_bloc.dart';

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

  CategoryState copyWith({
    CategoryStatus? status,
    List<CategoryItem>? categories,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CategoryState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
