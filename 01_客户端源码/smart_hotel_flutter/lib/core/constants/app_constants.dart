/// 全局常量：路由名、存储键、业务枚举、数值边界
///
/// 约定：业务代码不出现裸字符串，改一处即可全局生效。
class AppRoutes {
  const AppRoutes._();

  static const String login = '/login';
  static const String main = '/main';
}

class StorageKeys {
  const StorageKeys._();

  static const String token = 'auth_token';
  static const String roomNo = 'remember_room_no';
  static const String guestName = 'remember_guest_name';
  static const String remember = 'remember_enabled';
}

class TempLimits {
  const TempLimits._();

  static const int min = 16;
  static const int max = 30;
  static const int step = 1;
}

/// 灯光场景 id
class SceneIds {
  const SceneIds._();

  static const String bright = 'bright';
  static const String soft = 'soft';
  static const String reading = 'reading';
  static const String cozy = 'cozy';
  static const String sleep = 'sleep';

  /// 隐藏场景：一键全关，不出现在 scenes 列表，但可能成为 activeSceneId
  static const String goodnight = 'goodnight';

  /// 隐藏场景：仅清空 activeSceneId，不动灯具
  static const String off = 'off';

  /// 首页只展示 4 个（效果图如此），睡眠模式放在灯光页
  static const List<String> homeList = [bright, soft, reading, cozy];

  /// 灯光页展示 5 个公开场景
  static const List<String> lightList = [bright, soft, reading, cozy, sleep];
}

/// 窗帘
class CurtainIds {
  const CurtainIds._();

  static const String cloth = 'cloth';
  static const String sheer = 'sheer';
}

class CurtainActions {
  const CurtainActions._();

  static const String open = 'open';
  static const String pause = 'pause';
  static const String close = 'close';
}

class CurtainStatus {
  const CurtainStatus._();

  static const String opened = 'opened';
  static const String paused = 'paused';
  static const String closed = 'closed';
}

/// 客房服务键
class ServiceKeys {
  const ServiceKeys._();

  static const String doNotDisturb = 'doNotDisturb';
  static const String cleaning = 'cleaning';
}
