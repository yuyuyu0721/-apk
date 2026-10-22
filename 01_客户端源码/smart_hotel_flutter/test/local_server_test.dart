import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:smart_hotel/core/config/app_config.dart';
import 'package:smart_hotel/core/constants/app_constants.dart';
import 'package:smart_hotel/core/network/api_client.dart';
import 'package:smart_hotel/data/api/ac_api.dart';
import 'package:smart_hotel/data/api/auth_api.dart';
import 'package:smart_hotel/data/api/curtain_api.dart';
import 'package:smart_hotel/data/api/light_api.dart';
import 'package:smart_hotel/data/api/room_api.dart';
import 'package:smart_hotel/data/api/service_api.dart';
import 'package:smart_hotel/data/models/room_models.dart';
import 'package:smart_hotel/local_server/hotel_server.dart';
import 'package:smart_hotel/local_server/hotel_state.dart';
import 'package:smart_hotel/local_server/jwt_hs256.dart';
import 'package:smart_hotel/state/room_store.dart';

/// 内嵌后端契约测试：真起一个 HttpServer，用真的 http 客户端打进去
///
/// 覆盖 13 个接口 + 鉴权 + 错误码 + 业务联动，等价于把 Node 版的
/// 行为逐条搬过来验证一遍。
void main() {
  final HotelServer server = HotelServer.instance;
  late String base;

  setUpAll(() async {
    await server.start(ports: <int>[0]); // 0 = 让系统分配空闲端口
    base = 'http://127.0.0.1:${server.port}';
  });

  tearDownAll(() async {
    await server.stop();
  });

  setUp(() {
    server.state.reset();
  });

  Future<Map<String, dynamic>> call(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final Map<String, String> headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    final Uri uri = Uri.parse('$base$path');
    final http.Response response = method == 'GET'
        ? await http.get(uri, headers: headers)
        : await http.post(uri,
            headers: headers, body: jsonEncode(body ?? <String, dynamic>{}));
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  Future<String> login() async {
    final Map<String, dynamic> body =
        await call('POST', '/api/auth/login', body: <String, dynamic>{
      'roomNo': '1209',
      'guestName': '乔安',
    });
    return (body['data'] as Map<String, dynamic>)['token'] as String;
  }

  group('鉴权', () {
    test('ping 免鉴权，返回服务端时间', () async {
      final Map<String, dynamic> body = await call('GET', '/api/ping');
      expect(body['code'], 0);
      expect(body['msg'], 'pong');
      expect((body['data'] as Map<String, dynamic>)['time'], isA<String>());
    });

    test('登录成功返回 token 与 userInfo', () async {
      final Map<String, dynamic> body =
          await call('POST', '/api/auth/login', body: <String, dynamic>{
        'roomNo': '1209',
        'guestName': '乔安',
      });
      expect(body['code'], 0);
      final Map<String, dynamic> data = body['data'] as Map<String, dynamic>;
      expect(data['token'], isA<String>());
      expect((data['userInfo'] as Map<String, dynamic>)['guestName'], '乔安');
    });

    test('账号不匹配返回 1002', () async {
      final Map<String, dynamic> body =
          await call('POST', '/api/auth/login', body: <String, dynamic>{
        'roomNo': '1209',
        'guestName': '张三',
      });
      expect(body['code'], 1002);
      expect(body['msg'], '房间号或客人姓名错误');
    });

    test('缺 Token 返回 1101', () async {
      final Map<String, dynamic> body = await call('GET', '/api/room/snapshot');
      expect(body['code'], 1101);
    });

    test('非法 Token 返回 1101，过期 Token 返回 1102', () async {
      final Map<String, dynamic> bad =
          await call('GET', '/api/room/snapshot', token: 'not-a-token');
      expect(bad['code'], 1101);

      final int expiredAt =
          DateTime.now().millisecondsSinceEpoch ~/ 1000 - 60; // 1 分钟前过期
      final String expired = JwtHs256.sign(
        payload: <String, dynamic>{'roomNo': '1209', 'exp': expiredAt},
        secret: HotelState.jwtSecret,
      );
      final Map<String, dynamic> body =
          await call('GET', '/api/room/snapshot', token: expired);
      expect(body['code'], 1102);
      expect(body['msg'], contains('过期'));
    });
  });

  group('快照与空调', () {
    test('快照结构：9 灯 / 2 帘 / 5 公开场景', () async {
      final String token = await login();
      final Map<String, dynamic> body =
          await call('GET', '/api/room/snapshot', token: token);
      expect(body['code'], 0);

      final Map<String, dynamic> data = body['data'] as Map<String, dynamic>;
      expect((data['lights'] as List<dynamic>).length, 9);
      expect((data['curtains'] as List<dynamic>).length, 2);
      expect((data['scenes'] as List<dynamic>).length, 5);
      expect(data['activeSceneId'], isNull);
      expect(data['masterLight'], false);
      expect((data['ac'] as Map<String, dynamic>)['targetTemp'], 20);
      expect((data['ac'] as Map<String, dynamic>)['currentTemp'], 22);
    });

    test('开关机返回完整 AcState', () async {
      final String token = await login();
      final Map<String, dynamic> body = await call(
        'POST',
        '/api/ac/power',
        body: <String, dynamic>{'on': true},
        token: token,
      );
      expect(body['code'], 0);
      expect(body['msg'], '已开机');
      expect((body['data'] as Map<String, dynamic>)['on'], true);
    });

    test('温度越界返回 1001，非整数返回 1001', () async {
      final String token = await login();
      final Map<String, dynamic> tooHigh = await call(
        'POST',
        '/api/ac/temperature',
        body: <String, dynamic>{'targetTemp': 31},
        token: token,
      );
      expect(tooHigh['code'], 1001);
      expect(tooHigh['msg'], contains('16℃ 到 30℃'));

      final Map<String, dynamic> notInt = await call(
        'POST',
        '/api/ac/temperature',
        body: <String, dynamic>{'targetTemp': 24.5},
        token: token,
      );
      expect(notInt['code'], 1001);
      expect(notInt['msg'], 'targetTemp 必须是整数');
    });

    test('温度设置成功后回显', () async {
      final String token = await login();
      final Map<String, dynamic> body = await call(
        'POST',
        '/api/ac/temperature',
        body: <String, dynamic>{'targetTemp': 24},
        token: token,
      );
      expect(body['code'], 0);
      expect(body['msg'], '温度已设置为 24℃');
      expect((body['data'] as Map<String, dynamic>)['targetTemp'], 24);
    });
  });

  group('灯光', () {
    test('阅读模式只点亮指定的 3 盏灯', () async {
      final String token = await login();
      final Map<String, dynamic> body = await call(
        'POST',
        '/api/light/scene',
        body: <String, dynamic>{'sceneId': 'reading'},
        token: token,
      );
      expect(body['code'], 0);
      expect(body['msg'], '已切换到阅读模式');

      final Map<String, dynamic> data = body['data'] as Map<String, dynamic>;
      expect(data['activeSceneId'], 'reading');
      expect(data['masterLight'], true);

      final List<dynamic> lights = data['lights'] as List<dynamic>;
      final List<String> onIds = lights
          .where((dynamic e) => (e as Map<String, dynamic>)['on'] == true)
          .map((dynamic e) => (e as Map<String, dynamic>)['id'] as String)
          .toList();
      expect(onIds..sort(), <String>['desk', 'readLeft', 'readRight']);
    });

    test('关总开关 → 全灭且 activeSceneId 变 goodnight', () async {
      final String token = await login();
      final Map<String, dynamic> body = await call(
        'POST',
        '/api/light/master',
        body: <String, dynamic>{'on': false},
        token: token,
      );
      expect(body['msg'], '已关闭所有灯光');
      final Map<String, dynamic> data = body['data'] as Map<String, dynamic>;
      expect(data['activeSceneId'], 'goodnight');
      expect(data['masterLight'], false);
    });

    test('off 只清场景高亮，不动灯具', () async {
      final String token = await login();
      await call('POST', '/api/light/scene',
          body: <String, dynamic>{'sceneId': 'soft'}, token: token);
      final Map<String, dynamic> body = await call(
        'POST',
        '/api/light/scene',
        body: <String, dynamic>{'sceneId': 'off'},
        token: token,
      );
      expect(body['msg'], '已退出场景模式');
      final Map<String, dynamic> data = body['data'] as Map<String, dynamic>;
      expect(data['activeSceneId'], isNull);
      expect(data['masterLight'], true); // 灯还亮着
    });

    test('单灯操作清空场景并重算总开关', () async {
      final String token = await login();
      final Map<String, dynamic> body = await call(
        'POST',
        '/api/light/toggle',
        body: <String, dynamic>{'id': 'desk', 'on': true},
        token: token,
      );
      expect(body['msg'], '书桌灯已开启');
      final Map<String, dynamic> data = body['data'] as Map<String, dynamic>;
      expect(data['activeSceneId'], isNull);
      expect(data['masterLight'], true);
      expect((data['light'] as Map<String, dynamic>)['on'], true);
    });

    test('未知灯具 id 返回 1001', () async {
      final String token = await login();
      final Map<String, dynamic> body = await call(
        'POST',
        '/api/light/toggle',
        body: <String, dynamic>{'id': 'nope', 'on': true},
        token: token,
      );
      expect(body['code'], 1001);
      expect(body['msg'], contains('未知的灯具'));
    });
  });

  group('窗帘与服务', () {
    test('单帘 open 后状态为 opened', () async {
      final String token = await login();
      final Map<String, dynamic> body = await call(
        'POST',
        '/api/curtain/control',
        body: <String, dynamic>{'id': 'cloth', 'action': 'open'},
        token: token,
      );
      expect(body['msg'], '布帘已打开');
      expect((body['data'] as Map<String, dynamic>)['status'], 'opened');
    });

    test('批量只接受 open / close', () async {
      final String token = await login();
      final Map<String, dynamic> pause = await call(
        'POST',
        '/api/curtain/batch',
        body: <String, dynamic>{'action': 'pause'},
        token: token,
      );
      expect(pause['code'], 1001);

      final Map<String, dynamic> close = await call(
        'POST',
        '/api/curtain/batch',
        body: <String, dynamic>{'action': 'close'},
        token: token,
      );
      expect(close['msg'], '全部窗帘已关闭');
      final List<dynamic> curtains =
          (close['data'] as Map<String, dynamic>)['curtains'] as List<dynamic>;
      expect(
          curtains.every(
              (dynamic e) => (e as Map<String, dynamic>)['status'] == 'closed'),
          true);
    });

    test('服务开关与 SOS', () async {
      final String token = await login();
      final Map<String, dynamic> toggle = await call(
        'POST',
        '/api/service/toggle',
        body: <String, dynamic>{'key': 'doNotDisturb', 'on': true},
        token: token,
      );
      expect(toggle['msg'], '已开启请勿打扰');
      expect((toggle['data'] as Map<String, dynamic>)['doNotDisturb'], true);

      final Map<String, dynamic> sos =
          await call('POST', '/api/service/sos', token: token);
      expect(sos['code'], 0);
      expect(sos.containsKey('data'), false); // 无 data 字段
    });
  });

  group('异常契约', () {
    test('未知路由返回 404 业务码 1003', () async {
      final Map<String, dynamic> body = await call('GET', '/api/nope');
      expect(body['code'], 1003);
      expect(body['msg'], contains('接口不存在'));
    });

    test('请求体不是合法 JSON 返回 1001', () async {
      final String token = await login();
      final http.Response response = await http.post(
        Uri.parse('$base/api/ac/power'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: '{oops',
      );
      final Map<String, dynamic> body =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      expect(body['code'], 1001);
      expect(body['msg'], '请求体不是合法的 JSON');
    });
  });

  group('客户端 → 内置后端（真实 HTTP 全链路）', () {
    test('登录 → 拉快照 → 开机，走的是 App 自己的 ApiClient/Store', () async {
      // 把客户端的 BaseURL 指向刚起的真实服务
      AppConfig.bindPort(server.port);

      String? token;
      final ApiClient client = ApiClient(tokenProvider: () => token);
      final List<String> messages = <String>[];
      final RoomStore store = RoomStore(
        roomApi: RoomApi(client),
        acApi: AcApi(client),
        lightApi: LightApi(client),
        curtainApi: CurtainApi(client),
        serviceApi: ServiceApi(client),
        onMessage: messages.add,
      );

      final LoginResult loginResult =
          await AuthApi(client).login(roomNo: '1209', guestName: '乔安');
      token = loginResult.token;
      expect(loginResult.userInfo.guestName, '乔安');

      await store.refresh();
      expect(store.hasData, isTrue);
      expect(store.room.roomNo, '1209');
      expect(store.lights.length, 9);

      await store.toggleAcPower();
      expect(store.ac.on, isTrue);
      expect(messages.last, '已开启空调');
    });

    test('总开关未开启时点场景被拒绝：提示"请先打开总开关"且不改状态', () async {
      AppConfig.bindPort(server.port);

      String? token;
      final ApiClient client = ApiClient(tokenProvider: () => token);
      final List<String> messages = <String>[];
      final RoomStore store = RoomStore(
        roomApi: RoomApi(client),
        acApi: AcApi(client),
        lightApi: LightApi(client),
        curtainApi: CurtainApi(client),
        serviceApi: ServiceApi(client),
        onMessage: messages.add,
      );
      token =
          (await AuthApi(client).login(roomNo: '1209', guestName: '乔安')).token;
      await store.refresh();
      expect(store.masterLight, isFalse);

      await store.applyScene(SceneIds.reading);

      expect(messages.last, '请先打开总开关');
      expect(store.activeSceneId, isNull);
      expect(store.masterLight, isFalse);
      expect(store.lights.where((LightItem l) => l.on), isEmpty);

      // 开总开关之后再点，就能正常切换（演示视频 29-32s 的顺序）
      await store.setMasterLight(true);
      expect(store.masterLight, isTrue);

      await store.applyScene(SceneIds.reading);
      expect(store.activeSceneId, SceneIds.reading);
      expect(
        store.lights.where((LightItem l) => l.on).map((LightItem l) => l.id),
        unorderedEquals(<String>['readLeft', 'readRight', 'desk']),
      );
      expect(messages.last, '已切换到阅读模式');
    });

    test('场景连点不丢动作（串行队列，且总开关已开）', () async {
      AppConfig.bindPort(server.port);

      String? token;
      final ApiClient client = ApiClient(tokenProvider: () => token);
      final RoomStore store = RoomStore(
        roomApi: RoomApi(client),
        acApi: AcApi(client),
        lightApi: LightApi(client),
        curtainApi: CurtainApi(client),
        serviceApi: ServiceApi(client),
        onMessage: (String _) {},
      );
      token =
          (await AuthApi(client).login(roomNo: '1209', guestName: '乔安')).token;
      await store.refresh();

      // 不 await，连点：开总开关 → 温馨模式 → 明亮模式
      final List<Future<void>> taps = <Future<void>>[
        store.setMasterLight(true),
        store.applyScene(SceneIds.cozy),
        store.applyScene(SceneIds.bright),
      ];
      await Future.wait(taps);

      expect(store.activeSceneId, SceneIds.bright);
      expect(store.masterLight, isTrue);
      expect(store.lights.every((LightItem l) => l.on), isTrue);
    });

    test('晚安模式不受总开关限制：关灯后场景高亮回到 goodnight', () async {
      AppConfig.bindPort(server.port);

      String? token;
      final ApiClient client = ApiClient(tokenProvider: () => token);
      final List<String> messages = <String>[];
      final RoomStore store = RoomStore(
        roomApi: RoomApi(client),
        acApi: AcApi(client),
        lightApi: LightApi(client),
        curtainApi: CurtainApi(client),
        serviceApi: ServiceApi(client),
        onMessage: messages.add,
      );
      token =
          (await AuthApi(client).login(roomNo: '1209', guestName: '乔安')).token;
      await store.refresh();

      await store.toggleGoodnight();

      expect(store.activeSceneId, SceneIds.goodnight);
      expect(store.masterLight, isFalse);
      expect(store.lights.where((LightItem l) => l.on), isEmpty);
      expect(messages.last, '已关闭所有灯光');
    });
  });
}
