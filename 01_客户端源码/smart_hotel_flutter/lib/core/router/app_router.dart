import 'package:flutter/material.dart';

import '../../ui/pages/login_page.dart';
import '../../ui/pages/main_shell.dart';
import '../constants/app_constants.dart';

/// 全局路由表
///
/// 只有两个顶层路由：登录 / 主框架。
/// 主框架内部的四个页签由 MainShell 自己管理（IndexedStack），不占路由栈——
/// 这样"退出登录/401"统一用 pushNamedAndRemoveUntil 回登录页，栈不会越堆越深。
class AppRouter {
  const AppRouter._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.main:
        return MaterialPageRoute<void>(
          builder: (_) => const MainShell(),
          settings: settings,
        );
      case AppRoutes.login:
      default:
        return MaterialPageRoute<void>(
          builder: (_) => const LoginPage(),
          settings: settings,
        );
    }
  }

  static void toMain() {
    navigatorKey.currentState
        ?.pushNamedAndRemoveUntil(AppRoutes.main, (Route<dynamic> _) => false);
  }

  static void toLogin() {
    navigatorKey.currentState
        ?.pushNamedAndRemoveUntil(AppRoutes.login, (Route<dynamic> _) => false);
  }
}
