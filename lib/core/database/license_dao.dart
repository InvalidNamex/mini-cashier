import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'app_database.dart';
import 'tables.dart';
import '../constants.dart';

part 'license_dao.g.dart';

@DriftAccessor(tables: [AppLicenses])
class LicenseDao extends DatabaseAccessor<AppDatabase>
    with _$LicenseDaoMixin {
  LicenseDao(super.db);

  // ---------------------------------------------------------------------------
  // Signing helpers
  // ---------------------------------------------------------------------------

  /// Computes HMAC-SHA256 over the license fields so that any offline
  /// tampering with the database record is detectable.
  /// DateTime is truncated to millisecond precision to survive a SQLite
  /// round-trip (which stores at ms resolution), ensuring sign == verify.
  static String _sign(String mode, DateTime? trialExpiresAt) {
    // Truncate to ms so the signature computed here always matches the
    // value that comes back from SQLite (which drops sub-ms precision).
    final truncated = trialExpiresAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(
            trialExpiresAt.millisecondsSinceEpoch,
            isUtc: true,
          );
    final payload =
        '$mode|${truncated?.toIso8601String() ?? 'null'}';
    final key = utf8.encode(AppConstants.licenseSigningKey);
    final msg = utf8.encode(payload);
    return Hmac(sha256, key).convert(msg).toString();
  }

  static bool _verify(AppLicense record) {
    if (record.signature == null) return false;
    final expected = _sign(record.mode, record.trialExpiresAt);
    return expected == record.signature;
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns the current license record **only if** its signature is valid.
  /// Returns null if no record exists OR if the record has been tampered with.
  Future<AppLicense?> getLicense() async {
    final record = await select(appLicenses).getSingleOrNull();
    if (record == null) return null;
    if (!_verify(record)) return null; // tampered → treat as no license
    return record;
  }

  /// Sets the license to run indefinitely.
  Future<void> setInfinite() async {
    final sig = _sign('infinite', null);
    await delete(appLicenses).go();
    await into(appLicenses).insert(
      AppLicensesCompanion.insert(
        mode: 'infinite',
        signature: Value(sig),
      ),
    );
  }

  /// Sets the license to a 3-day trial starting from now.
  Future<void> setTrial() async {
    final raw = DateTime.now().toUtc().add(const Duration(days: 3));
    // Truncate to milliseconds so the stored value matches what _sign expects.
    final expires = DateTime.fromMillisecondsSinceEpoch(
        raw.millisecondsSinceEpoch, isUtc: true);
    final sig = _sign('trial', expires);
    await delete(appLicenses).go();
    await into(appLicenses).insert(
      AppLicensesCompanion.insert(
        mode: 'trial',
        trialExpiresAt: Value(expires),
        signature: Value(sig),
      ),
    );
  }

  /// Restores a trial license with a specific expiry (used during import).
  Future<void> setTrialWithExpiry(DateTime expires) async {
    final utc = DateTime.fromMillisecondsSinceEpoch(
        expires.toUtc().millisecondsSinceEpoch, isUtc: true);
    final sig = _sign('trial', utc);
    await delete(appLicenses).go();
    await into(appLicenses).insert(
      AppLicensesCompanion.insert(
        mode: 'trial',
        trialExpiresAt: Value(utc),
        signature: Value(sig),
      ),
    );
  }
}
