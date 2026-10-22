import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// 本地持久化：Token 与"记住我的信息"
///
/// 全部走 SharedPreferences（App 重启后仍在），
/// 与后端的无状态 JWT 配合：客户端负责存，服务端负责验。
class TokenStorage {
  TokenStorage(this._prefs);

  final SharedPreferences _prefs;

  static Future<TokenStorage> create() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return TokenStorage(prefs);
  }

  String? get token => _prefs.getString(StorageKeys.token);

  bool get remember => _prefs.getBool(StorageKeys.remember) ?? false;

  String? get roomNo => _prefs.getString(StorageKeys.roomNo);

  String? get guestName => _prefs.getString(StorageKeys.guestName);

  Future<void> saveSession(String token, {required bool remember}) async {
    await _prefs.setString(StorageKeys.token, token);
    await _prefs.setBool(StorageKeys.remember, remember);
  }

  Future<void> saveRemembered(String roomNo, String guestName) async {
    await _prefs.setString(StorageKeys.roomNo, roomNo);
    await _prefs.setString(StorageKeys.guestName, guestName);
  }

  Future<void> clearToken() async {
    await _prefs.remove(StorageKeys.token);
  }

  Future<void> clearRemembered() async {
    await _prefs.remove(StorageKeys.roomNo);
    await _prefs.remove(StorageKeys.guestName);
  }
}
