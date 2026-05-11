import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/database/app_database.dart';
import '../../core/database/users_dao.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final UsersDao _usersDao;

  AuthCubit(this._usersDao) : super(AuthInitial());

  Future<void> login(String username, String password) async {
    emit(AuthLoading());
    try {
      final user = await _usersDao.authenticate(username.trim(), password);
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthError('اسم المستخدم أو كلمة المرور غير صحيحة'));
      }
    } catch (_) {
      emit(const AuthError('حدث خطأ، حاول مرة أخرى'));
    }
  }

  void logout() => emit(AuthInitial());

  User? get currentUser {
    final s = state;
    if (s is AuthAuthenticated) return s.user;
    return null;
  }
}
