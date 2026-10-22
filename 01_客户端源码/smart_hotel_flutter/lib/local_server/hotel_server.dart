import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'hotel_state.dart';
import 'jwt_hs256.dart';

/// 内嵌后端：把 smart_hotel_server 的 13 个 REST 接口用 Dart 复刻，
/// 在 App 自己的进程里监听 127.0.0.1，随 App 启停。
///
/// 为什么不是把 Node 打包进来：
///   - 塞 Node 运行时（nodejs-mobile）要多背 40MB+ 原生库，且维护停滞；
///   - 后端逻辑只有 13 个接口 + 内存状态，用 Dart 重写不到 500 行，
///     接口契约、错误码、提示文案全部保持一致，客户端一行都不用改。
///
/// 用途：比赛/演示现场没有电脑跑 Node 时，App 自带后端即可完整演示。
class HotelServer {
  HotelServer._();

  static final HotelServer instance = HotelServer._();

  /// 端口候选：3000 被占用时顺延
  static const List<int> candidatePorts = <int>[3000, 3001, 3100];

  HttpServer? _server;
  final HotelState state = HotelState();
  final Random _random = Random();

  /// 回环地址本身没有网络延迟，默认关闭 100-300ms 模拟；
  /// 想复现"弱网 Loading"时置 true
  bool enableDelay = false;
  bool enableLog = true;

  int get port => _server?.port ?? 0;

  bool get isRunning => _server != null;

  Future<void> start({
    List<int> ports = candidatePorts,
    String host = '127.0.0.1',
  }) async {
    if (_server != null) {
      return;
    }
    Object? lastError;
    for (final int candidate in ports) {
      try {
        _server = await HttpServer.bind(host, candidate);
        break;
      } on SocketException catch (error) {
        lastError = error;
      }
    }
    final HttpServer? server = _server;
    if (server == null) {
      throw StateError('内嵌后端启动失败（端口全部被占用）：$lastError');
    }
    state.startTempSimulator();
    server.listen(
      _onRequest,
      onError: (Object error) => _log('连接异常：$error'),
    );
    _log('内嵌后端已启动 http://$host:${server.port}');
  }

  Future<void> stop() async {
    state.stopTempSimulator();
    await _server?.close(force: true);
    _server = null;
  }

  // ==================== 请求分发 ====================

  static const Set<String> _knownRoutes = <String>{
    'GET /api/ping',
    'POST /api/auth/login',
    'POST /api/auth/logout',
    'GET /api/room/snapshot',
    'POST /api/ac/power',
    'POST /api/ac/temperature',
    'POST /api/light/master',
    'POST /api/light/scene',
    'POST /api/light/toggle',
    'POST /api/curtain/control',
    'POST /api/curtain/batch',
    'POST /api/service/toggle',
    'POST /api/service/sos',
  };

  Future<void> _onRequest(HttpRequest request) async {
    try {
      if (enableDelay) {
        await Future<void>.delayed(
          Duration(milliseconds: 100 + _random.nextInt(201)),
        );
      }
      await _dispatch(request);
    } catch (error, stack) {
      _log('未捕获异常：$error\n$stack');
      try {
        await _json(request, 500, _fail(5000, '服务器内部错误'));
      } catch (_) {
        // 响应可能已经发出，忽略
      }
    }
  }

  Future<void> _dispatch(HttpRequest request) async {
    final String method = request.method;
    final String path = request.uri.path;
    final String key = '$method $path';
    _log('→ $key');

    if (key == 'GET /api/ping') {
      return _json(
        request,
        200,
        _ok(<String, dynamic>{'time': DateTime.now().toUtc().toIso8601String()},
            'pong'),
      );
    }
    if (key == 'POST /api/auth/login') {
      return _login(request);
    }
    if (!_knownRoutes.contains(key)) {
      return _json(request, 404, _fail(1003, '接口不存在：$method $path'));
    }

    final RoomState? room = await _authorize(request);
    if (room == null) {
      return;
    }

    switch (key) {
      case 'POST /api/auth/logout':
        return _json(request, 200, _ok(null, '已退出登录'));

      case 'GET /api/room/snapshot':
        return _json(request, 200, _ok(room.snapshotJson()));

      case 'POST /api/ac/power':
        return _acPower(request, room);

      case 'POST /api/ac/temperature':
        return _acTemperature(request, room);

      case 'POST /api/light/master':
        return _lightMaster(request, room);

      case 'POST /api/light/scene':
        return _lightScene(request, room);

      case 'POST /api/light/toggle':
        return _lightToggle(request, room);

      case 'POST /api/curtain/control':
        return _curtainControl(request, room);

      case 'POST /api/curtain/batch':
        return _curtainBatch(request, room);

      case 'POST /api/service/toggle':
        return _serviceToggle(request, room);

      case 'POST /api/service/sos':
        _log('[SOS] 房间 ${room.roomNo} 触发紧急求助');
        return _json(request, 200, _ok(null, '紧急求助已发送，前台将立即与您联系'));

      default:
        return _json(request, 404, _fail(1003, '接口不存在：$method $path'));
    }
  }

  // ==================== 各接口实现 ====================

  Future<void> _login(HttpRequest request) async {
    final Map<String, dynamic>? body = await _readBody(request);
    if (body == null) {
      return _badJson(request);
    }
    final Object? roomNo = body['roomNo'];
    final Object? guestName = body['guestName'];

    if (roomNo is! String || roomNo.isEmpty) {
      return _json(request, 200, _fail(1001, '房间号必须是非空字符串'));
    }
    if (guestName is! String || guestName.isEmpty) {
      return _json(request, 200, _fail(1001, '客人姓名必须是非空字符串'));
    }
    if (!state.validateCredential(roomNo, guestName)) {
      return _json(request, 200, _fail(1002, '房间号或客人姓名错误'));
    }

    final RoomState room = state.room(roomNo)!;
    final int nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final String token = JwtHs256.sign(
      payload: <String, dynamic>{
        'roomNo': roomNo,
        'iat': nowSeconds,
        'exp': nowSeconds + HotelState.tokenTtl.inSeconds,
      },
      secret: HotelState.jwtSecret,
    );
    return _json(
      request,
      200,
      _ok(<String, dynamic>{'token': token, 'userInfo': room.roomJson()},
          '登录成功'),
    );
  }

  Future<void> _acPower(HttpRequest request, RoomState room) async {
    final Map<String, dynamic>? body = await _readBody(request);
    if (body == null) {
      return _badJson(request);
    }
    final Object? on = body['on'];
    if (on is! bool) {
      return _json(request, 200, _fail(1001, 'on 字段必须是布尔值'));
    }
    room.acOn = on;
    return _json(request, 200, _ok(room.acJson(), on ? '已开机' : '已关机'));
  }

  Future<void> _acTemperature(HttpRequest request, RoomState room) async {
    final Map<String, dynamic>? body = await _readBody(request);
    if (body == null) {
      return _badJson(request);
    }
    final Object? targetTemp = body['targetTemp'];
    final bool isIntegerValue = targetTemp is int ||
        (targetTemp is double && targetTemp == targetTemp.roundToDouble());
    if (!isIntegerValue) {
      return _json(request, 200, _fail(1001, 'targetTemp 必须是整数'));
    }
    final int value = (targetTemp as num).toInt();
    if (value < room.minTemp || value > room.maxTemp) {
      return _json(
        request,
        200,
        _fail(1001, '目标温度必须在 ${room.minTemp}℃ 到 ${room.maxTemp}℃ 之间'),
      );
    }
    room.targetTemp = value;
    return _json(request, 200, _ok(room.acJson(), '温度已设置为 $value℃'));
  }

  Future<void> _lightMaster(HttpRequest request, RoomState room) async {
    final Map<String, dynamic>? body = await _readBody(request);
    if (body == null) {
      return _badJson(request);
    }
    final Object? on = body['on'];
    if (on is! bool) {
      return _json(request, 200, _fail(1001, 'on 字段必须是布尔值'));
    }
    state.setMasterLight(room, on);
    return _json(
      request,
      200,
      _ok(<String, dynamic>{
        'activeSceneId': room.activeSceneId,
        'masterLight': room.masterLight,
        'lights': room.lightsJson(),
      }, on ? '已打开所有灯光' : '已关闭所有灯光'),
    );
  }

  Future<void> _lightScene(HttpRequest request, RoomState room) async {
    final Map<String, dynamic>? body = await _readBody(request);
    if (body == null) {
      return _badJson(request);
    }
    final Object? sceneId = body['sceneId'];
    if (sceneId is! String || !HotelState.validSceneIds.contains(sceneId)) {
      return _json(request, 200, _fail(1001, '无效的场景 ID'));
    }

    // off：只清场景高亮，不动灯具
    if (sceneId == 'off') {
      room.activeSceneId = null;
      return _json(
        request,
        200,
        _ok(<String, dynamic>{
          'activeSceneId': null,
          'masterLight': room.masterLight,
          'lights': room.lightsJson(),
        }, '已退出场景模式'),
      );
    }

    state.applyScene(room, sceneId);
    final String name = _sceneName(sceneId);
    return _json(
      request,
      200,
      _ok(<String, dynamic>{
        'activeSceneId': room.activeSceneId,
        'masterLight': room.masterLight,
        'lights': room.lightsJson(),
      }, '已切换到$name'),
    );
  }

  Future<void> _lightToggle(HttpRequest request, RoomState room) async {
    final Map<String, dynamic>? body = await _readBody(request);
    if (body == null) {
      return _badJson(request);
    }
    final Object? id = body['id'];
    final Object? on = body['on'];
    if (id is! String || id.isEmpty) {
      return _json(request, 200, _fail(1001, 'id 字段不能为空'));
    }
    if (on is! bool) {
      return _json(request, 200, _fail(1001, 'on 字段必须是布尔值'));
    }

    final Map<String, dynamic>? light = state.toggleLight(room, id, on);
    if (light == null) {
      return _json(request, 200, _fail(1001, '未知的灯具 id：$id'));
    }
    return _json(
      request,
      200,
      _ok(<String, dynamic>{
        'light': light,
        'masterLight': room.masterLight,
        'activeSceneId': room.activeSceneId,
      }, '${light['name']}已${on ? '开启' : '关闭'}'),
    );
  }

  Future<void> _curtainControl(HttpRequest request, RoomState room) async {
    final Map<String, dynamic>? body = await _readBody(request);
    if (body == null) {
      return _badJson(request);
    }
    final Object? id = body['id'];
    final Object? action = body['action'];
    if (id is! String || id.isEmpty) {
      return _json(request, 200, _fail(1001, 'id 字段不能为空'));
    }
    if (action is! String ||
        !<String>['open', 'pause', 'close'].contains(action)) {
      return _json(request, 200, _fail(1001, '无效的动作：$action'));
    }

    final Map<String, dynamic>? curtain =
        state.controlCurtain(room, id, action);
    if (curtain == null) {
      return _json(request, 200, _fail(1001, '未知的窗帘 id：$id'));
    }
    const Map<String, String> verb = <String, String>{
      'open': '已打开',
      'pause': '已暂停',
      'close': '已关闭',
    };
    return _json(
      request,
      200,
      _ok(curtain, '${curtain['name']}${verb[action]}'),
    );
  }

  Future<void> _curtainBatch(HttpRequest request, RoomState room) async {
    final Map<String, dynamic>? body = await _readBody(request);
    if (body == null) {
      return _badJson(request);
    }
    final Object? action = body['action'];
    if (action is! String || !<String>['open', 'close'].contains(action)) {
      return _json(request, 200, _fail(1001, '批量操作仅支持 open 或 close'));
    }
    state.batchCurtain(room, action);
    return _json(
      request,
      200,
      _ok(<String, dynamic>{'curtains': room.curtainsJson()},
          action == 'open' ? '全部窗帘已打开' : '全部窗帘已关闭'),
    );
  }

  Future<void> _serviceToggle(HttpRequest request, RoomState room) async {
    final Map<String, dynamic>? body = await _readBody(request);
    if (body == null) {
      return _badJson(request);
    }
    final Object? key = body['key'];
    final Object? on = body['on'];
    if (key is! String || !<String>['doNotDisturb', 'cleaning'].contains(key)) {
      return _json(request, 200, _fail(1001, '无效的服务键：$key'));
    }
    if (on is! bool) {
      return _json(request, 200, _fail(1001, 'on 字段必须是布尔值'));
    }

    if (key == 'doNotDisturb') {
      room.doNotDisturb = on;
    } else {
      room.cleaning = on;
    }
    final String name = key == 'doNotDisturb' ? '请勿打扰' : '清理房间';
    return _json(
        request, 200, _ok(room.servicesJson(), '已${on ? '开启' : '关闭'}$name'));
  }

  // ==================== 鉴权 / 工具 ====================

  Future<RoomState?> _authorize(HttpRequest request) async {
    final String header = request.headers.value('authorization') ?? '';
    if (!header.startsWith('Bearer ')) {
      await _json(request, 401, _fail(1101, 'Token 缺失或格式错误'));
      return null;
    }
    final String token = header.substring('Bearer '.length).trim();
    if (token.isEmpty) {
      await _json(request, 401, _fail(1101, 'Token 不能为空'));
      return null;
    }

    try {
      final Map<String, dynamic> payload =
          JwtHs256.verify(token, HotelState.jwtSecret);
      final Object? roomNo = payload['roomNo'];
      final RoomState? room = roomNo is String ? state.room(roomNo) : null;
      if (room == null) {
        await _json(request, 401, _fail(1101, 'Token 无效'));
        return null;
      }
      return room;
    } on JwtError catch (error) {
      if (error.expired) {
        await _json(request, 401, _fail(1102, 'Token 已过期，请重新登录'));
      } else {
        await _json(request, 401, _fail(1101, 'Token 无效'));
      }
      return null;
    }
  }

  /// 读取并解析 JSON 请求体；返回 null 表示不是合法的 JSON 对象
  Future<Map<String, dynamic>?> _readBody(HttpRequest request) async {
    final String text = await utf8.decoder.bind(request).join();
    if (text.trim().isEmpty) {
      return <String, dynamic>{};
    }
    try {
      final Object? decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } on FormatException {
      return null;
    }
  }

  Future<void> _badJson(HttpRequest request) {
    // 与 Express 的 express.json() 解析失败行为一致：HTTP 200 + 业务码 1001
    return _json(request, 200, _fail(1001, '请求体不是合法的 JSON'));
  }

  Map<String, dynamic> _ok(Object? data, [String msg = 'success']) {
    final Map<String, dynamic> body = <String, dynamic>{'code': 0, 'msg': msg};
    if (data != null) {
      body['data'] = data;
    }
    return body;
  }

  Map<String, dynamic> _fail(int code, String msg) {
    return <String, dynamic>{'code': code, 'msg': msg};
  }

  Future<void> _json(
      HttpRequest request, int status, Map<String, dynamic> body) async {
    final HttpResponse response = request.response;
    response.statusCode = status;
    response.headers.contentType =
        ContentType('application', 'json', charset: 'utf-8');
    response.write(jsonEncode(body));
    await response.close();
  }

  String _sceneName(String sceneId) {
    for (final Map<String, String> scene in HotelState.publicScenes) {
      if (scene['id'] == sceneId) {
        return scene['name']!;
      }
    }
    return '晚安模式';
  }

  void _log(String message) {
    if (enableLog) {
      debugPrint('[server] $message');
    }
  }
}
