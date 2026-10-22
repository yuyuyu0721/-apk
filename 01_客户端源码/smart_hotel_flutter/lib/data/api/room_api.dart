import '../../core/network/api_client.dart';
import '../models/room_models.dart';

/// 房间域接口：GET /api/room/snapshot
/// 房间号由服务端从 Token 解析，客户端不传参。
class RoomApi {
  const RoomApi(this._client);

  final ApiClient _client;

  Future<RoomSnapshot> snapshot() async {
    final Map<String, dynamic> json =
        await _client.getJson('/api/room/snapshot');
    return RoomSnapshot.fromJson(json);
  }
}
