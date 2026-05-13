import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/auth_cubit.dart';
import '../database/app_database.dart';
import '../services/db_export_service.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final isAdmin =
        authState is AuthAuthenticated && authState.user.isAdmin;
    final location = GoRouterState.of(context).uri.toString();

    return Scaffold(
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
            selectedLabelTextStyle:
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                      if (isAdmin)
                        IconButton(
                          icon: const Icon(Icons.download_outlined,
                              color: Colors.white70),
                          tooltip: 'تصدير قاعدة البيانات',
                          onPressed: () async {
                            final db = context.read<AppDatabase>();
                            await DbExportService.exportToFile(db);
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white70),
                        tooltip: 'خروج',
                        onPressed: () {
                          context.read<AuthCubit>().logout();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            destinations: _buildDestinations(isAdmin),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
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
