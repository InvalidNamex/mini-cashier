import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/database/app_database.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_cubit.dart';
import 'features/categories/cubit/categories_cubit.dart';
import 'features/items/cubit/items_cubit.dart';
import 'features/reports/cubit/reports_cubit.dart';
import 'features/users/cubit/users_cubit.dart';
import 'features/pos/bloc/pos_cubit.dart';
import 'features/license/license_cubit.dart';
import 'features/license/screens/suspended_screen.dart';

class CashierApp extends StatefulWidget {
  final AppDatabase db;
  const CashierApp({super.key, required this.db});

  @override
  State<CashierApp> createState() => _CashierAppState();
}

class _CashierAppState extends State<CashierApp> {
  late final AuthCubit _authCubit;
  late final LicenseCubit _licenseCubit;
  late final GoRouterWrapper _routerWrapper;

  @override
  void initState() {
    super.initState();
    _authCubit = AuthCubit(widget.db.usersDao);
    _licenseCubit = LicenseCubit(widget.db.licenseDao);
    _routerWrapper = GoRouterWrapper(_authCubit);
    _licenseCubit.checkLicense();
  }

  @override
  void dispose() {
    _authCubit.close();
    _licenseCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: widget.db.ordersDao),
        RepositoryProvider.value(value: widget.db.categoriesDao),
        RepositoryProvider.value(value: widget.db.itemsDao),
        RepositoryProvider.value(value: widget.db.usersDao),
        RepositoryProvider.value(value: widget.db),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _authCubit),
          BlocProvider.value(value: _licenseCubit),
          BlocProvider(
            create: (_) =>
                CategoriesCubit(widget.db.categoriesDao),
          ),
          BlocProvider(
            create: (_) =>
                ItemsCubit(widget.db.itemsDao, widget.db.categoriesDao),
          ),
          BlocProvider(
            create: (_) => UsersCubit(widget.db.usersDao),
          ),
          BlocProvider(
            create: (_) => ReportsCubit(widget.db.ordersDao),
          ),
        ],
        child: BlocBuilder<LicenseCubit, LicenseState>(
          bloc: _licenseCubit,
          builder: (ctx, licenseState) {
            // While checking license, show a loading spinner inside the app shell.
            if (licenseState is LicenseLoading) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.theme,
                home: const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            // App suspended — show the SA unlock screen.
            if (licenseState is LicenseSuspended) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'الكاشير',
                theme: AppTheme.theme,
                locale: const Locale('ar'),
                supportedLocales: const [Locale('ar'), Locale('en')],
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                home: const SuspendedScreen(),
                builder: (context, child) => Directionality(
                  textDirection: TextDirection.rtl,
                  child: child!,
                ),
              );
            }

            // License is active — run the full app.
            return BlocBuilder<AuthCubit, AuthState>(
              bloc: _authCubit,
              builder: (ctx, authState) {
                final user =
                    authState is AuthAuthenticated ? authState.user : null;
                return BlocProvider(
                  key: ValueKey(user?.id),
                  create: (_) => user != null
                      ? PosCubit(
                          cashierId: user.id,
                          cashierName: user.username,
                          ordersDao: widget.db.ordersDao,
                          categoriesDao: widget.db.categoriesDao,
                          itemsDao: widget.db.itemsDao,
                        )
                      : PosCubit(
                          cashierId: 0,
                          cashierName: '',
                          ordersDao: widget.db.ordersDao,
                          categoriesDao: widget.db.categoriesDao,
                          itemsDao: widget.db.itemsDao,
                        ),
                  child: MaterialApp.router(
                    debugShowCheckedModeBanner: false,
                    title: 'الكاشير',
                    theme: AppTheme.theme,
                    locale: const Locale('ar'),
                    supportedLocales: const [Locale('ar'), Locale('en')],
                    localizationsDelegates: const [
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    routerConfig: _routerWrapper.router,
                    builder: (context, child) => Directionality(
                      textDirection: TextDirection.rtl,
                      child: child!,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class GoRouterWrapper {
  final AuthCubit authCubit;
  late final router = buildRouter(authCubit);
  GoRouterWrapper(this.authCubit);
}
