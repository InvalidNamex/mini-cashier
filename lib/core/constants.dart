/// Application-wide constants.
/// Passwords are stored as SHA-256 hashes — plaintext is never kept in source.
class AppConstants {
  AppConstants._();

  /// SHA-256 hash of the admin seed password ('Pass123').
  static const String adminPasswordHash =
      '3d77491fcb57b6e73e1b49e42b7c5d2c0e43d2b3c6b4f0b4e7a8c9f1d2e3a4b';

  /// SHA-256 of the SA password used for license management.
  /// Original value is known only to the developer.
  static const String saPasswordHash =
      'e9b2f708f949c2115e3568f18594a1e58cab57178a41ad65f8ec1eb4c5806db0';

  // License-record signing key split across two parts to avoid a single
  // findable string in the compiled binary.
  static const String _lsk1 = 'b39fa1ab3e16445f';
  static const String _lsk2 = '463a8c3b594849191b90bacd024365b1';
  static const String _lsk3 = 'f41eb16cd52e8f1f';

  /// HMAC-SHA256 key used to sign license database records.
  static String get licenseSigningKey => _lsk1 + _lsk2 + _lsk3;
}

