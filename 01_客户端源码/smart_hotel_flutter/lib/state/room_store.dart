import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../core/network/api_exception.dart';
import '../data/api/ac_api.dart';
import '../data/api/curtain_api.dart';
import '../data/api/light_api.dart';
import '../data/api/room_api.dart';
import '../data/api/service_api.dart';
import '../data/models/room_models.dart';

/// 房间业务状态（全应用唯一数据源）
///
/// 设计要点：
///   - 每次写操作都走"调接口 → 用返回值刷新快照 → 通知 UI"的闭环，不做乐观更新。
///     后端会联动多个字段（切场景同时改 9 个灯 + 总开关 + activeSceneId），
///     乐观更新必然对不上。
///   - 所有写操作排进同一条 Future 链串行执行：既不丢点击，也不会被乱序响应覆盖。
///   - onMessage 是注入的提示回调（UI 层接 SnackBar），Store 本身不依赖任何 Widget，
///     这样单元测试可以只收集提示文案而不启动界面。
class RoomStore extends ChangeNotifier {
  RoomStore({
    required RoomApi roomApi,
    required AcApi acApi,
    required LightApi lightApi,
    required CurtainApi curtainApi,
    required ServiceApi serviceApi,
    required this.onMessage,
  })  : _roomApi = roomApi,
        _acApi = acApi,
        _lightApi = lightApi,
        _curtainApi = curtainApi,
        _serviceApi = serviceApi;

  final RoomApi _roomApi;
  final AcApi _acApi;
  final LightApi _lightApi;
  final CurtainApi _curtainApi;
  final ServiceApi _serviceApi;

  /// UI 提示出口（SnackBar / Toast）
  final void Function(String message) onMessage;

  RoomSnapshot _snapshot = RoomSnapshot.empty;
  bool _loading = false;
  Future<void> _queue = Future<void>.value();
  bool _hasData = false;

  RoomSnapshot get snapshot => _snapshot;
  bool get loading => _loading;

  /// 串行队列里是否还有未完成的动作（UI 可用来做轻量忙碌提示）
  bool get busy => _pending > 0;
  int _pending = 0;
  bool get hasData => _hasData;

  RoomInfo get room => _snapshot.room;
  AcState get ac => _snapshot.ac;
  List<SceneItem> get scenes => _snapshot.scenes;
  String? get activeSceneId => _snapshot.activeSceneId;
  bool get masterLight => _snapshot.masterLight;
  List<LightItem> get lights => _snapshot.lights;
  List<CurtainItem> get curtains => _snapshot.curtains;
  ServiceState get services => _snapshot.services;

  // ==================== 读 ====================

  Future<void> refresh() async {
    _loading = true;
    notifyListeners();
    try {
      _snapshot = await _roomApi.snapshot();
      _hasData = true;
    } on ApiException catch (e) {
      onMessage(e.message);
    } catch (_) {
      onMessage('加载房间数据失败，请下拉重试');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// 按给定 id 顺序过滤场景（首页 4 个 / 灯光页 5 个）
  List<SceneItem> pickScenes(List<String> ids) {
    final List<SceneItem> result = <SceneItem>[];
    for (final String id in ids) {
      for (final SceneItem item in _snapshot.scenes) {
        if (item.id == id) {
          result.add(item);
          break;
        }
      }
    }
    return result;
  }

  bool isSceneActive(String id) => _snapshot.activeSceneId == id;

  String sceneName(String id) {
    for (final SceneItem item in _snapshot.scenes) {
      if (item.id == id) {
        return item.name;
      }
    }
    if (id == SceneIds.goodnight) {
      return '晚安模式';
    }
    return '场景';
  }

  CurtainItem? findCurtain(String id) {
    for (final CurtainItem item in _snapshot.curtains) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  // ==================== 写：空调 ====================

  Future<void> toggleAcPower() => _guard(() async {
        final bool next = !_snapshot.ac.on;
        final AcState ac = await _acApi.power(next);
        _snapshot = _merge(ac: ac);
        onMessage(next ? '已开启空调' : '已关闭空调');
      });

  Future<void> changeTargetTemp(int delta) async {
    final int next = _snapshot.ac.targetTemp + delta;
    if (next < TempLimits.min || next > TempLimits.max) {
      onMessage('温度范围 ${TempLimits.min}~${TempLimits.max}℃');
      return;
    }
    await _guard(() async {
      final AcState ac = await _acApi.setTemperature(next);
      _snapshot = _merge(ac: ac);
      onMessage('温度已调至 $next℃');
    });
  }

  // ==================== 写：灯光 ====================

  Future<void> setMasterLight(bool on) => _guard(() async {
        final LightStateResult result = await _lightApi.master(on);
        _applyLightState(result);
        onMessage(on ? '已打开全部灯光' : '已关闭全部灯光');
      });

  Future<void> applyScene(String sceneId) => _guard(() async {
        // 演示视频规范（29-31s）：总开关未开启时，场景模式不允许直接启动，
        // 点了要提示"请先打开总开关"并拒绝执行；晚安（全关）与 off（仅退高亮）
        // 本身就是关灯动作，不受总开关限制。
        final bool needsMaster = sceneId != SceneIds.off &&
            sceneId != SceneIds.goodnight &&
            !_snapshot.masterLight;
        if (needsMaster) {
          onMessage('请先打开总开关');
          return;
        }
        final LightStateResult result = await _lightApi.scene(sceneId);
        _applyLightState(result);
        if (sceneId == SceneIds.off) {
          onMessage('已退出场景模式');
        } else if (sceneId == SceneIds.goodnight) {
          onMessage('已关闭所有灯光');
        } else {
          onMessage('已切换到${sceneName(sceneId)}');
        }
      });

  /// 首页"晚安模式"卡片：已激活时再点一次走 off（只取消高亮，不改灯光）
  Future<void> toggleGoodnight() {
    if (_snapshot.activeSceneId == SceneIds.goodnight) {
      return applyScene(SceneIds.off);
    }
    return applyScene(SceneIds.goodnight);
  }

  Future<void> toggleLight(LightItem light) => _guard(() async {
        final LightToggleResult result =
            await _lightApi.toggle(light.id, !light.on);
        final List<LightItem> nextLights = <LightItem>[];
        for (final LightItem item in _snapshot.lights) {
          nextLights.add(item.id == result.light.id ? result.light : item);
        }
        _snapshot = _merge(
          lights: nextLights,
          masterLight: result.masterLight,
          activeSceneId: result.activeSceneId,
        );
        onMessage('${result.light.name}已${result.light.on ? '开启' : '关闭'}');
      });

  void _applyLightState(LightStateResult result) {
    _snapshot = _merge(
      activeSceneId: result.activeSceneId,
      masterLight: result.masterLight,
      lights: result.lights,
    );
  }

  // ==================== 写：窗帘 ====================

  Future<void> controlCurtain(String id, String action) => _guard(() async {
        final CurtainItem updated = await _curtainApi.control(id, action);
        final List<CurtainItem> next = <CurtainItem>[];
        for (final CurtainItem item in _snapshot.curtains) {
          next.add(item.id == updated.id ? updated : item);
        }
        _snapshot = _merge(curtains: next);
        onMessage('${updated.name}${_actionVerb(action)}');
      });

  Future<void> batchCurtain(String action) => _guard(() async {
        final List<CurtainItem> curtains = await _curtainApi.batch(action);
        _snapshot = _merge(curtains: curtains);
        onMessage(action == CurtainActions.open ? '全部窗帘已打开' : '全部窗帘已关闭');
      });

  String _actionVerb(String action) {
    switch (action) {
      case CurtainActions.open:
        return '已打开';
      case CurtainActions.pause:
        return '已暂停';
      default:
        return '已关闭';
    }
  }

  // ==================== 写：客房服务 ====================

  Future<void> toggleService(String key) => _guard(() async {
        final bool current = key == ServiceKeys.doNotDisturb
            ? _snapshot.services.doNotDisturb
            : _snapshot.services.cleaning;
        final ServiceState state = await _serviceApi.toggle(key, !current);
        _snapshot = _merge(services: state);
        final String name = key == ServiceKeys.doNotDisturb ? '请勿打扰' : '清理房间';
        onMessage('已${!current ? '开启' : '关闭'}$name');
      });

  Future<void> sendSos() => _guard(() async {
        await _serviceApi.sos();
        onMessage('紧急求助已发送，前台将立即与您联系');
      });

  // ==================== 内部 ====================

  /// 用于区分"没传这个字段"与"显式传 null"（activeSceneId 合法值包含 null）
  static const Object _keepScene = Object();

  RoomSnapshot _merge({
    RoomInfo? room,
    AcState? ac,
    List<SceneItem>? scenes,
    Object? activeSceneId = _keepScene,
    bool? masterLight,
    List<LightItem>? lights,
    List<CurtainItem>? curtains,
    ServiceState? services,
  }) {
    final RoomSnapshot current = _snapshot;
    final String? nextSceneId = identical(activeSceneId, _keepScene)
        ? current.activeSceneId
        : activeSceneId as String?;
    return RoomSnapshot(
      room: room ?? current.room,
      ac: ac ?? current.ac,
      scenes: scenes ?? current.scenes,
      activeSceneId: nextSceneId,
      masterLight: masterLight ?? current.masterLight,
      lights: lights ?? current.lights,
      curtains: curtains ?? current.curtains,
      services: services ?? current.services,
    );
  }

  /// 统一执行壳：**串行排队**，不丢点击
  ///
  /// 之前用布尔锁 + 提前 return，导致"上一个请求还没回来时点场景会被静默吞掉"——
  /// 表现就是"总开关关着时点场景没反应，得先把总开关开一下"。
  /// 现在改为把动作排进 Future 链：顺序执行、点击不丢失、状态不会被乱序响应覆盖。
  Future<void> _guard(Future<void> Function() task) {
    _pending++;
    final Future<void> next = _queue.then((_) async {
      try {
        await task();
      } on ApiException catch (e) {
        onMessage(e.message);
      } catch (_) {
        onMessage('操作失败，请稍后重试');
      } finally {
        _pending--;
        notifyListeners();
      }
    });
    _queue = next;
    return next;
  }
}
