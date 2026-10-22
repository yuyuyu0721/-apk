import '../../core/network/api_client.dart';
import '../models/room_models.dart';

/// 客房服务域接口
class ServiceApi {
  const ServiceApi(this._client);

  final ApiClient _client;

  /// POST /api/service/toggle  key: doNotDisturb / cleaning
  Future<ServiceState> toggle(String key, bool on) async {
    final Map<String, dynamic> json = await _client.postJson(
      '/api/service/toggle',
      <String, dynamic>{'key': key, 'on': on},
    );
    return ServiceState.fromJson(json);
  }

  /// POST /api/service/sos  一次性事件，无参数、无状态
  Future<void> sos() => _client.postVoid('/api/service/sos');
}
