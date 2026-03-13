part of 'category_bloc.dart';

abstract class CategoryEvent {
  const CategoryEvent();
}

class CategoriesStarted extends CategoryEvent {
  const CategoriesStarted();
}

class CategoryAdded extends CategoryEvent {
  const CategoryAdded(this.name);

  final String name;
}

class CategoryDeleted extends CategoryEvent {
  const CategoryDeleted(this.categoryId);

  final String categoryId;
}

class CategoriesChanged extends CategoryEvent {
  const CategoriesChanged(this.categories);

  final List<CategoryItem> categories;
}

class CategoriesFailed extends CategoryEvent {
  const CategoriesFailed(this.message);

  final String message;
}
