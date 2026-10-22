import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

/// 内嵌后端的房间状态与业务规则
///
/// 这是 smart_hotel_server/src/store/rooms.js 的 Dart 等价实现：
///   - 数据全部驻留内存，App 重启即还原（与 Node 版一致）
///   - 场景预设、总开关、单灯、窗帘、服务的联动规则逐条对齐
///   - currentTemp 由定时器每秒 0.5℃ 逼近 targetTemp
class HotelState {
  HotelState() {
    reset();
  }

  // ==================== 常量（与后端 config / rooms.js 对齐）====================

  static const Duration tokenTtl = Duration(hours: 12);

  /// 仅用于演示；真实环境必须换成强随机密钥并从安全存储读取
  static const String jwtSecret = 'smart-hotel-skills-competition-secret-2026';

  static const int tempMin = 16;
  static const int tempMax = 30;
  static const double tempStep = 0.5;
  static const Duration tempInterval = Duration(seconds: 1);

  /// 灯具元数据（顺序与 UI 的"独立控制"一致）
  static const List<Map<String, String>> lightMeta = <Map<String, String>>[
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

  static const List<Map<String, String>> curtainMeta = <Map<String, String>>[
    <String, String>{'id': 'cloth', 'name': '布帘'},
    <String, String>{'id': 'sheer', 'name': '窗纱'},
  ];

  /// 5 个公开场景（goodnight / off 为隐藏场景，不出现在列表里）
  static const List<Map<String, String>> publicScenes = <Map<String, String>>[
    <String, String>{'id': 'bright', 'name': '明亮模式', 'icon': 'sun'},
    <String, String>{'id': 'soft', 'name': '柔和模式', 'icon': 'moon'},
    <String, String>{'id': 'reading', 'name': '阅读模式', 'icon': 'book'},
    <String, String>{'id': 'cozy', 'name': '温馨模式', 'icon': 'heart'},
    <String, String>{'id': 'sleep', 'name': '睡眠模式', 'icon': 'crescent'},
  ];

  /// 场景 → 该场景下点亮的灯具集合
  static const Map<String, List<String>> scenePresets = <String, List<String>>{
    'bright': <String>[
      'bath',
      'wardrobe',
      'floor',
      'bar',
      'readLeft',
      'readRight',
      'desk',
      'fan',
      'corridor',
    ],
    'soft': <String>['floor', 'readLeft', 'readRight'],
    'reading': <String>['readLeft', 'readRight', 'desk'],
    'cozy': <String>['floor', 'bar'],
    'sleep': <String>['corridor'],
    'goodnight': <String>[],
  };

  /// 合法的 sceneId（含两个隐藏场景）
  static const List<String> validSceneIds = <String>[
    'bright',
    'soft',
    'reading',
    'cozy',
    'sleep',
    'goodnight',
    'off',
  ];

  static const List<Map<String, String>> _defaultAccounts =
      <Map<String, String>>[
    <String, String>{
      'roomNo': '1209',
      'guestName': '乔安',
      'checkInDate': '2026-05-26'
    },
    <String, String>{
      'roomNo': '1210',
      'guestName': '张明',
      'checkInDate': '2026-05-26'
    },
    <String, String>{
      'roomNo': '1211',
      'guestName': '李娜',
      'checkInDate': '2026-05-26'
    },
  ];

  // ==================== 运行时 ====================

  final Map<String, RoomState> _rooms = <String, RoomState>{};
  Timer? _tempTimer;

  void reset() {
    _rooms.clear();
    for (final Map<String, String> account in _defaultAccounts) {
      final String roomNo = account['roomNo']!;
      _rooms[roomNo] = RoomState(
        roomNo: roomNo,
        guestName: account['guestName']!,
        checkInDate: account['checkInDate']!,
      );
    }
  }

  RoomState? room(String roomNo) => _rooms[roomNo];

  bool validateCredential(String roomNo, String guestName) {
    final RoomState? state = _rooms[roomNo];
    return state != null && state.guestName == guestName;
  }

  /// 启动温度逼近定时器（与 Node 的 startTempSimulator 等价）
  void startTempSimulator() {
    _tempTimer ??= Timer.periodic(tempInterval, (_) => _tickTemperature());
  }

  void stopTempSimulator() {
    _tempTimer?.cancel();
    _tempTimer = null;
  }

  void _tickTemperature() {
    for (final RoomState state in _rooms.values) {
      if (!state.acOn || state.currentTemp == state.targetTemp) {
        continue;
      }
      final double diff = state.targetTemp - state.currentTemp;
      final double step = diff.sign * min(tempStep, diff.abs());
      state.currentTemp = (state.currentTemp + step * 10).roundToDouble() / 10;
    }
  }

  // ==================== 业务操作 ====================

  /// 按场景预设重排灯光；不存在的 sceneId 返回 false
  bool applyScene(RoomState state, String sceneId) {
    final List<String>? preset = scenePresets[sceneId];
    if (preset == null) {
      return false;
    }
    for (final String id in state.lights.keys.toList()) {
      state.lights[id] = preset.contains(id);
    }
    state.masterLight = state.lights.values.any((bool on) => on);
    state.activeSceneId = sceneId;
    return true;
  }

  void setMasterLight(RoomState state, bool on) {
    for (final String id in state.lights.keys.toList()) {
      state.lights[id] = on;
    }
    state.masterLight = on;
    state.activeSceneId = on ? 'bright' : 'goodnight';
  }

  /// 返回被更新的灯；id 不存在返回 null
  Map<String, dynamic>? toggleLight(RoomState state, String id, bool on) {
    if (!state.lights.containsKey(id)) {
      return null;
    }
    state.lights[id] = on;
    state.masterLight = state.lights.values.any((bool value) => value);
    state.activeSceneId = null; // 单灯操作打破场景
    return state.lightJson(id);
  }

  /// 返回更新后的窗帘；id 不存在返回 null
  Map<String, dynamic>? controlCurtain(
      RoomState state, String id, String action) {
    if (!state.curtains.containsKey(id)) {
      return null;
    }
    const Map<String, String> statusMap = <String, String>{
      'open': 'opened',
      'pause': 'paused',
      'close': 'closed',
    };
    state.curtains[id] = statusMap[action]!;
    return state.curtainJson(id);
  }

  void batchCurtain(RoomState state, String action) {
    final String status = action == 'open' ? 'opened' : 'closed';
    for (final String id in state.curtains.keys.toList()) {
      state.curtains[id] = status;
    }
  }
}

/// 单个房间的完整状态（可变，服务端侧专用；不要和客户端的不可变模型混用）
class RoomState {
  RoomState({
    required this.roomNo,
    required this.guestName,
    required this.checkInDate,
  }) {
    for (final Map<String, String> meta in HotelState.lightMeta) {
      lights[meta['id']!] = false;
    }
    for (final Map<String, String> meta in HotelState.curtainMeta) {
      curtains[meta['id']!] = 'closed';
    }
  }

  final String roomNo;
  final String guestName;
  final String checkInDate;

  bool acOn = false;
  int targetTemp = 20;
  double currentTemp = 22;
  final int minTemp = HotelState.tempMin;
  final int maxTemp = HotelState.tempMax;

  String? activeSceneId;
  bool masterLight = false;

  /// 有序：插入顺序即 UI 顺序
  final Map<String, bool> lights = <String, bool>{};
  final Map<String, String> curtains = <String, String>{};

  bool doNotDisturb = false;
  bool cleaning = false;

  // ---------- 序列化 ----------

  Map<String, dynamic> roomJson() => <String, dynamic>{
        'roomNo': roomNo,
        'guestName': guestName,
        'checkInDate': checkInDate,
      };

  Map<String, dynamic> acJson() => <String, dynamic>{
        'on': acOn,
        'targetTemp': targetTemp,
        'currentTemp': currentTemp,
        'minTemp': minTemp,
        'maxTemp': maxTemp,
      };

  Map<String, dynamic> servicesJson() => <String, dynamic>{
        'doNotDisturb': doNotDisturb,
        'cleaning': cleaning,
      };

  Map<String, dynamic> lightJson(String id) {
    final Map<String, String>? meta = _findLightMeta(id);
    return <String, dynamic>{
      'id': id,
      'name': meta?['name'] ?? id,
      'icon': meta?['icon'] ?? id,
      'on': lights[id] ?? false,
    };
  }

  List<Map<String, dynamic>> lightsJson() {
    return HotelState.lightMeta
        .map((Map<String, String> meta) => lightJson(meta['id']!))
        .toList();
  }

  Map<String, dynamic> curtainJson(String id) {
    final Map<String, String>? meta = _findCurtainMeta(id);
    return <String, dynamic>{
      'id': id,
      'name': meta?['name'] ?? id,
      'status': curtains[id] ?? 'closed',
    };
  }

  List<Map<String, dynamic>> curtainsJson() {
    return HotelState.curtainMeta
        .map((Map<String, String> meta) => curtainJson(meta['id']!))
        .toList();
  }

  Map<String, dynamic> snapshotJson() => <String, dynamic>{
        'room': roomJson(),
        'ac': acJson(),
        'scenes': HotelState.publicScenes,
        'activeSceneId': activeSceneId,
        'masterLight': masterLight,
        'lights': lightsJson(),
        'curtains': curtainsJson(),
        'services': servicesJson(),
      };

  Map<String, String>? _findLightMeta(String id) {
    for (final Map<String, String> meta in HotelState.lightMeta) {
      if (meta['id'] == id) {
        return meta;
      }
    }
    return null;
  }

  Map<String, String>? _findCurtainMeta(String id) {
    for (final Map<String, String> meta in HotelState.curtainMeta) {
      if (meta['id'] == id) {
        return meta;
      }
    }
    return null;
  }

  void logState() {
    debugPrint('[server] 房间 $roomNo 状态变更：场景=$activeSceneId 总开关=$masterLight');
  }
}
