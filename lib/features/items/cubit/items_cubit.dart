import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/items_dao.dart';
import '../../../core/database/categories_dao.dart';

part 'items_state.dart';

class ItemsCubit extends Cubit<ItemsState> {
  final ItemsDao _itemsDao;
  final CategoriesDao _categoriesDao;

  ItemsCubit(this._itemsDao, this._categoriesDao) : super(ItemsInitial());

  Future<void> load() async {
    emit(ItemsLoading());
    try {
      final items = await _itemsDao.allItems();
      final cats = await _categoriesDao.allCategories();
      emit(ItemsLoaded(items, cats));
    } catch (e) {
      emit(ItemsError(e.toString()));
    }
  }

  Future<void> add(int categoryId, String name, double price) async {
    await _itemsDao.addItem(categoryId, name.trim(), price);
    await load();
  }

  Future<void> update(
      int id, int categoryId, String name, double price) async {
    await _itemsDao.updateItem(id, categoryId, name.trim(), price);
    await load();
  }

  Future<void> delete(int id) async {
    await _itemsDao.deleteItem(id);
    await load();
  }
}
