import 'dart:convert';

import 'package:crypto/crypto.dart';

/// JWT HS256 的签发与校验（与 smart_hotel_server 的 jsonwebtoken 行为对齐）
///
/// 只实现本赛题用到的部分：HS256 + exp，不做 alg 白名单之外的扩展。
class JwtError implements Exception {
  const JwtError(this.expired);

  /// true = 已过期（对应业务码 1102），false = 无效（1101）
  final bool expired;
}

class JwtHs256 {
  const JwtHs256._();

  static String sign({
    required Map<String, dynamic> payload,
    required String secret,
  }) {
    final String header =
        _encode(<String, dynamic>{'alg': 'HS256', 'typ': 'JWT'});
    final String body = _encode(payload);
    final String signingInput = '$header.$body';
    return '$signingInput.${_sign(signingInput, secret)}';
  }

  /// 校验失败抛 JwtError
  static Map<String, dynamic> verify(String token, String secret) {
    final List<String> parts = token.split('.');
    if (parts.length != 3) {
      throw const JwtError(false);
    }
    final String signingInput = '${parts[0]}.${parts[1]}';
    if (!_safeEquals(_sign(signingInput, secret), parts[2])) {
      throw const JwtError(false);
    }

    Map<String, dynamic> payload;
    try {
      final String decoded =
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      payload = jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      throw const JwtError(false);
    }

    final Object? exp = payload['exp'];
    if (exp is int) {
      final int nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (nowSeconds >= exp) {
        throw const JwtError(true);
      }
    }
    return payload;
  }

  static String _encode(Map<String, dynamic> obj) {
    return base64Url.encode(utf8.encode(jsonEncode(obj))).replaceAll('=', '');
  }

  static String _sign(String input, String secret) {
    final Hmac hmac = Hmac(sha256, utf8.encode(secret));
    return base64Url
        .encode(hmac.convert(utf8.encode(input)).bytes)
        .replaceAll('=', '');
  }

  /// 定长比较，避免签名校验被时序攻击（与 jsonwebtoken 行为一致）
  static bool _safeEquals(String a, String b) {
    if (a.length != b.length) {
      return false;
    }
    int diff = 0;
    for (int i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
