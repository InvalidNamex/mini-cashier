import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth_cubit.dart';
import '../../../core/constants.dart';
import '../../license/screens/suspended_screen.dart';

bool _isSaPassword(String input) {
  final hash = sha256.convert(utf8.encode(input)).toString();
  return hash == AppConstants.saPasswordHash;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // SA password intercept — open license management instead of logging in.
      if (_isSaPassword(_passwordCtrl.text)) {
        _passwordCtrl.clear();
        showSaLicenseDialog(context);
        return;
      }
      context.read<AuthCubit>().login(_usernameCtrl.text, _passwordCtrl.text);
    }
  }

  void _showSaPasswordPrompt() {
    final ctrl = TextEditingController();
    bool obscure = true;
    String? error;

    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (dlgCtx, setDlgState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.admin_panel_settings_outlined,
                  color: Color(0xFF1B6B4A)),
              SizedBox(width: 8),
              Text('SA Login'),
            ],
          ),
          content: TextField(
            controller: ctrl,
            obscureText: obscure,
            textDirection: TextDirection.ltr,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'كلمة مرور SA',
              border: const OutlineInputBorder(),
              errorText: error,
              suffixIcon: IconButton(
                icon: Icon(obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () => setDlgState(() => obscure = !obscure),
              ),
            ),
            onSubmitted: (_) {
              if (_isSaPassword(ctrl.text)) {
                Navigator.of(dlgCtx).pop();
                showSaLicenseDialog(context);
              } else {
                setDlgState(() => error = 'كلمة المرور غير صحيحة');
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dlgCtx).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B6B4A)),
              onPressed: () {
                if (_isSaPassword(ctrl.text)) {
                  Navigator.of(dlgCtx).pop();
                  showSaLicenseDialog(context);
                } else {
                  setDlgState(() => error = 'كلمة المرور غير صحيحة');
                }
              },
              child: const Text('دخول',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: BlocListener<AuthCubit, AuthState>(
        listener: (ctx, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
        },
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              elevation: 6,
              margin: const EdgeInsets.all(24),
              child: Container(
                width: 380,
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.point_of_sale,
                          size: 56, color: Color(0xFF1B6B4A)),
                      const SizedBox(height: 8),
                      Text(
                        'الكاشير',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1B6B4A),
                            ),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _usernameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'اسم المستخدم',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        textDirection: TextDirection.ltr,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        textDirection: TextDirection.ltr,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'مطلوب' : null,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 24),
                      BlocBuilder<AuthCubit, AuthState>(
                        builder: (ctx, state) {
                          if (state is AuthLoading) {
                            return const CircularProgressIndicator();
                          }
                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submit,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text('دخول',
                                    style: TextStyle(fontSize: 16)),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          icon: const Icon(
                            Icons.admin_panel_settings_outlined,
                            size: 16,
                            color: Colors.black38,
                          ),
                          label: const Text(
                            'SA Login',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black38,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: _showSaPasswordPrompt,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
