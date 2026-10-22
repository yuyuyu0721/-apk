import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/api/auth_api.dart';
import 'state/room_store.dart';
import 'state/session_store.dart';
import 'ui/widgets/app_toast.dart';

/// 应用根组件
///
/// 依赖全部由 main 装配后注入（可测：widget 测试可以塞入 mock 过的 Store）。
class SmartHotelApp extends StatelessWidget {
  const SmartHotelApp({
    super.key,
    required this.session,
    required this.roomStore,
    required this.authApi,
  });

  final SessionStore session;
  final RoomStore roomStore;
  final AuthApi authApi;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SessionStore>.value(value: session),
        ChangeNotifierProvider<RoomStore>.value(value: roomStore),
        Provider<AuthApi>.value(value: authApi),
      ],
      child: MaterialApp(
        title: '智慧客房',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        navigatorKey: AppRouter.navigatorKey,
        scaffoldMessengerKey: AppToast.messengerKey,
        initialRoute: session.isLoggedIn ? AppRoutes.main : AppRoutes.login,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
