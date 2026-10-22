import '../../core/network/api_client.dart';
import '../models/room_models.dart';

/// 窗帘域接口
///
/// 注意：服务端不模拟运动过程，收到动作直接落状态；
/// 开合动画与暂停位置由 UI 层（CurtainPanel）自行维护。
class CurtainApi {
  const CurtainApi(this._client);

  final ApiClient _client;

  /// POST /api/curtain/control  open / pause / close → 返回更新后的单个窗帘
  Future<CurtainItem> control(String id, String action) async {
    final Map<String, dynamic> json = await _client.postJson(
      '/api/curtain/control',
      <String, dynamic>{'id': id, 'action': action},
    );
    return CurtainItem.fromJson(json);
  }

  /// POST /api/curtain/batch    仅支持 open / close
  Future<List<CurtainItem>> batch(String action) async {
    final Map<String, dynamic> json = await _client.postJson(
      '/api/curtain/batch',
      <String, dynamic>{'action': action},
    );
    final List<dynamic> list =
        json['curtains'] as List<dynamic>? ?? <dynamic>[];
    return list
        .map((dynamic e) => CurtainItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
