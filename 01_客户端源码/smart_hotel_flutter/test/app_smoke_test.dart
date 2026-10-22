import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_hotel/app.dart';
import 'package:smart_hotel/core/network/api_client.dart';
import 'package:smart_hotel/core/storage/token_storage.dart';
import 'package:smart_hotel/data/api/ac_api.dart';
import 'package:smart_hotel/data/api/auth_api.dart';
import 'package:smart_hotel/data/api/curtain_api.dart';
import 'package:smart_hotel/data/api/light_api.dart';
import 'package:smart_hotel/data/api/room_api.dart';
import 'package:smart_hotel/data/api/service_api.dart';
import 'package:smart_hotel/state/room_store.dart';
import 'package:smart_hotel/state/session_store.dart';
import 'package:smart_hotel/ui/widgets/app_icons.dart';

import 'support/fixtures.dart';

/// 端到端冒烟：真实装配（Provider + 路由 + Store + 网络层），只把 HTTP 换成 MockClient
///
/// 覆盖：登录页渲染 → 提交登录 → 跳主框架 → 拉快照 → 切换四个页签。
void main() {
  testWidgets('登录后进入主框架并可切换四个页签', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final TokenStorage storage = await TokenStorage.create();
    final SessionStore session = SessionStore(storage)..restore();

    final MockClient mock = MockClient((http.Request request) async {
      switch (request.url.path) {
        case '/api/auth/login':
          return okResponse(loginJson(), msg: '登录成功');
        case '/api/room/snapshot':
          return okResponse(snapshotJson());
        default:
          return okResponse(<String, dynamic>{});
      }
    });

    final ApiClient client =
        ApiClient(client: mock, tokenProvider: () => session.token);
    final RoomStore roomStore = RoomStore(
      roomApi: RoomApi(client),
      acApi: AcApi(client),
      lightApi: LightApi(client),
      curtainApi: CurtainApi(client),
      serviceApi: ServiceApi(client),
      onMessage: (String message) {},
    );

    await tester.pumpWidget(
      SmartHotelApp(
        session: session,
        roomStore: roomStore,
        authApi: AuthApi(client),
      ),
    );
    await tester.pumpAndSettle();

    // 登录页
    expect(find.text('深圳技能竞赛'), findsOneWidget);
    expect(find.text('立即入住'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), '1209');
    await tester.enterText(find.byType(TextField).at(1), '乔安');
    await tester.tap(find.text('立即入住'));
    await tester.pumpAndSettle();

    // 主框架：快照已加载，问候语使用服务端返回的客人姓名
    expect(find.textContaining('欢迎回家'), findsOneWidget);
    expect(find.text('房号 1209'), findsOneWidget);
    expect(roomStore.hasData, isTrue);

    // 登录成功的 SnackBar 会浮在底部导航上方 2 秒，先等它自动消失再点页签
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // 四个页签轮转
    await tester.tap(find.byType(DomeLightIcon));
    await tester.pumpAndSettle();
    expect(find.text('灯光控制'), findsOneWidget);
    expect(find.text('洗漱间'), findsOneWidget);

    await tester.tap(find.byType(BlindsIcon));
    await tester.pumpAndSettle();
    expect(find.text('窗帘控制'), findsOneWidget);
    expect(find.text('布帘'), findsOneWidget);

    await tester.tap(find.byType(ServiceGridIcon));
    await tester.pumpAndSettle();
    expect(find.text('服务控制'), findsOneWidget);
    expect(find.text('SOS'), findsOneWidget);
  });
}
