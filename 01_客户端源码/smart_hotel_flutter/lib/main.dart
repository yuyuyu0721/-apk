import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/storage/token_storage.dart';
import 'core/network/api_client.dart';
import 'data/api/ac_api.dart';
import 'data/api/auth_api.dart';
import 'data/api/curtain_api.dart';
import 'data/api/light_api.dart';
import 'data/api/room_api.dart';
import 'data/api/service_api.dart';
import 'local_server/hotel_server.dart';
import 'state/room_store.dart';
import 'state/session_store.dart';
import 'ui/widgets/app_toast.dart';
import 'app.dart';

/// 应用入口
///
/// 启动顺序（顺序敏感）：
///   1. 内置后端起来并确定端口（embedded 模式）—— 否则 baseUrl 没有端口可用
///   2. SharedPreferences 就绪（否则读不到 Token）
///   3. 恢复会话 —— 决定 initialRoute 是登录页还是主框架
///   4. 装配依赖（ApiClient 注入 Token/401 回调）→ runApp
///
/// 依赖在这里集中装配，页面里只用 Provider 取，不出现 new XxxApi()。
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 设计图为深色照片背景，状态栏用白色图标
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // 内置后端：与 App 同进程，只监听 127.0.0.1，随 App 起停
  if (AppConfig.serverMode == ServerMode.embedded) {
    try {
      await HotelServer.instance.start();
      AppConfig.bindPort(HotelServer.instance.port);
      debugPrint('[app] 内置后端已就绪：${AppConfig.baseUrl}');
    } catch (error) {
      // 起不来不阻塞启动，登录时会以"无法连接后端服务"提示出来
      debugPrint('[app] 内置后端启动失败：$error');
    }
  }

  final TokenStorage storage = await TokenStorage.create();
  final SessionStore session = SessionStore(storage)..restore();

  final ApiClient client = ApiClient(
    tokenProvider: () => session.token,
    onUnauthorized: () {
      session.clearSession();
      AppRouter.toLogin();
    },
  );

  final RoomStore roomStore = RoomStore(
    roomApi: RoomApi(client),
    acApi: AcApi(client),
    lightApi: LightApi(client),
    curtainApi: CurtainApi(client),
    serviceApi: ServiceApi(client),
    onMessage: AppToast.show,
  );

  runApp(
    SmartHotelApp(
      session: session,
      roomStore: roomStore,
      authApi: AuthApi(client),
    ),
  );
}
