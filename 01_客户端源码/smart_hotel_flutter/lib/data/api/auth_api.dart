import '../../core/network/api_client.dart';
import '../models/room_models.dart';

/// 鉴权域接口
///
/// POST /api/auth/login   登录（免鉴权）
/// POST /api/auth/logout  退出（服务端无状态，不作废 Token）
/// GET  /api/ping         探活（免鉴权）
class AuthApi {
  const AuthApi(this._client);

  final ApiClient _client;

  Future<LoginResult> login(
      {required String roomNo, required String guestName}) async {
    final Map<String, dynamic> json = await _client.postJson(
      '/api/auth/login',
      <String, dynamic>{'roomNo': roomNo, 'guestName': guestName},
      auth: false,
    );
    return LoginResult.fromJson(json);
  }

  Future<void> logout() => _client.postVoid('/api/auth/logout');

  /// 启动探活：仅用于日志与联通性自检，失败不阻塞
  Future<void> ping() => _client.getJson('/api/ping', auth: false);
}
