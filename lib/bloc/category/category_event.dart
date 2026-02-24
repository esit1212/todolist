part of 'category_bloc.dart';

sealed class CategoryEvent {
  const CategoryEvent();
}

final class CategoriesStarted extends CategoryEvent {
  const CategoriesStarted();
}

final class CategoryAdded extends CategoryEvent {
  const CategoryAdded(this.name);

  final String name;
}

final class CategoryDeleted extends CategoryEvent {
  const CategoryDeleted(this.categoryId);

  final String categoryId;
}

final class CategoriesChanged extends CategoryEvent {
  const CategoriesChanged(this.categories);

  final List<CategoryItem> categories;
}

final class CategoriesFailed extends CategoryEvent {
  const CategoriesFailed(this.message);

  final String message;
}
