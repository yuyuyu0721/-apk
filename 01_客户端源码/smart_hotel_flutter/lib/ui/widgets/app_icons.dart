import 'package:flutter/material.dart';

/// 设计图里的自绘图标
///
/// 有几个图形在 Material Icons 里找不到对应（空调出风口、窗帘开合符号），
/// 用 CustomPainter 按设计图的线条重绘，避免用近似图标破坏一致性。

/// 空调出风口：圆角矩形 + 内部横槽 + 三条支腿
class AcUnitIcon extends StatelessWidget {
  const AcUnitIcon({super.key, this.size = 24, this.color = Colors.white});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _AcUnitPainter(color),
    );
  }
}

class _AcUnitPainter extends CustomPainter {
  _AcUnitPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.075
      ..strokeCap = StrokeCap.round;

    final double w = size.width;
    final double h = size.height;
    final Rect body = Rect.fromLTWH(w * 0.10, h * 0.16, w * 0.80, h * 0.34);
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, Radius.circular(w * 0.06)),
      stroke,
    );
    // 出风口横槽
    canvas.drawLine(
      Offset(w * 0.22, h * 0.32),
      Offset(w * 0.78, h * 0.32),
      stroke,
    );
    // 三条支腿
    for (final double x in <double>[0.22, 0.50, 0.78]) {
      canvas.drawLine(Offset(w * x, h * 0.52), Offset(w * x, h * 0.76), stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _AcUnitPainter old) => old.color != color;
}

/// 窗帘开合符号：两根竖杆 + 顶部横杆
///   opened = true  两杆向外、顶部横杆断开（打开）
///   opened = false 两杆向内、顶部横杆贯通（关闭）
class CurtainIcon extends StatelessWidget {
  const CurtainIcon({
    super.key,
    required this.opened,
    this.size = 22,
    this.color = Colors.white,
  });

  final bool opened;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CurtainPainter(color, opened),
    );
  }
}

class _CurtainPainter extends CustomPainter {
  _CurtainPainter(this.color, this.opened);

  final Color color;
  final bool opened;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.09
      ..strokeCap = StrokeCap.round;

    final double w = size.width;
    final double h = size.height;
    final double top = h * 0.16;
    final double bottom = h * 0.86;

    if (opened) {
      // 两杆靠外，顶部横杆分成两段
      final double leftX = w * 0.16;
      final double rightX = w * 0.84;
      canvas.drawLine(Offset(leftX, top), Offset(leftX, bottom), stroke);
      canvas.drawLine(Offset(rightX, top), Offset(rightX, bottom), stroke);
      canvas.drawLine(Offset(leftX, top), Offset(w * 0.34, top), stroke);
      canvas.drawLine(Offset(w * 0.66, top), Offset(rightX, top), stroke);
    } else {
      final double leftX = w * 0.34;
      final double rightX = w * 0.66;
      canvas.drawLine(Offset(leftX, top), Offset(leftX, bottom), stroke);
      canvas.drawLine(Offset(rightX, top), Offset(rightX, bottom), stroke);
      canvas.drawLine(Offset(leftX, top), Offset(rightX, top), stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _CurtainPainter old) =>
      old.color != color || old.opened != opened;
}

/// 暂停符号：两条竖杠
class PauseIcon extends StatelessWidget {
  const PauseIcon({super.key, this.size = 22, this.color = Colors.white});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _PausePainter(color));
  }
}

class _PausePainter extends CustomPainter {
  _PausePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.round;
    final double w = size.width;
    final double h = size.height;
    canvas.drawLine(
        Offset(w * 0.38, h * 0.18), Offset(w * 0.38, h * 0.82), stroke);
    canvas.drawLine(
        Offset(w * 0.62, h * 0.18), Offset(w * 0.62, h * 0.82), stroke);
  }

  @override
  bool shouldRepaint(covariant _PausePainter old) => old.color != color;
}

/// 横线 / 十字（空调加减按钮）
class MinusPlusIcon extends StatelessWidget {
  const MinusPlusIcon(
      {super.key,
      required this.plus,
      this.size = 22,
      this.color = Colors.white});

  final bool plus;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
        size: Size(size, size), painter: _MinusPlusPainter(color, plus));
  }
}

class _MinusPlusPainter extends CustomPainter {
  _MinusPlusPainter(this.color, this.plus);

  final Color color;
  final bool plus;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.085
      ..strokeCap = StrokeCap.round;
    final double w = size.width;
    final double h = size.height;
    canvas.drawLine(
        Offset(w * 0.12, h * 0.5), Offset(w * 0.88, h * 0.5), stroke);
    if (plus) {
      canvas.drawLine(
          Offset(w * 0.5, h * 0.12), Offset(w * 0.5, h * 0.88), stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _MinusPlusPainter old) =>
      old.color != color || old.plus != plus;
}

/// 闭眼（睫毛）图标：首页"晚安模式"右侧用
class EyelashIcon extends StatelessWidget {
  const EyelashIcon({super.key, this.size = 26, this.color = Colors.white});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
        size: Size(size, size * 0.62), painter: _EyelashPainter(color));
  }
}

class _EyelashPainter extends CustomPainter {
  _EyelashPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.042
      ..strokeCap = StrokeCap.round;

    final double w = size.width;
    final double h = size.height;

    // 二次贝塞尔参数点
    final Offset p0 = Offset(w * 0.04, h * 0.28);
    final Offset p1 = Offset(w * 0.5, h * 0.86);
    final Offset p2 = Offset(w * 0.96, h * 0.28);

    Offset at(double t) {
      final double u = 1 - t;
      return Offset(
        u * u * p0.dx + 2 * u * t * p1.dx + t * t * p2.dx,
        u * u * p0.dy + 2 * u * t * p1.dy + t * t * p2.dy,
      );
    }

    // 眼睑弧
    final Path lid = Path()
      ..moveTo(p0.dx, p0.dy)
      ..quadraticBezierTo(p1.dx, p1.dy, p2.dx, p2.dy);
    canvas.drawPath(lid, stroke);

    // 睫毛：沿弧线均布，向外（下方）发散
    for (final double t in <double>[0.12, 0.31, 0.5, 0.69, 0.88]) {
      final Offset point = at(t);
      final double spread = (t - 0.5) * w * 0.16;
      canvas.drawLine(
        point,
        Offset(point.dx + spread, point.dy + h * 0.34),
        stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EyelashPainter old) => old.color != color;
}

/// 吸顶灯符号（导航"灯光"用）：半圆灯罩 + 底座横条
///
/// Material 里的 lightbulb 是灯泡剪影，视频导航用的是吸顶灯罩，
/// 画一个实心半圆 + 下方横条来对齐。
class DomeLightIcon extends StatelessWidget {
  const DomeLightIcon({super.key, this.size = 21, this.color = Colors.white});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _DomeLightPainter(color),
    );
  }
}

class _DomeLightPainter extends CustomPainter {
  _DomeLightPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final double w = size.width;
    final double h = size.height;

    // 灯罩：上半圆
    final Rect dome = Rect.fromLTRB(w * 0.14, h * 0.20, w * 0.86, h * 0.92);
    canvas.drawArc(dome, 3.1415926, 3.1415926, true, fill);

    // 底座横条
    canvas.drawRRect(
      RRect.fromLTRBR(
        w * 0.30,
        h * 0.90,
        w * 0.70,
        h * 0.98,
        Radius.circular(w * 0.04),
      ),
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _DomeLightPainter old) => old.color != color;
}

/// 百叶/窗帘符号（导航"窗帘"用）：上下两道横杆 + 三根竖向叶片
///
/// 参考图里是"上横杆+下横杆+三条竖片"，Material 的 blinds 是横向百叶，
/// 形状对不上，这里按参考图画。
class BlindsIcon extends StatelessWidget {
  const BlindsIcon({super.key, this.size = 21, this.color = Colors.white});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _BlindsPainter(color),
    );
  }
}

class _BlindsPainter extends CustomPainter {
  _BlindsPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final double w = size.width;
    final double h = size.height;

    // 上下横杆
    canvas.drawRRect(
      RRect.fromLTRBR(w * 0.08, h * 0.16, w * 0.92, h * 0.26,
          Radius.circular(w * 0.05)),
      fill,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(w * 0.08, h * 0.74, w * 0.92, h * 0.84,
          Radius.circular(w * 0.05)),
      fill,
    );
    // 三根竖向叶片
    for (final double cx in <double>[0.26, 0.5, 0.74]) {
      canvas.drawRRect(
        RRect.fromLTRBR(w * (cx - 0.055), h * 0.24, w * (cx + 0.055),
            h * 0.76, Radius.circular(w * 0.03)),
        fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BlindsPainter old) => old.color != color;
}

/// 四宫格符号（导航"服务"用）：2×2 四个实心圆点
///
/// 参考图是四个圆点，Material 的 grid_view 是四个圆角方块，故自绘。
class ServiceGridIcon extends StatelessWidget {
  const ServiceGridIcon({super.key, this.size = 21, this.color = Colors.white});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ServiceGridPainter(color),
    );
  }
}

class _ServiceGridPainter extends CustomPainter {
  _ServiceGridPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final double w = size.width;
    final double h = size.height;
    const List<double> xs = <double>[0.28, 0.72];
    const List<double> ys = <double>[0.28, 0.72];
    for (final double x in xs) {
      for (final double y in ys) {
        canvas.drawCircle(Offset(w * x, h * y), w * 0.17, fill);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ServiceGridPainter old) => old.color != color;
}
