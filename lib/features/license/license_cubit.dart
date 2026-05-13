import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/database/license_dao.dart';

part 'license_state.dart';

class LicenseCubit extends Cubit<LicenseState> {
  final LicenseDao _dao;

  LicenseCubit(this._dao) : super(const LicenseLoading());

  /// Called once on app start to determine the current license status.
  Future<void> checkLicense() async {
    final record = await _dao.getLicense();
    if (record == null) {
      emit(const LicenseSuspended());
      return;
    }
    if (record.mode == 'infinite') {
      emit(const LicenseActive(isInfinite: true));
      return;
    }
    // trial
    final expires = record.trialExpiresAt;
    if (expires != null && DateTime.now().toUtc().isBefore(expires)) {
      emit(LicenseActive(isInfinite: false, trialExpiresAt: expires));
    } else {
      emit(const LicenseSuspended());
    }
  }

  /// Activates an infinite license.
  Future<void> activateInfinite() async {
    await _dao.setInfinite();
    emit(const LicenseActive(isInfinite: true));
  }

  /// Activates a 3-day trial from now.
  Future<void> activateTrial() async {
    await _dao.setTrial();
    final expires = DateTime.now().toUtc().add(const Duration(days: 3));
    emit(LicenseActive(isInfinite: false, trialExpiresAt: expires));
  }
}
