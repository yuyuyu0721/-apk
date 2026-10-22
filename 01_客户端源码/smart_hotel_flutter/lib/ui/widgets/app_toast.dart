import 'package:flutter/material.dart';

/// 全局轻提示（对照演示视频的样式）
///
/// 视频里的提示是一条**白底黑字的胶囊**，水平居中、悬在底部导航上方，
/// 宽度随文案收缩（不是通栏），约 42dp 高、15sp 字号。
/// 用 MaterialApp 的 scaffoldMessengerKey 做唯一出口，
/// Store / 网络层都不需要持有 BuildContext。
class AppToast {
  const AppToast._();

  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// 提示条与屏幕底部的距离：悬浮导航 90 + 底边距 10 + 间隙 14
  static const double _bottomOffset = 114;

  static const Duration _duration = Duration(seconds: 2);

  static const Color _bg = Color(0xFFF8F7F5);
  static const Color _fg = Color(0xFF262626);

  static void show(String message) {
    final ScaffoldMessengerState? messenger = messengerKey.currentState;
    if (messenger == null || message.isEmpty) {
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          // 通栏透明、内容自己收起宽度 → 得到"居中胶囊"而不是一整条
          margin: const EdgeInsets.only(bottom: _bottomOffset),
          duration: _duration,
          content: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x2E000000),
                      blurRadius: 14,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  message,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.25,
                    color: _fg,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
  }
}
