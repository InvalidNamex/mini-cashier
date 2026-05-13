part of 'items_cubit.dart';

abstract class ItemsState extends Equatable {
  const ItemsState();
  @override
  List<Object?> get props => [];
}

class ItemsInitial extends ItemsState {}

class ItemsLoading extends ItemsState {}

class ItemsLoaded extends ItemsState {
  final List<Item> items;
  final List<Category> categories;
  const ItemsLoaded(this.items, this.categories);
  @override
  List<Object?> get props => [items, categories];
}

class ItemsError extends ItemsState {
  final String message;
  const ItemsError(this.message);
  @override
  List<Object?> get props => [message];
}
