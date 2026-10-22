import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_hotel/core/network/api_client.dart';
import 'package:smart_hotel/core/storage/token_storage.dart';
import 'package:smart_hotel/core/theme/app_theme.dart';
import 'package:smart_hotel/data/api/ac_api.dart';
import 'package:smart_hotel/data/api/auth_api.dart';
import 'package:smart_hotel/data/api/curtain_api.dart';
import 'package:smart_hotel/data/api/light_api.dart';
import 'package:smart_hotel/data/api/room_api.dart';
import 'package:smart_hotel/data/api/service_api.dart';
import 'package:smart_hotel/state/room_store.dart';
import 'package:smart_hotel/state/session_store.dart';
import 'package:smart_hotel/ui/pages/login_page.dart';
import 'package:smart_hotel/ui/pages/main_shell.dart';
import 'package:smart_hotel/ui/widgets/app_toast.dart';

/// 生成对比图：flutter test test/preview_test.dart --update-goldens
/// 产物在 test/goldens/，用来和 7.高清预览图 逐张比对
void main() {
  setUpAll(() async {
    // 真实中文字体 + Material 图标字体，避免 golden 里出现方块
    await _loadFont('SimHei', r'C:\Windows\Fonts\simhei.ttf');
    await _loadFont(
      'MaterialIcons',
      r'D:\tools\flutter\bin\cache\artifacts\material_fonts\MaterialIcons-Regular.otf',
    );
  });

  testWidgets('login', (WidgetTester tester) async {
    _size(tester);
    await tester.pumpWidget(await _app(const LoginPage()));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('../test/goldens/login.png'));
  });

  testWidgets('shell', (WidgetTester tester) async {
    _size(tester);
    final RoomStore store = _store();
    await tester.pumpWidget(
      await _appWithStore(const MainShell(), store),
    );
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('../test/goldens/home.png'));

    await tester.tap(find.byIcon(Icons.lightbulb));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('../test/goldens/light.png'));

    await tester.tap(find.byIcon(Icons.blinds));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('../test/goldens/curtain.png'));

    await tester.tap(find.byIcon(Icons.grid_view));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('../test/goldens/service.png'));
  });
}

Future<void> _loadFont(String family, String path) async {
  final File file = File(path);
  if (!file.existsSync()) {
    return;
  }
  final Uint8List bytes = file.readAsBytesSync();
  final FontLoader loader = FontLoader(family)
    ..addFont(Future<ByteData>.value(ByteData.view(bytes.buffer)));
  await loader.load();
}

void _size(WidgetTester tester) {
  tester.view.physicalSize = const Size(880, 1904);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

ThemeData _theme() {
  final ThemeData base = buildAppTheme();
  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: 'SimHei'),
    primaryTextTheme: base.primaryTextTheme.apply(fontFamily: 'SimHei'),
  );
}

Future<SessionStore> _session() async {
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final TokenStorage storage = await TokenStorage.create();
  return SessionStore(storage)..restore();
}

Future<Widget> _app(Widget home) async {
  final SessionStore session = await _session();
  final ApiClient client = ApiClient(
    client:
        MockClient((http.Request request) async => _json(<String, dynamic>{})),
  );
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SessionStore>.value(value: session),
      Provider<AuthApi>.value(value: AuthApi(client)),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _theme(),
      scaffoldMessengerKey: AppToast.messengerKey,
      home: home,
    ),
  );
}

RoomStore _store() {
  final MockClient mock = MockClient((http.Request request) async {
    return _json(
      _snapshot(
        acOn: true,
        activeSceneId: 'bright',
        lightsOn: <String>['bath', 'floor', 'corridor'],
        cloth: 'closed',
        sheer: 'closed',
        dnd: true,
        cleaning: true,
      ),
    );
  });
  final ApiClient client = ApiClient(client: mock, tokenProvider: () => 'tk');
  return RoomStore(
    roomApi: RoomApi(client),
    acApi: AcApi(client),
    lightApi: LightApi(client),
    curtainApi: CurtainApi(client),
    serviceApi: ServiceApi(client),
    onMessage: (String message) {},
  );
}

Future<Widget> _appWithStore(Widget home, RoomStore store) async {
  final SessionStore session = await _session();
  await store.refresh();
  final ApiClient client = ApiClient(
    client:
        MockClient((http.Request request) async => _json(<String, dynamic>{})),
  );
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SessionStore>.value(value: session),
      ChangeNotifierProvider<RoomStore>.value(value: store),
      Provider<AuthApi>.value(value: AuthApi(client)),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _theme(),
      scaffoldMessengerKey: AppToast.messengerKey,
      home: home,
    ),
  );
}

http.Response _json(Map<String, dynamic> data) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(
        <String, dynamic>{'code': 0, 'msg': 'success', 'data': data})),
    200,
    headers: <String, String>{
      'content-type': 'application/json; charset=utf-8'
    },
  );
}

Map<String, dynamic> _snapshot({
  required bool acOn,
  required String? activeSceneId,
  required List<String> lightsOn,
  required String cloth,
  required String sheer,
  required bool dnd,
  required bool cleaning,
}) {
  const List<Map<String, String>> lights = <Map<String, String>>[
    <String, String>{'id': 'bath', 'name': '洗漱间', 'icon': 'bath'},
    <String, String>{'id': 'wardrobe', 'name': '衣柜灯', 'icon': 'wardrobe'},
    <String, String>{'id': 'floor', 'name': '落地灯', 'icon': 'floor'},
    <String, String>{'id': 'bar', 'name': '吧灯', 'icon': 'bar'},
    <String, String>{'id': 'readLeft', 'name': '左阅读灯', 'icon': 'readLeft'},
    <String, String>{'id': 'readRight', 'name': '右阅读灯', 'icon': 'readRight'},
    <String, String>{'id': 'desk', 'name': '书桌灯', 'icon': 'desk'},
    <String, String>{'id': 'fan', 'name': '排风扇', 'icon': 'fan'},
    <String, String>{'id': 'corridor', 'name': '廊灯', 'icon': 'corridor'},
  ];

  return <String, dynamic>{
    'room': <String, dynamic>{
      'roomNo': '1209',
      'guestName': '乔安',
      'checkInDate': '2026-05-26',
    },
    'ac': <String, dynamic>{
      'on': acOn,
      'targetTemp': 20,
      'currentTemp': 22,
      'minTemp': 16,
      'maxTemp': 30,
    },
    'scenes': <Map<String, dynamic>>[
      <String, dynamic>{'id': 'bright', 'name': '明亮模式', 'icon': 'sun'},
      <String, dynamic>{'id': 'soft', 'name': '柔和模式', 'icon': 'moon'},
      <String, dynamic>{'id': 'reading', 'name': '阅读模式', 'icon': 'book'},
      <String, dynamic>{'id': 'cozy', 'name': '温馨模式', 'icon': 'heart'},
      <String, dynamic>{'id': 'sleep', 'name': '睡眠模式', 'icon': 'crescent'},
    ],
    'activeSceneId': activeSceneId,
    'masterLight': lightsOn.isNotEmpty,
    'lights': lights
        .map((Map<String, String> l) => <String, dynamic>{
              'id': l['id'],
              'name': l['name'],
              'icon': l['icon'],
              'on': lightsOn.contains(l['id']),
            })
        .toList(),
    'curtains': <Map<String, dynamic>>[
      <String, dynamic>{'id': 'cloth', 'name': '布帘', 'status': cloth},
      <String, dynamic>{'id': 'sheer', 'name': '窗纱', 'status': sheer},
    ],
    'services': <String, dynamic>{'doNotDisturb': dnd, 'cleaning': cleaning},
  };
}
