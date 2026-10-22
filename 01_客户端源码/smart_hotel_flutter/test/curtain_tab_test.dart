import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:smart_hotel/core/network/api_client.dart';
import 'package:smart_hotel/core/theme/app_theme.dart';
import 'package:smart_hotel/data/api/ac_api.dart';
import 'package:smart_hotel/data/api/curtain_api.dart';
import 'package:smart_hotel/data/api/light_api.dart';
import 'package:smart_hotel/data/api/room_api.dart';
import 'package:smart_hotel/data/api/service_api.dart';
import 'package:smart_hotel/state/room_store.dart';
import 'package:smart_hotel/ui/pages/curtain_tab.dart';
import 'package:smart_hotel/ui/widgets/curtain_panel.dart';

import 'support/fixtures.dart';

void main() {
  /// 窗帘相关的假后端：batch / control 都按请求体直接落状态
  final MockClient mock = MockClient((http.Request request) async {
    final String path = request.url.path;
    if (path == '/api/room/snapshot') {
      return okResponse(snapshotJson());
    }
    if (path == '/api/curtain/batch') {
      final String action = (jsonDecode(request.body)
          as Map<String, dynamic>)['action'] as String;
      final String status = action == 'open' ? 'opened' : 'closed';
      return okResponse(<String, dynamic>{
        'curtains': <Map<String, dynamic>>[
          <String, dynamic>{'id': 'cloth', 'name': '布帘', 'status': status},
          <String, dynamic>{'id': 'sheer', 'name': '窗纱', 'status': status},
        ],
      });
    }
    if (path == '/api/curtain/control') {
      final Map<String, dynamic> body = jsonDecode(request.body)
          as Map<String, dynamic>;
      const Map<String, String> statusMap = <String, String>{
        'open': 'opened',
        'pause': 'paused',
        'close': 'closed',
      };
      return okResponse(<String, dynamic>{
        'id': body['id'],
        'name': body['id'] == 'cloth' ? '布帘' : '窗纱',
        'status': statusMap[body['action']],
      });
    }
    return okResponse(<String, dynamic>{});
  });

  Future<RoomStore> pumpTab(WidgetTester tester) async {
    final ApiClient client = ApiClient(client: mock, tokenProvider: () => 'tk');
    final RoomStore store = RoomStore(
      roomApi: RoomApi(client),
      acApi: AcApi(client),
      lightApi: LightApi(client),
      curtainApi: CurtainApi(client),
      serviceApi: ServiceApi(client),
      onMessage: (String _) {},
    );
    await store.refresh();

    await tester.pumpWidget(
      ChangeNotifierProvider<RoomStore>.value(
        value: store,
        child: const MaterialApp(
          home: Scaffold(
            backgroundColor: Color(0xFF5C6360),
            body: Center(
              child: SizedBox(
                width: 440,
                height: 900,
                child: CurtainTab(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return store;
  }

  BoxDecoration decorationOf(WidgetTester tester, Key key) {
    final AnimatedContainer container = tester.widget<AnimatedContainer>(
      find
          .descendant(
            of: find.byKey(key),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    return container.decoration as BoxDecoration;
  }

  const Key openKey = ValueKey<String>('curtain-batch-open');
  const Key closeKey = ValueKey<String>('curtain-batch-close');

  testWidgets('批量按钮跟随实际状态：全关点亮全部关闭，全开点亮全部打开', (WidgetTester tester) async {
    await pumpTab(tester);

    // 初始：全部收起 → 只有"全部关闭"点亮
    expect(decorationOf(tester, closeKey).color, D.accent);
    expect(decorationOf(tester, openKey).color, isNot(D.accent));

    // 按"全部打开"→ 全开后"全部打开"点亮，另一个灭
    await tester.tap(find.byKey(openKey));
    await tester.pumpAndSettle();
    expect(decorationOf(tester, openKey).color, D.accent);
    expect(decorationOf(tester, closeKey).color, isNot(D.accent));

    // 再按"全部关闭"→ 点亮权易主
    await tester.tap(find.byKey(closeKey));
    await tester.pumpAndSettle();
    expect(decorationOf(tester, closeKey).color, D.accent);
    expect(decorationOf(tester, openKey).color, isNot(D.accent));
  });

  testWidgets('一开一关的混合态：两个批量按钮都不点亮', (WidgetTester tester) async {
    await pumpTab(tester);

    await tester.tap(find.byKey(openKey));
    await tester.pumpAndSettle();
    expect(decorationOf(tester, openKey).color, D.accent);

    // 在第一块面板（布帘）上点"关闭"
    final Finder clothPanel = find.byType(CurtainPanel).first;
    await tester.tap(
      find.descendant(
        of: clothPanel,
        matching: find.text('关闭'),
      ),
    );
    await tester.pumpAndSettle();

    // 布帘关、窗纱开 → 既不是全开也不是全关，都不该点亮
    expect(decorationOf(tester, openKey).color, isNot(D.accent));
    expect(decorationOf(tester, closeKey).color, isNot(D.accent));
  });
}
