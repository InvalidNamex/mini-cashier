import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../license_cubit.dart';
import '../../../core/constants.dart';

bool _isSaPassword(String input) {
  final hash = sha256.convert(utf8.encode(input)).toString();
  return hash == AppConstants.saPasswordHash;
}

/// Full-screen wall shown when the app license has expired or was never set.
/// The SA can enter their password here to renew access.
class SuspendedScreen extends StatefulWidget {
  const SuspendedScreen({super.key});

  @override
  State<SuspendedScreen> createState() => _SuspendedScreenState();
}

class _SuspendedScreenState extends State<SuspendedScreen> {
  final _ctrl = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_isSaPassword(_ctrl.text)) {
      setState(() => _error = null);
      _showLicenseDialog();
    } else {
      setState(() => _error = 'كلمة المرور غير صحيحة');
    }
  }

  void _showLicenseDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _LicenseChoiceDialog(
        cubit: context.read<LicenseCubit>(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1B2F),
      body: Center(
        child: Card(
          elevation: 8,
          margin: const EdgeInsets.all(24),
          child: Container(
            width: 380,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 56, color: Colors.red),
                const SizedBox(height: 12),
                const Text(
                  'التطبيق موقوف',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'انتهت صلاحية التجربة أو لم يتم تفعيل الترخيص بعد.\n'
                  'يرجى إدخال كلمة مرور المسؤول (SA) لتجديد الوصول.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _ctrl,
                  obscureText: _obscure,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: 'كلمة مرور SA',
                    prefixIcon: const Icon(Icons.admin_panel_settings_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    errorText: _error,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B6B4A),
                    ),
                    onPressed: _submit,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'تفعيل',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared dialog used both from SuspendedScreen and the login screen.
// ---------------------------------------------------------------------------

class _LicenseChoiceDialog extends StatefulWidget {
  final LicenseCubit cubit;
  const _LicenseChoiceDialog({required this.cubit});

  @override
  State<_LicenseChoiceDialog> createState() => _LicenseChoiceDialogState();
}

class _LicenseChoiceDialogState extends State<_LicenseChoiceDialog> {
  bool _loading = false;

  Future<void> _activate(bool infinite) async {
    setState(() => _loading = true);
    if (infinite) {
      await widget.cubit.activateInfinite();
    } else {
      await widget.cubit.activateTrial();
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.verified_user_outlined, color: Color(0xFF1B6B4A)),
          SizedBox(width: 8),
          Text('إدارة الترخيص'),
        ],
      ),
      content: _loading
          ? const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            )
          : const Text(
              'اختر نوع الترخيص:\n\n'
              '• تشغيل دائم — لا تنتهي صلاحية التطبيق.\n'
              '• تجربة ٣ أيام — يتوقف التطبيق بعد ٣ أيام ويحتاج إلى تجديد.',
              style: TextStyle(height: 1.6),
            ),
      actions: _loading
          ? []
          : [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إلغاء'),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.timer_outlined),
                label: const Text('تجربة ٣ أيام'),
                onPressed: () => _activate(false),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B6B4A),
                ),
                icon: const Icon(Icons.all_inclusive, color: Colors.white),
                label: const Text(
                  'تشغيل دائم',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () => _activate(true),
              ),
            ],
    );
  }
}

/// Convenience function — show the SA license-management dialog.
/// Call this after verifying the SA password.
void showSaLicenseDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => _LicenseChoiceDialog(
      cubit: context.read<LicenseCubit>(),
    ),
  );
}
