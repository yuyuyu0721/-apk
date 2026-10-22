import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api_exception.dart';

typedef TokenProvider = String? Function();
typedef UnauthorizedHandler = void Function();

/// 网络请求核心（唯一出口）
///
/// 职责：
///   1. 拼接 BaseURL（来自 AppConfig）
///   2. 注入 Content-Type 与 Authorization: Bearer {token}
///   3. 解包 Result<T>，把"HTTP 2xx 但业务码非 0"也视为失败
///   4. 401（1101/1102）统一回调 onUnauthorized，由上层决定清会话与跳转
///   5. 把网络异常翻译成可读的中文提示
///
/// 依赖注入：http.Client / TokenProvider / onUnauthorized 都可替换，
/// 因此可以在单测里用 MockClient 完整覆盖成功与各类失败分支。
class ApiClient {
  ApiClient({
    http.Client? client,
    this.tokenProvider,
    this.onUnauthorized,
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final TokenProvider? tokenProvider;
  final UnauthorizedHandler? onUnauthorized;

  Future<Map<String, dynamic>> getJson(String path, {bool auth = true}) {
    return _send('GET', path, null, auth);
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) {
    return _send('POST', path, body, auth);
  }

  /// 无返回体的接口（logout / sos）：后端 data 字段缺省
  Future<void> postVoid(String path, {bool auth = true}) async {
    await _send('POST', path, null, auth);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path,
    Map<String, dynamic>? body,
    bool auth,
  ) async {
    final Uri uri = Uri.parse('${AppConfig.baseUrl}$path');
    final Map<String, String> headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (auth) {
      final String? token = tokenProvider?.call();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    http.Response response;
    try {
      if (method == 'GET') {
        response = await _client
            .get(uri, headers: headers)
            .timeout(AppConfig.connectTimeout);
      } else {
        response = await _client
            .post(uri,
                headers: headers, body: body == null ? null : jsonEncode(body))
            .timeout(AppConfig.connectTimeout);
      }
    } on TimeoutException {
      throw ApiException(ApiCode.networkError, '请求超时，请确认后端服务是否启动');
    } catch (_) {
      throw ApiException(
        ApiCode.networkError,
        '无法连接后端服务（${AppConfig.baseUrl}），请确认服务已启动',
      );
    }

    if (AppConfig.enableHttpLog) {
      debugPrint('[http] $method $path -> ${response.statusCode}');
    }

    return _parse(response, path);
  }

  Map<String, dynamic> _parse(http.Response response, String path) {
    Map<String, dynamic> envelope;
    try {
      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      envelope = decoded as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(ApiCode.parseError, '服务端响应格式异常（$path）');
    }

    final int code = (envelope['code'] as num?)?.toInt() ?? ApiCode.parseError;
    final String message = (envelope['msg'] as String?) ?? '';

    // 业务码优先：后端 401 时同样返回 { code, msg } 且无 data
    if (code == ApiCode.tokenInvalid ||
        code == ApiCode.tokenExpired ||
        response.statusCode == 401) {
      onUnauthorized?.call();
      throw ApiException(code, message.isEmpty ? '登录状态已失效' : message);
    }
    if (code != ApiCode.ok) {
      throw ApiException(code, message);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
          ApiCode.networkError, '请求失败（HTTP ${response.statusCode}）');
    }

    final Object? data = envelope['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    return <String, dynamic>{};
  }

  void dispose() => _client.close();
}
