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

class CashierApp extends StatefulWidget {
  final AppDatabase db;
  const CashierApp({super.key, required this.db});

  @override
  State<CashierApp> createState() => _CashierAppState();
}

class _CashierAppState extends State<CashierApp> {
  late final AuthCubit _authCubit;
  late final GoRouterWrapper _routerWrapper;

  @override
  void initState() {
    super.initState();
    _authCubit = AuthCubit(widget.db.usersDao);
    _routerWrapper = GoRouterWrapper(_authCubit);
  }

  @override
  void dispose() {
    _authCubit.close();
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
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _authCubit),
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
        child: BlocBuilder<AuthCubit, AuthState>(
          bloc: _authCubit,
          builder: (ctx, authState) {
            final user = authState is AuthAuthenticated ? authState.user : null;
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
