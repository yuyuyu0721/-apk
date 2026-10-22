import '../../core/network/api_client.dart';
import '../models/room_models.dart';

/// 空调域接口
class AcApi {
  const AcApi(this._client);

  final ApiClient _client;

  /// POST /api/ac/power  → 返回完整 AcState
  Future<AcState> power(bool on) async {
    final Map<String, dynamic> json = await _client.postJson(
      '/api/ac/power',
      <String, dynamic>{'on': on},
    );
    return AcState.fromJson(json);
  }

  /// POST /api/ac/temperature  → 目标温度，整数 16-30
  Future<AcState> setTemperature(int targetTemp) async {
    final Map<String, dynamic> json = await _client.postJson(
      '/api/ac/temperature',
      <String, dynamic>{'targetTemp': targetTemp},
    );
    return AcState.fromJson(json);
  }
}
