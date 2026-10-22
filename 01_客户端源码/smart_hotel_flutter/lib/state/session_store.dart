import 'package:flutter/foundation.dart';

import '../core/storage/token_storage.dart';
import '../data/models/room_models.dart';

/// 会话状态：Token + 用户信息
///
/// 只负责"存哪儿、怎么取"，不负责调接口——登录由页面调 AuthApi 完成后写入，
/// 这样 SessionStore 不依赖 api 层，避免 ApiClient ←→ Session 的循环依赖。
class SessionStore extends ChangeNotifier {
  SessionStore(this._storage);

  final TokenStorage _storage;

  String? _token;
  RoomInfo? _user;
  bool _remembered = true;

  String? get token => _token;

  RoomInfo? get user => _user;

  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  bool get remember => _remembered;

  set remember(bool value) {
    if (_remembered == value) {
      return;
    }
    _remembered = value;
    notifyListeners();
  }

  /// 冷启动恢复（SharedPreferences 已在 bootstrap 阶段加载完毕，这里同步读取）
  void restore() {
    _token = _storage.token;
    final String? roomNo = _storage.roomNo;
    final String? guestName = _storage.guestName;
    if (roomNo != null && guestName != null && guestName.isNotEmpty) {
      _user = RoomInfo(roomNo: roomNo, guestName: guestName, checkInDate: '');
      _remembered = true;
    } else {
      // 没记住账号时默认勾选，符合效果图的默认态
      _remembered = true;
    }
  }

  /// 登录成功后写入会话；remember=false 时只留 Token，不记账号
  Future<void> save({
    required String token,
    required RoomInfo user,
    required bool remember,
  }) async {
    _token = token;
    _user = user;
    _remembered = remember;
    await _storage.saveSession(token, remember: remember);
    if (remember) {
      await _storage.saveRemembered(user.roomNo, user.guestName);
    }
    notifyListeners();
  }

  /// 退出登录：Token 与账号缓存一起清
  Future<void> logout() async {
    _token = null;
    _user = null;
    await _storage.clearToken();
    await _storage.clearRemembered();
    notifyListeners();
  }

  /// 401 拦截：同步失效内存状态，磁盘异步清理（不阻塞跳转）
  void clearSession() {
    _token = null;
    _user = null;
    notifyListeners();
    _storage.clearToken();
  }

  /// 登录页回填"记住我的信息"
  ({String roomNo, String guestName})? get rememberedAccount {
    final String? roomNo = _storage.roomNo;
    final String? guestName = _storage.guestName;
    if (_storage.remember && roomNo != null && guestName != null) {
      return (roomNo: roomNo, guestName: guestName);
    }
    return null;
  }
}
