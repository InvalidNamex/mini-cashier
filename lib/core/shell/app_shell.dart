import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/auth_cubit.dart';
import '../../features/license/license_cubit.dart';
import '../database/app_database.dart';
import '../services/db_export_service.dart';
import '../services/db_import_service.dart';

class AppShell extends StatefulWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _busy = false;

  // ---------------------------------------------------------------------------
  // Admin password verification
  // ---------------------------------------------------------------------------

  /// Shows a dialog asking for the current admin's password.
  /// Returns true only if the password is correct.
  Future<bool> _askAdminPassword() async {
    final db = context.read<AppDatabase>();
    final username = context.read<AuthCubit>().currentUser?.username ?? '';
    final ctrl = TextEditingController();
    bool obscure = true;
    String? error;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (dlgCtx, setS) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock_outline, color: Color(0xFF1B6B4A)),
              SizedBox(width: 8),
              Text('تأكيد كلمة المرور'),
            ],
          ),
          content: TextField(
            controller: ctrl,
            obscureText: obscure,
            textDirection: TextDirection.ltr,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'كلمة مرور المسؤول',
              border: const OutlineInputBorder(),
              errorText: error,
              suffixIcon: IconButton(
                icon: Icon(obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () => setS(() => obscure = !obscure),
              ),
            ),
            onSubmitted: (_) async {
              final user =
                  await db.usersDao.authenticate(username, ctrl.text);
              if (!dlgCtx.mounted) return;
              if (user != null) {
                Navigator.of(dlgCtx).pop(true);
              } else {
                setS(() => error = 'كلمة المرور غير صحيحة');
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dlgCtx).pop(false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B6B4A)),
              onPressed: () async {
                final user =
                    await db.usersDao.authenticate(username, ctrl.text);
                if (!dlgCtx.mounted) return;
                if (user != null) {
                  Navigator.of(dlgCtx).pop(true);
                } else {
                  setS(() => error = 'كلمة المرور غير صحيحة');
                }
              },
              child: const Text('تأكيد',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
    return confirmed == true;
  }

  // ---------------------------------------------------------------------------
  // Export
  // ---------------------------------------------------------------------------

  Future<void> _handleExport() async {
    final ok = await _askAdminPassword();
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await DbExportService.exportToFile(context.read<AppDatabase>());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Import
  // ---------------------------------------------------------------------------

  Future<void> _handleImport() async {
    final ok = await _askAdminPassword();
    if (!ok || !mounted) return;

    // Confirm destructive action
    final proceed = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('تحذير'),
          ],
        ),
        content: const Text(
          'سيؤدي الاستيراد إلى استبدال جميع البيانات الحالية بالبيانات من الملف. '
          'هذا الإجراء لا يمكن التراجع عنه.\n\nهل تريد المتابعة؟',
          style: TextStyle(height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlgCtx).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(dlgCtx).pop(true),
            child: const Text('متابعة',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) return;

    setState(() => _busy = true);
    String? error;
    try {
      error = await DbImportService.importFromFile(context.read<AppDatabase>());
      if (mounted && error == null) {
        // Re-check license since it may have changed in the backup.
        await context.read<LicenseCubit>().checkLicense();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ?? 'تم الاستيراد بنجاح'),
      backgroundColor: error != null ? Colors.red.shade700 : Colors.green,
    ));
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final isAdmin =
        authState is AuthAuthenticated && authState.user.isAdmin;
    final location = GoRouterState.of(context).uri.toString();

    return Stack(
      children: [
        Scaffold(
          body: Row(
            children: [
              NavigationRail(
                extended: true,
                minExtendedWidth: 180,
                backgroundColor: const Color(0xFF1B6B4A),
                selectedIconTheme:
                    const IconThemeData(color: Colors.white),
                unselectedIconTheme:
                    const IconThemeData(color: Colors.white70),
                selectedLabelTextStyle: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
                unselectedLabelTextStyle:
                    const TextStyle(color: Colors.white70),
                indicatorColor: Colors.white24,
                selectedIndex: _selectedIndex(location, isAdmin),
                onDestinationSelected: (i) =>
                    _onNav(context, i, isAdmin),
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      const Icon(Icons.point_of_sale,
                          color: Colors.white, size: 32),
                      const SizedBox(height: 4),
                      Text(
                        'الكاشير',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                trailing: Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isAdmin) ...[
                            IconButton(
                              icon: const Icon(Icons.download_outlined,
                                  color: Colors.white70),
                              tooltip: 'تصدير قاعدة البيانات',
                              onPressed: _busy ? null : _handleExport,
                            ),
                            IconButton(
                              icon: const Icon(Icons.upload_outlined,
                                  color: Colors.white70),
                              tooltip: 'استيراد قاعدة البيانات',
                              onPressed: _busy ? null : _handleImport,
                            ),
                          ],
                          IconButton(
                            icon: const Icon(Icons.logout,
                                color: Colors.white70),
                            tooltip: 'خروج',
                            onPressed: () =>
                                context.read<AuthCubit>().logout(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                destinations: _buildDestinations(isAdmin),
              ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(child: widget.child),
            ],
          ),
        ),
        // Loading overlay shown during import/export
        if (_busy)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x66000000),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('جارٍ المعالجة...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<NavigationRailDestination> _buildDestinations(bool isAdmin) {
    final destinations = <NavigationRailDestination>[
      const NavigationRailDestination(
        icon: Icon(Icons.point_of_sale_outlined),
        selectedIcon: Icon(Icons.point_of_sale),
        label: Text('نقطة البيع'),
      ),
    ];
    if (isAdmin) {
      destinations.addAll([
        const NavigationRailDestination(
          icon: Icon(Icons.category_outlined),
          selectedIcon: Icon(Icons.category),
          label: Text('الفئات'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2),
          label: Text('الأصناف'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: Text('المستخدمين'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart),
          label: Text('التقارير'),
        ),
      ]);
    }
    return destinations;
  }

  int _selectedIndex(String location, bool isAdmin) {
    if (location.startsWith('/pos')) return 0;
    if (!isAdmin) return 0;
    if (location.startsWith('/categories')) return 1;
    if (location.startsWith('/items')) return 2;
    if (location.startsWith('/users')) return 3;
    if (location.startsWith('/reports')) return 4;
    return 0;
  }

  void _onNav(BuildContext context, int index, bool isAdmin) {
    switch (index) {
      case 0:
        context.go('/pos');
        break;
      case 1:
        if (isAdmin) context.go('/categories');
        break;
      case 2:
        if (isAdmin) context.go('/items');
        break;
      case 3:
        if (isAdmin) context.go('/users');
        break;
      case 4:
        if (isAdmin) context.go('/reports');
        break;
    }
  }
}
