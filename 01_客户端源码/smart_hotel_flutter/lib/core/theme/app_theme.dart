import 'dart:ui';

import 'package:flutter/material.dart';

/// 设计令牌 —— 全部按设计图（880×1904 @2x → 440×952dp）实测得出
class D {
  const D._();

  // ==================== 颜色 ====================
  /// 主色：设计图中"明亮模式"选中块、导航选中块实测 #999854
  static const Color accent = Color(0xFF999854);
  static const Color accentDark = Color(0xFF6E6D3A);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF); // 70%
  static const Color textTertiary = Color(0x8AFFFFFF); // 54%

  /// 玻璃卡片：白色 10%，描边 18%
  static const Color glass = Color(0x1AFFFFFF);
  static const Color glassStrong = Color(0x26FFFFFF);
  static const Color glassBorder = Color(0x2EFFFFFF);

  /// 白底胶囊内文字（"运行中"）
  static const Color onWhite = Color(0xFF3C3C3C);

  static const Color danger = Color(0xFFFF3636);
  static const Color scrim = Color(0x14000000);

  // ==================== 尺寸 ====================
  static const double page = 16;
  static const double gap = 16;

  static const double radiusCard = 20;
  static const double radiusChip = 14;
  static const double radiusTile = 16;
  static const double radiusPill = 999;

  static const double cardTitle = 20; // 区块标题
  static const double cardBody = 17; // 卡片标题 / 场景名
  static const double label = 16; // 列表项
  static const double caption = 13; // 当前温度等
  static const double tiny = 12; // 胶囊 / 导航标签
  static const double pageTitle = 30;
  static const double hero = 46;

  /// 导航条高度：设计稿 01首页.png 实测 181px @2x = 90.5dp
  static const double navHeight = 90;
  static const double navBottom = 10;

  /// 玻璃模糊强度
  static const double blurSigma = 18;
}

/// 兼容旧命名的别名（页面里统一用 D，这里保留少量语义别名）
class AppColors {
  const AppColors._();

  static const Color primary = D.accent;
  static const Color primaryDark = D.accentDark;
  static const Color textPrimary = D.textPrimary;
  static const Color textSecondary = D.textSecondary;
  static const Color textTertiary = D.textTertiary;
  static const Color danger = D.danger;
  static const Color surfaceMuted = D.glass;
}

class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double page = 16;
}

class AppRadius {
  const AppRadius._();

  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double pill = 999;
}

class AppSizes {
  const AppSizes._();

  /// 导航条高度：设计稿 01首页.png 实测 181px @2x = 90.5dp
  static const double navHeight = 90;
  static const double buttonHeight = 56;
  static const double rowHeight = 46;
  static const double maxContentWidth = 520;
}

/// 玻璃卡片装饰（不含背景模糊；模糊由 GlassCard 组件统一处理）
BoxDecoration glassDecoration({
  Color color = D.glass,
  Color borderColor = D.glassBorder,
  double radius = D.radiusCard,
  bool border = true,
}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: border ? Border.all(color: borderColor, width: 1) : null,
  );
}

/// 背景模糊滤镜（BackdropFilter 用）
ImageFilter glassBlur() =>
    ImageFilter.blur(sigmaX: D.blurSigma, sigmaY: D.blurSigma);

/// 输入框装饰（登录页两个白色胶囊）
InputDecoration loginInputDecoration({String? hint, Widget? icon}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF9A9A9A), fontSize: 15),
    prefixIcon: icon,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(D.radiusPill),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(D.radiusPill),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(D.radiusPill),
      borderSide: BorderSide.none,
    ),
  );
}

ThemeData buildAppTheme() {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: D.accent,
    brightness: Brightness.light,
  ).copyWith(
    primary: D.accent,
    surface: D.accent,
    error: D.danger,
  );

  final ThemeData base = ThemeData(useMaterial3: true, colorScheme: scheme);

  return base.copyWith(
    scaffoldBackgroundColor: const Color(0xFF4E5450),
    textTheme: base.textTheme.apply(
      bodyColor: D.textPrimary,
      displayColor: D.textPrimary,
    ),
    splashFactory: InkRipple.splashFactory,
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Color(0xE6000000),
      contentTextStyle: TextStyle(color: Colors.white, fontSize: 14),
    ),
  );
}
