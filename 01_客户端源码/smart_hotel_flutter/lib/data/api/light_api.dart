import '../../core/network/api_client.dart';
import '../models/room_models.dart';

/// 灯光域接口
class LightApi {
  const LightApi(this._client);

  final ApiClient _client;

  /// POST /api/light/master  开 → activeSceneId=bright；关 → goodnight
  Future<LightStateResult> master(bool on) async {
    final Map<String, dynamic> json = await _client.postJson(
      '/api/light/master',
      <String, dynamic>{'on': on},
    );
    return LightStateResult.fromJson(json);
  }

  /// POST /api/light/scene   sceneId 支持 5 个公开场景 + goodnight + off
  Future<LightStateResult> scene(String sceneId) async {
    final Map<String, dynamic> json = await _client.postJson(
      '/api/light/scene',
      <String, dynamic>{'sceneId': sceneId},
    );
    return LightStateResult.fromJson(json);
  }

  /// POST /api/light/toggle  单灯操作会把 activeSceneId 置为 null
  Future<LightToggleResult> toggle(String id, bool on) async {
    final Map<String, dynamic> json = await _client.postJson(
      '/api/light/toggle',
      <String, dynamic>{'id': id, 'on': on},
    );
    return LightToggleResult.fromJson(json);
  }
}
