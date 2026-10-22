import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_hotel/core/network/api_client.dart';
import 'package:smart_hotel/core/storage/token_storage.dart';
import 'package:smart_hotel/core/theme/app_theme.dart';
import 'package:smart_hotel/data/api/auth_api.dart';
import 'package:smart_hotel/state/session_store.dart';
import 'package:smart_hotel/ui/pages/login_page.dart';
import 'package:smart_hotel/ui/widgets/app_toast.dart';

Widget _wrap(SessionStore session, AuthApi authApi) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SessionStore>.value(value: session),
      Provider<AuthApi>.value(value: authApi),
    ],
    child: MaterialApp(
      theme: buildAppTheme(),
      scaffoldMessengerKey: AppToast.messengerKey,
      home: const LoginPage(),
    ),
  );
}

void main() {
  testWidgets('房间号为空时本地拦截，不发请求', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final TokenStorage storage = await TokenStorage.create();
    final SessionStore session = SessionStore(storage)..restore();

    bool requested = false;
    final MockClient mock = MockClient((http.Request request) async {
      requested = true;
      return http.Response('{}', 200);
    });

    await tester.pumpWidget(_wrap(session, AuthApi(ApiClient(client: mock))));

    await tester.enterText(find.byType(TextField).first, '');
    await tester.tap(find.text('立即入住'));
    await tester.pump();

    expect(find.text('请输入房间号'), findsOneWidget);
    expect(requested, isFalse);
  });

  testWidgets('后端返回 1002 时展示服务端错误文案', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final TokenStorage storage = await TokenStorage.create();
    final SessionStore session = SessionStore(storage)..restore();

    final MockClient mock = MockClient((http.Request request) async {
      return http.Response.bytes(
        utf8.encode(jsonEncode(<String, dynamic>{
          'code': 1002,
          'msg': '房间号或客人姓名错误',
        })),
        200,
        headers: <String, String>{
          'content-type': 'application/json; charset=utf-8'
        },
      );
    });

    await tester.pumpWidget(_wrap(session, AuthApi(ApiClient(client: mock))));

    await tester.enterText(find.byType(TextField).at(0), '1209');
    await tester.enterText(find.byType(TextField).at(1), '不存在');
    await tester.tap(find.text('立即入住'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('房间号或客人姓名错误'), findsWidgets);
  });
}
