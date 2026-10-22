/// 运行环境与网络配置
///
/// 提供两种后端模式：
///   embedded —— App 自带后端（Dart 复刻 smart_hotel_server），进程内监听 127.0.0.1
///              优点：装到手机上就能完整演示，不需要电脑、不需要网络
///   remote   —— 连接电脑上跑的 Node 后端，按载体选地址
///
/// 两者接口契约完全一致，客户端代码（ApiClient / Store / 页面）无需任何改动，
/// 切换只改这一个常量。
enum ServerMode {
  /// App 内置后端（默认）
  embedded,

  /// 连接外部 Node 后端
  remote,
}

/// remote 模式下的载体地址
enum HostEnv {
  /// Android 模拟器
  androidEmulator,

  /// iOS 模拟器 / Windows / macOS 桌面
  desktop,

  /// 真机 + 同一 Wi-Fi，直连电脑内网 IP
  physicalDevice,

  /// 真机 + USB 数据线，配合 `adb reverse tcp:3000 tcp:3000`
  usbReverse,
}

class AppConfig {
  const AppConfig._();

  /// 当前后端模式：默认内置，现场演示不依赖任何外部服务
  static const ServerMode serverMode = ServerMode.embedded;

  /// remote 模式下才生效
  static const HostEnv env = HostEnv.usbReverse;

  /// 内置后端优先监听的端口（被占用时 HotelServer 会顺延到 3001 / 3100）
  static const int defaultPort = 3000;

  /// 走 Wi-Fi 真机时改成自己电脑的 IPv4（ipconfig 查看）
  static const String deviceHost = '192.168.1.100';

  static const String androidEmulatorHost = '10.0.2.2';

  /// 超时：远程模式要覆盖后端 100-300ms 延迟 + 弱网
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);

  /// 是否打印请求日志
  static const bool enableHttpLog = true;

  static int _activePort = defaultPort;

  /// 内置后端实际绑定的端口（启动后由 HotelServer 回写）
  static int get port => _activePort;

  static void bindPort(int port) {
    _activePort = port;
  }

  static String get host {
    if (serverMode == ServerMode.embedded) {
      // 只监听回环地址：外部访问不到，也不会意外暴露到局域网
      return '127.0.0.1';
    }
    switch (env) {
      case HostEnv.androidEmulator:
        return androidEmulatorHost;
      case HostEnv.desktop:
        return 'localhost';
      case HostEnv.physicalDevice:
        return deviceHost;
      case HostEnv.usbReverse:
        // 手机上的 localhost 被 adb reverse 转发到电脑的 3000 端口
        return 'localhost';
    }
  }

  static String get baseUrl => 'http://$host:$port';

  /// 登录页底部展示的调试信息
  static String get envLabel => '${serverMode.name} · $baseUrl';
}
