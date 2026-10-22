/// 接口层通用类型：业务码、异常
class ApiCode {
  const ApiCode._();

  static const int ok = 0;
  static const int paramError = 1001;
  static const int loginFailed = 1002;
  static const int notFound = 1003;
  static const int tokenInvalid = 1101;
  static const int tokenExpired = 1102;
  static const int deviceOffline = 1201;
  static const int deviceBusy = 1202;
  static const int internalError = 5000;

  /// 客户端自定义：网络层失败
  static const int networkError = -1;

  /// 客户端自定义：响应无法解析
  static const int parseError = -2;
}

/// 业务异常：接口层所有失败路径统一抛这个类型
class ApiException implements Exception {
  ApiException(this.code, this.message);

  final int code;
  final String message;

  bool get isAuthError =>
      code == ApiCode.tokenInvalid || code == ApiCode.tokenExpired;

  @override
  String toString() => 'ApiException($code): $message';
}
