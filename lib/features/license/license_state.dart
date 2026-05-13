part of 'license_cubit.dart';

abstract class LicenseState extends Equatable {
  const LicenseState();
}

class LicenseLoading extends LicenseState {
  const LicenseLoading();
  @override
  List<Object?> get props => [];
}

/// The app has a valid, active license (either infinite or trial not yet expired).
class LicenseActive extends LicenseState {
  final bool isInfinite;

  /// Null when [isInfinite] is true.
  final DateTime? trialExpiresAt;

  const LicenseActive({required this.isInfinite, this.trialExpiresAt});

  @override
  List<Object?> get props => [isInfinite, trialExpiresAt];
}

/// No license or expired trial — the app is suspended.
class LicenseSuspended extends LicenseState {
  const LicenseSuspended();
  @override
  List<Object?> get props => [];
}
