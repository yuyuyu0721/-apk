/// 与《智慧客房项目接口文档》第 4 节逐字段对齐的数据模型
///
/// 原则：字段名与后端返回完全一致（camelCase），不做前端改名；
/// 数字统一用 int / double 收敛（后端 currentTemp 是 0.5 步进的浮点）。
library;

class RoomInfo {
  const RoomInfo({
    required this.roomNo,
    required this.guestName,
    required this.checkInDate,
  });

  factory RoomInfo.fromJson(Map<String, dynamic> json) {
    return RoomInfo(
      roomNo: json['roomNo'] as String? ?? '',
      guestName: json['guestName'] as String? ?? '',
      checkInDate: json['checkInDate'] as String? ?? '',
    );
  }

  final String roomNo;
  final String guestName;
  final String checkInDate;

  static const RoomInfo empty =
      RoomInfo(roomNo: '', guestName: '', checkInDate: '');
}

class AcState {
  const AcState({
    required this.on,
    required this.targetTemp,
    required this.currentTemp,
    required this.minTemp,
    required this.maxTemp,
  });

  factory AcState.fromJson(Map<String, dynamic> json) {
    return AcState(
      on: json['on'] as bool? ?? false,
      targetTemp: (json['targetTemp'] as num? ?? 20).toInt(),
      currentTemp: (json['currentTemp'] as num? ?? 22).toDouble(),
      minTemp: (json['minTemp'] as num? ?? 16).toInt(),
      maxTemp: (json['maxTemp'] as num? ?? 30).toInt(),
    );
  }

  final bool on;

  /// 目标温度（大字展示这个）
  final int targetTemp;

  /// 当前温度（小字展示，后端每秒 0.5℃ 逼近）
  final double currentTemp;

  final int minTemp;
  final int maxTemp;

  static const AcState empty = AcState(
    on: false,
    targetTemp: 20,
    currentTemp: 22,
    minTemp: 16,
    maxTemp: 30,
  );
}

class SceneItem {
  const SceneItem({required this.id, required this.name, required this.icon});

  factory SceneItem.fromJson(Map<String, dynamic> json) {
    return SceneItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
    );
  }

  final String id;
  final String name;
  final String icon;
}

class LightItem {
  const LightItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.on,
  });

  factory LightItem.fromJson(Map<String, dynamic> json) {
    return LightItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      on: json['on'] as bool? ?? false,
    );
  }

  final String id;
  final String name;
  final String icon;
  final bool on;

  LightItem copyWith({bool? on}) {
    return LightItem(id: id, name: name, icon: icon, on: on ?? this.on);
  }
}

class CurtainItem {
  const CurtainItem(
      {required this.id, required this.name, required this.status});

  factory CurtainItem.fromJson(Map<String, dynamic> json) {
    return CurtainItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? 'closed',
    );
  }

  final String id;
  final String name;

  /// opened / paused / closed（注意是形容词，动作是 open/pause/close）
  final String status;
}

class ServiceState {
  const ServiceState({required this.doNotDisturb, required this.cleaning});

  factory ServiceState.fromJson(Map<String, dynamic> json) {
    return ServiceState(
      doNotDisturb: json['doNotDisturb'] as bool? ?? false,
      cleaning: json['cleaning'] as bool? ?? false,
    );
  }

  final bool doNotDisturb;
  final bool cleaning;

  static const ServiceState empty = ServiceState(
    doNotDisturb: false,
    cleaning: false,
  );
}

class RoomSnapshot {
  const RoomSnapshot({
    required this.room,
    required this.ac,
    required this.scenes,
    required this.activeSceneId,
    required this.masterLight,
    required this.lights,
    required this.curtains,
    required this.services,
  });

  factory RoomSnapshot.fromJson(Map<String, dynamic> json) {
    final List<dynamic> scenesJson =
        json['scenes'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> lightsJson =
        json['lights'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> curtainsJson =
        json['curtains'] as List<dynamic>? ?? <dynamic>[];

    return RoomSnapshot(
      room: RoomInfo.fromJson(
          json['room'] as Map<String, dynamic>? ?? <String, dynamic>{}),
      ac: AcState.fromJson(
          json['ac'] as Map<String, dynamic>? ?? <String, dynamic>{}),
      scenes: scenesJson
          .map((dynamic e) => SceneItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      activeSceneId: json['activeSceneId'] as String?,
      masterLight: json['masterLight'] as bool? ?? false,
      lights: lightsJson
          .map((dynamic e) => LightItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      curtains: curtainsJson
          .map((dynamic e) => CurtainItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      services: ServiceState.fromJson(
        json['services'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
    );
  }

  final RoomInfo room;
  final AcState ac;
  final List<SceneItem> scenes;

  /// 可能为 goodnight（不在 scenes 列表里），也可能为 null
  final String? activeSceneId;
  final bool masterLight;
  final List<LightItem> lights;
  final List<CurtainItem> curtains;
  final ServiceState services;

  static const RoomSnapshot empty = RoomSnapshot(
    room: RoomInfo.empty,
    ac: AcState.empty,
    scenes: <SceneItem>[],
    activeSceneId: null,
    masterLight: false,
    lights: <LightItem>[],
    curtains: <CurtainItem>[],
    services: ServiceState.empty,
  );
}

class LoginResult {
  const LoginResult({required this.token, required this.userInfo});

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      token: json['token'] as String? ?? '',
      userInfo: RoomInfo.fromJson(
        json['userInfo'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
    );
  }

  final String token;
  final RoomInfo userInfo;
}

/// 总开关 / 切换场景的统一返回
class LightStateResult {
  const LightStateResult({
    required this.activeSceneId,
    required this.masterLight,
    required this.lights,
  });

  factory LightStateResult.fromJson(Map<String, dynamic> json) {
    final List<dynamic> lightsJson =
        json['lights'] as List<dynamic>? ?? <dynamic>[];
    return LightStateResult(
      activeSceneId: json['activeSceneId'] as String?,
      masterLight: json['masterLight'] as bool? ?? false,
      lights: lightsJson
          .map((dynamic e) => LightItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String? activeSceneId;
  final bool masterLight;
  final List<LightItem> lights;
}

/// 单灯开关返回
class LightToggleResult {
  const LightToggleResult({
    required this.light,
    required this.masterLight,
    required this.activeSceneId,
  });

  factory LightToggleResult.fromJson(Map<String, dynamic> json) {
    return LightToggleResult(
      light: LightItem.fromJson(
        json['light'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      masterLight: json['masterLight'] as bool? ?? false,
      activeSceneId: json['activeSceneId'] as String?,
    );
  }

  final LightItem light;
  final bool masterLight;
  final String? activeSceneId;
}
