import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_hotel/core/constants/app_constants.dart';
import 'package:smart_hotel/core/network/api_client.dart';
import 'package:smart_hotel/data/api/ac_api.dart';
import 'package:smart_hotel/data/api/curtain_api.dart';
import 'package:smart_hotel/data/api/light_api.dart';
import 'package:smart_hotel/data/api/room_api.dart';
import 'package:smart_hotel/data/api/service_api.dart';
import 'package:smart_hotel/data/models/room_models.dart';
import 'package:smart_hotel/state/room_store.dart';

import 'support/fixtures.dart';

void main() {
  late List<String> messages;
  late List<String> requestLog;

  RoomStore buildStore(MockClient mock) {
    final ApiClient client = ApiClient(client: mock, tokenProvider: () => 'tk');
    return RoomStore(
      roomApi: RoomApi(client),
      acApi: AcApi(client),
      lightApi: LightApi(client),
      curtainApi: CurtainApi(client),
      serviceApi: ServiceApi(client),
      onMessage: messages.add,
    );
  }

  setUp(() {
    messages = <String>[];
    requestLog = <String>[];
  });

  test('refresh 填充整房快照', () async {
    final MockClient mock = MockClient((http.Request request) async {
      requestLog.add(request.url.path);
      return okResponse(snapshotJson());
    });
    final RoomStore store = buildStore(mock);

    await store.refresh();

    expect(store.hasData, isTrue);
    expect(store.room.roomNo, '1209');
    expect(store.lights.length, 9);
    expect(store.curtains.length, 2);
    expect(store.scenes.length, 5);
    expect(requestLog, contains('/api/room/snapshot'));
  });

  test('开机：请求体带 on=true，并用返回值刷新空调状态', () async {
    String? body;
    final MockClient mock = MockClient((http.Request request) async {
      if (request.url.path == '/api/room/snapshot') {
        return okResponse(snapshotJson());
      }
      body = request.body;
      return okResponse(<String, dynamic>{
        'on': true,
        'targetTemp': 20,
        'currentTemp': 22,
        'minTemp': 16,
        'maxTemp': 30,
      });
    });
    final RoomStore store = buildStore(mock);
    await store.refresh();

    await store.toggleAcPower();

    expect(jsonDecode(body!)['on'], isTrue);
    expect(store.ac.on, isTrue);
    expect(messages.last, '已开启空调');
  });

  test('切换场景：activeSceneId 与灯光列表一起刷新', () async {
    final MockClient mock = MockClient((http.Request request) async {
      if (request.url.path == '/api/room/snapshot') {
        return okResponse(snapshotJson(masterLight: true));
      }
      return okResponse(<String, dynamic>{
        'activeSceneId': 'reading',
        'masterLight': true,
        'lights': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'bath',
            'name': '洗漱间',
            'icon': 'bath',
            'on': false
          },
          <String, dynamic>{
            'id': 'wardrobe',
            'name': '衣柜灯',
            'icon': 'wardrobe',
            'on': false
          },
          <String, dynamic>{
            'id': 'floor',
            'name': '落地灯',
            'icon': 'floor',
            'on': false
          },
          <String, dynamic>{
            'id': 'bar',
            'name': '吧灯',
            'icon': 'bar',
            'on': false
          },
          <String, dynamic>{
            'id': 'readLeft',
            'name': '左阅读灯',
            'icon': 'readLeft',
            'on': true
          },
          <String, dynamic>{
            'id': 'readRight',
            'name': '右阅读灯',
            'icon': 'readRight',
            'on': true
          },
          <String, dynamic>{
            'id': 'desk',
            'name': '书桌灯',
            'icon': 'desk',
            'on': true
          },
          <String, dynamic>{
            'id': 'fan',
            'name': '排风扇',
            'icon': 'fan',
            'on': false
          },
          <String, dynamic>{
            'id': 'corridor',
            'name': '廊灯',
            'icon': 'corridor',
            'on': false
          },
        ],
      });
    });
    final RoomStore store = buildStore(mock);
    await store.refresh();

    await store.applyScene('reading');

    expect(store.activeSceneId, 'reading');
    expect(store.isSceneActive('reading'), isTrue);
    expect(store.masterLight, isTrue);
    expect(store.lights.where((LightItem l) => l.on).length, 3);
    expect(messages.last, '已切换到阅读模式');
  });

  test('单灯操作会把 activeSceneId 清空', () async {
    final MockClient mock = MockClient((http.Request request) async {
      if (request.url.path == '/api/room/snapshot') {
        return okResponse(snapshotJson());
      }
      return okResponse(<String, dynamic>{
        'light': <String, dynamic>{
          'id': 'desk',
          'name': '书桌灯',
          'icon': 'desk',
          'on': true
        },
        'masterLight': true,
        'activeSceneId': null,
      });
    });
    final RoomStore store = buildStore(mock);
    await store.refresh();

    final LightItem light =
        store.lights.firstWhere((LightItem l) => l.id == 'desk');
    await store.toggleLight(light);

    expect(store.activeSceneId, isNull);
    expect(store.lights.firstWhere((LightItem l) => l.id == 'desk').on, isTrue);
    expect(messages.last, '书桌灯已开启');
  });

  test('总开关未开启时点场景：提示"请先打开总开关"，且不发请求', () async {
    final MockClient mock = MockClient((http.Request request) async {
      requestLog.add(request.url.path);
      if (request.url.path == '/api/room/snapshot') {
        return okResponse(snapshotJson());
      }
      return okResponse(<String, dynamic>{});
    });
    final RoomStore store = buildStore(mock);
    await store.refresh();
    requestLog.clear();

    await store.applyScene(SceneIds.reading);

    expect(messages.last, '请先打开总开关');
    expect(store.activeSceneId, isNull);
    expect(store.lights.where((LightItem l) => l.on), isEmpty);
    expect(requestLog, isEmpty, reason: '被拦下的场景不应该打接口');
  });

  test('晚安模式 / off 不受总开关限制', () async {
    final MockClient mock = MockClient((http.Request request) async {
      requestLog.add(request.url.path);
      if (request.url.path == '/api/room/snapshot') {
        return okResponse(snapshotJson());
      }
      return okResponse(<String, dynamic>{
        'activeSceneId': SceneIds.goodnight,
        'masterLight': false,
        'lights': <Map<String, dynamic>>[],
      });
    });
    final RoomStore store = buildStore(mock);
    await store.refresh();
    requestLog.clear();

    await store.applyScene(SceneIds.goodnight);

    expect(requestLog, <String>['/api/light/scene']);
    expect(store.activeSceneId, SceneIds.goodnight);
  });

  test('服务端业务错误转成提示，不抛到 UI', () async {
    final MockClient mock = MockClient(
      (http.Request request) async => http.Response.bytes(
        utf8.encode(
            jsonEncode(<String, dynamic>{'code': 5000, 'msg': '服务器内部错误'})),
        500,
        headers: <String, String>{
          'content-type': 'application/json; charset=utf-8'
        },
      ),
    );
    final RoomStore store = buildStore(mock);

    await store.refresh();

    expect(store.hasData, isFalse);
    expect(messages.last, '服务器内部错误');
  });

  test('上一个请求未返回时点击场景不会被丢弃（串行队列回归）', () async {
    // 关键回归点：旧实现用布尔锁 + 提前 return，
    // "开总开关"还在飞行时点场景会被静默吞掉。
    final MockClient mock = MockClient((http.Request request) async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      if (request.url.path == '/api/room/snapshot') {
        return okResponse(snapshotJson(acOn: true));
      }
      if (request.url.path == '/api/light/master') {
        final List<dynamic> lights = (snapshotJson()['lights'] as List<dynamic>)
            .map((dynamic e) => (e as Map<String, dynamic>)..['on'] = true)
            .toList();
        return okResponse(<String, dynamic>{
          'activeSceneId': SceneIds.bright,
          'masterLight': true,
          'lights': lights,
        });
      }
      if (request.url.path == '/api/light/scene') {
        final List<dynamic> lights = (snapshotJson()['lights'] as List<dynamic>)
            .map((dynamic e) => (e as Map<String, dynamic>)
              ..['on'] = <String>['floor', 'bar'].contains(e['id']))
            .toList();
        return okResponse(<String, dynamic>{
          'activeSceneId': 'cozy',
          'masterLight': true,
          'lights': lights,
        });
      }
      return okResponse(<String, dynamic>{});
    });

    final RoomStore store = buildStore(mock);
    await store.refresh();

    // 不 await 第一个，紧接着发第二个——模拟"手快"：
    // 开总开关还在飞行时就点场景，队列保证两个动作都执行且顺序正确
    final Future<void> first = store.setMasterLight(true);
    final Future<void> second = store.applyScene(SceneIds.cozy);
    await Future.wait(<Future<void>>[first, second]);

    expect(store.activeSceneId, SceneIds.cozy);
    expect(store.masterLight, isTrue);
    expect(store.lights.where((LightItem l) => l.on).length, 2);
  });
}
