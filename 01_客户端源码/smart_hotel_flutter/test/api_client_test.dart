import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_hotel/core/config/app_config.dart';
import 'package:smart_hotel/core/network/api_client.dart';
import 'package:smart_hotel/core/network/api_exception.dart';

http.Response jsonResponse(Object body, int status) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: <String, String>{
      'content-type': 'application/json; charset=utf-8'
    },
  );
}

void main() {
  group('ApiClient', () {
    test('业务码为 0 时解包 data', () async {
      final MockClient mock = MockClient((http.Request request) async {
        // 与 AppConfig 保持一致：内置/远程模式切换后这里不用改
        expect(request.url.toString(), '${AppConfig.baseUrl}/api/ping');
        return jsonResponse(<String, dynamic>{
          'code': 0,
          'msg': 'pong',
          'data': <String, dynamic>{'time': '2026-06-02T08:30:15.123Z'},
        }, 200);
      });
      final ApiClient api = ApiClient(client: mock);
      final Map<String, dynamic> data = await api.getJson('/api/ping');
      expect(data['time'], '2026-06-02T08:30:15.123Z');
    });

    test('鉴权接口自动注入 Bearer Token', () async {
      String? authHeader;
      final MockClient mock = MockClient((http.Request request) async {
        authHeader = request.headers['Authorization'];
        return jsonResponse(<String, dynamic>{
          'code': 0,
          'msg': 'ok',
          'data': <String, dynamic>{}
        }, 200);
      });
      final ApiClient api =
          ApiClient(client: mock, tokenProvider: () => 'tk-123');
      await api.getJson('/api/room/snapshot');
      expect(authHeader, 'Bearer tk-123');
    });

    test('免鉴权接口不带 Authorization', () async {
      String? authHeader = 'unset';
      final MockClient mock = MockClient((http.Request request) async {
        authHeader = request.headers['Authorization'];
        return jsonResponse(<String, dynamic>{
          'code': 0,
          'msg': 'ok',
          'data': <String, dynamic>{}
        }, 200);
      });
      final ApiClient api =
          ApiClient(client: mock, tokenProvider: () => 'tk-123');
      await api.getJson('/api/ping', auth: false);
      expect(authHeader, isNull);
    });

    test('业务码非 0 抛 ApiException，保留 code 与 msg', () async {
      final MockClient mock = MockClient(
        (http.Request request) async => jsonResponse(
            <String, dynamic>{'code': 1002, 'msg': '房间号或客人姓名错误'}, 200),
      );
      final ApiClient api = ApiClient(client: mock);

      await expectLater(
        api.postJson('/api/auth/login',
            <String, dynamic>{'roomNo': '1', 'guestName': 'x'}),
        throwsA(
          isA<ApiException>()
              .having((ApiException e) => e.code, 'code', 1002)
              .having((ApiException e) => e.message, 'message', '房间号或客人姓名错误'),
        ),
      );
    });

    test('401 触发 onUnauthorized 回调并抛异常', () async {
      bool unauthorized = false;
      final MockClient mock = MockClient(
        (http.Request request) async => jsonResponse(
            <String, dynamic>{'code': 1102, 'msg': 'Token 已过期'}, 401),
      );
      final ApiClient api = ApiClient(
        client: mock,
        onUnauthorized: () => unauthorized = true,
      );

      await expectLater(
        api.getJson('/api/room/snapshot'),
        throwsA(isA<ApiException>()),
      );
      expect(unauthorized, isTrue);
    });

    test('无 data 字段的接口（logout）不报错', () async {
      final MockClient mock = MockClient(
        (http.Request request) async =>
            jsonResponse(<String, dynamic>{'code': 0, 'msg': '已退出登录'}, 200),
      );
      final ApiClient api = ApiClient(client: mock);
      await api.postVoid('/api/auth/logout');
    });

    test('响应不是 JSON 时抛解析异常', () async {
      final MockClient mock = MockClient(
        (http.Request request) async =>
            http.Response.bytes(utf8.encode('oops'), 200),
      );
      final ApiClient api = ApiClient(client: mock);
      await expectLater(
        api.getJson('/api/ping'),
        throwsA(
            isA<ApiException>().having((ApiException e) => e.code, 'code', -2)),
      );
    });
  });
}
