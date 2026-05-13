import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/users_dao.dart';

part 'users_state.dart';

class UsersCubit extends Cubit<UsersState> {
  final UsersDao _dao;

  UsersCubit(this._dao) : super(UsersInitial());

  Future<void> loadCashiers() async {
    emit(UsersLoading());
    try {
      final list = await _dao.allCashiers();
      emit(UsersLoaded(list));
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }

  Future<void> createCashier(String username, String password) async {
    try {
      await _dao.createCashier(username.trim(), password);
      await loadCashiers();
    } catch (_) {
      emit(const UsersError('اسم المستخدم موجود بالفعل'));
    }
  }

  Future<void> updateCashier(
      int id, String newUsername, String newPassword) async {
    try {
      await _dao.updateCashier(
        id,
        newUsername: newUsername,
        newPassword: newPassword.isEmpty ? null : newPassword,
      );
      await loadCashiers();
    } catch (_) {
      emit(const UsersError('اسم المستخدم موجود بالفعل'));
    }
  }

  Future<void> deleteCashier(int id) async {
    await _dao.deleteCashier(id);
    await loadCashiers();
  }
}
