import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/categories_dao.dart';

part 'categories_state.dart';

class CategoriesCubit extends Cubit<CategoriesState> {
  final CategoriesDao _dao;

  CategoriesCubit(this._dao) : super(CategoriesInitial());

  Future<void> load() async {
    emit(CategoriesLoading());
    try {
      final list = await _dao.allCategories();
      emit(CategoriesLoaded(list));
    } catch (e) {
      emit(CategoriesError(e.toString()));
    }
  }

  Future<void> add(String name) async {
    await _dao.addCategory(name.trim());
    await load();
  }

  Future<void> update(int id, String name) async {
    await _dao.updateCategory(id, name.trim());
    await load();
  }

  Future<void> delete(int id) async {
    await _dao.deleteCategory(id);
    await load();
  }
}
