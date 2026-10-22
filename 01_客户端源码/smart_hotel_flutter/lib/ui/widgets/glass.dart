import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// 全屏背景：客房实景照片 + 轻压暗
///
/// 素材来自 UI 素材包 `4.配图/img_raw.png`（2400×2400 原图），
/// 按视频背景的观感重新导出：竖版 1080 宽、中度模糊（能看出窗与床头轮廓）、
/// 整体亮度抬到与演示视频同档，比早期那张重模糊的灰度底图亮一档、也清楚一档。
///
/// 登录页用的是同源的**冷色调**版本（bg_login.jpg）：压红、提蓝，
/// 对齐视频登录页那种蓝灰冷调。
class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    this.child,
    this.scrim = D.scrim,
    this.asset = 'assets/images/bg_hotel.jpg',
  });

  final Widget? child;
  final Color scrim;
  final String asset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Image.asset(
          asset,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
        ),
        ColoredBox(color: scrim),
        if (child != null) child!,
      ],
    );
  }
}

/// 玻璃卡片：内容后面实时模糊背景
///
/// 设计图里所有卡片都是"半透明白 + 背景模糊 + 1px 描边"，
/// 用 BackdropFilter 而不是静态半透明色，才能在照片背景上得到同样的通透感。
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(D.gap),
    this.radius = D.radiusCard,
    this.color = D.glass,
    this.borderColor = D.glassBorder,
    this.blur = true,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;
  final Color borderColor;
  final bool blur;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius borderRadius = BorderRadius.circular(radius);

    Widget content = Container(
      padding: padding,
      decoration: glassDecoration(
          color: color, borderColor: borderColor, radius: radius),
      child: child,
    );

    if (blur) {
      content = BackdropFilter(filter: glassBlur(), child: content);
    }

    content = ClipRRect(borderRadius: borderRadius, child: content);

    if (onTap != null) {
      content = GestureDetector(
          behavior: HitTestBehavior.opaque, onTap: onTap, child: content);
    }
    return content;
  }
}

/// 卡片内的小图标底座（圆角方块）
class GlassTile extends StatelessWidget {
  const GlassTile({
    super.key,
    required this.child,
    this.size = 52,
    this.radius = D.radiusTile,
    this.color = D.glassStrong,
    this.shape = BoxShape.rectangle,
  });

  final Widget child;
  final double size;
  final double radius;
  final Color color;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: shape,
        borderRadius:
            shape == BoxShape.circle ? null : BorderRadius.circular(radius),
      ),
      child: child,
    );
  }
}
