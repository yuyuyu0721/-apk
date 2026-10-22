import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import 'app_icons.dart';
import 'common_widgets.dart';

/// 单组窗帘面板
///
/// 后端只返回 opened / paused / closed 三态，没有位置量，
/// 开合过程由本地 AnimationController 补间；paused 时直接停在当前进度。
///
/// 织物用 CustomPainter 画竖向褶皱（设计图是实物纹理，这里用同色系明暗条纹还原）：
///   布帘 #999854 系，窗纱 #F2F2EE 系。
class CurtainPanel extends StatefulWidget {
  const CurtainPanel({
    super.key,
    required this.name,
    required this.status,
    required this.isSheer,
    required this.onAction,
  });

  final String name;
  final String status;

  /// true = 窗纱（白色细褶皱），false = 布帘（橄榄色粗褶皱）
  final bool isSheer;
  final ValueChanged<String> onAction;

  @override
  State<CurtainPanel> createState() => _CurtainPanelState();
}

class _CurtainPanelState extends State<CurtainPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
    value: _statusToValue(widget.status),
  );

  static double _statusToValue(String status) {
    switch (status) {
      case CurtainStatus.opened:
        return 1;
      case CurtainStatus.paused:
        return 0.5;
      default:
        return 0;
    }
  }

  @override
  void initState() {
    super.initState();
    _syncToStatus();
  }

  @override
  void didUpdateWidget(covariant CurtainPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      _syncToStatus();
    }
  }

  void _syncToStatus() {
    switch (widget.status) {
      case CurtainStatus.opened:
        _controller.forward();
        break;
      case CurtainStatus.closed:
        _controller.reverse();
        break;
      default:
        // paused：停在当前进度，不归位
        _controller.stop();
        break;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isActionActive(String action) {
    switch (action) {
      case CurtainActions.open:
        return widget.status == CurtainStatus.opened;
      case CurtainActions.pause:
        return widget.status == CurtainStatus.paused;
      default:
        return widget.status == CurtainStatus.closed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(D.gap),
      decoration: glassDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            widget.name,
            style: const TextStyle(fontSize: D.cardBody, color: D.textPrimary),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 146,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (BuildContext context, Widget? child) {
                  return CustomPaint(
                    painter: _CurtainPainter(
                      progress: _controller.value,
                      sheer: widget.isSheer,
                    ),
                    child: const SizedBox.expand(),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              ActionTile(
                icon: CurtainIcon(
                  opened: true,
                  size: 20,
                  color: _isActionActive(CurtainActions.open)
                      ? Colors.white
                      : D.textPrimary,
                ),
                label: '打开',
                active: _isActionActive(CurtainActions.open),
                onTap: () => widget.onAction(CurtainActions.open),
              ),
              ActionTile(
                icon: PauseIcon(
                  size: 20,
                  color: _isActionActive(CurtainActions.pause)
                      ? Colors.white
                      : D.textPrimary,
                ),
                label: '暂停',
                active: _isActionActive(CurtainActions.pause),
                onTap: () => widget.onAction(CurtainActions.pause),
              ),
              ActionTile(
                icon: CurtainIcon(
                  opened: false,
                  size: 20,
                  color: _isActionActive(CurtainActions.close)
                      ? Colors.white
                      : D.textPrimary,
                ),
                label: '关闭',
                active: _isActionActive(CurtainActions.close),
                onTap: () => widget.onAction(CurtainActions.close),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 窗帘织物
///
/// 结构（对照设计图 03窗帘_opening 与演示视频 00:46-01:12）：
///   顶部一根浅灰白细杆 → 杆与布料之间留空隙（空隙里透出深色窗景）
///   → 左右两片布料垂下，关闭态中间留一条中缝
///
/// 材质：每片布由细密竖褶皱组成 —— 每条褶皱"暗边—亮面—暗边"三段，
/// 相邻褶皱明暗交替，叠加大尺度受光起伏；下摆是随褶皱周期起伏的扇贝形。
///
/// 开合动画的关键是"布料守恒"：褶皱总数按关闭态宽度定死，
/// 收拢/展开时每条褶皱**等分铺满整片宽度**（收拢变密、展开变疏），
/// 任何中间态布片都平整铺满、边缘整齐；
/// 完全打开时两侧保留一段密集堆叠（约 11% 面板宽），而不是缩成一条缝。
class _CurtainPainter extends CustomPainter {
  _CurtainPainter({required this.progress, required this.sheer});

  final double progress;
  final bool sheer;

  static const double rodY = 4;
  static const double rodThickness = 3;

  /// 杆与布料之间的空隙：布料吊在杆子下方，不贴杆
  static const double rodGap = 10;

  /// 关闭态左右两片之间的中缝
  static const double centerGap = 4;

  /// 一条褶皱在关闭态的宽度（决定褶皱总数）
  ///
  /// 用户反馈 6.2dp 仍然偏密，再放宽一档：布帘 8.4dp、窗纱 6.8dp。
  double get foldWidth => sheer ? 6.8 : 8.4;

  /// 完全打开时两侧堆叠的宽度：收起来要"小一点"，约 7% 面板宽
  static double stackWidth(double panelWidth) =>
      math.max(22, panelWidth * 0.07);

  /// 杆底（空隙从这里开始）
  static const double railBottom = rodY + rodThickness;

  /// 布料顶边
  static const double fabricTop = railBottom + rodGap;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 窗：从杆底一直铺到底，杆与布之间的空隙透出的是窗景（深色），
    // 这样杆子和布料之间才有"隔了一条缝"的层次，而不是贴在卡片底色上。
    _drawWindow(canvas, Rect.fromLTWH(0, railBottom, w, h - railBottom));

    // 两片布：progress=0 关闭（各占半宽留中缝），progress=1 全开（两侧各剩堆叠）
    final double half = (w - centerGap) / 2;
    final double stack = stackWidth(w);
    final double panelW = stack + (half - stack) * (1 - progress);
    final int maxFolds = math.max(8, (half / foldWidth).round());

    _drawFabric(
      canvas,
      Rect.fromLTWH(0, fabricTop, panelW, h - fabricTop),
      maxFolds,
    );
    _drawFabric(
      canvas,
      Rect.fromLTWH(w - panelW, fabricTop, panelW, h - fabricTop),
      maxFolds,
    );

    // 杆在布料之上，杆下再压一道阴影落在空隙里
    _drawRod(canvas, size);
  }

  void _drawWindow(Canvas canvas, Rect rect) {
    canvas.drawRect(rect, Paint()..color = const Color(0x3D2F3A38));
    // 左右压暗，模拟室内纵深，让中间的窗更"透"
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[
            Color(0x40000000),
            Color(0x00000000),
            Color(0x40000000),
          ],
        ).createShader(rect),
    );
  }

  /// 杆：浅灰白细杆（设计图里是金属导轨质感）+ 顶部一线高光 + 下方淡投影
  void _drawRod(Canvas canvas, Size size) {
    final Color rodColor =
        sheer ? const Color(0xFFE2E1D8) : const Color(0xFFD9D8CE);
    final Rect rod = Rect.fromLTWH(2, rodY, size.width - 4, rodThickness);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rod, const Radius.circular(1.5)),
      Paint()..color = rodColor,
    );
    // 顶部高光：让杆子从布料里"跳"出来
    canvas.drawRect(
      Rect.fromLTWH(rod.left + 1, rod.top + 0.6, rod.width - 2, 0.9),
      Paint()..color = const Color(0xCCFFFFFF),
    );
    // 杆下投影：落在杆与布之间的空隙上
    canvas.drawRect(
      Rect.fromLTWH(rod.left, rod.bottom, rod.width, 2.5),
      Paint()..color = const Color(0x26000000),
    );
  }

  /// 一片布：细密竖褶皱等分铺满整个 rect，边缘永远整齐
  void _drawFabric(Canvas canvas, Rect rect, int maxFolds) {
    // 布帘橄榄绿系 / 窗纱白灰系（取自设计图 03窗帘_opening）
    final Color light =
        sheer ? const Color(0xFFFBFAF6) : const Color(0xFFCFC87A);
    final Color mid = sheer ? const Color(0xFFEFEEE7) : const Color(0xFFA29F68);
    final Color dark =
        sheer ? const Color(0xFFD8D7CF) : const Color(0xFF85824C);

    canvas.save();
    canvas.clipRect(rect);

    if (rect.width > 0.5) {
      // 褶皱数守恒；堆叠处过密时给最小褶皱宽度兜底，避免糊成一团
      final int folds =
          math.max(3, math.min(maxFolds, (rect.width / 2.6).floor()));
      final double stripeW = rect.width / folds;

      for (int i = 0; i < folds; i++) {
        final double x = rect.left + i * stripeW;
        // 大尺度受光起伏（按归一化布料坐标，动画中不闪）
        final double u = folds == 1 ? 0.5 : i / (folds - 1);
        final double wave = (math.sin(u * math.pi * 2.2 + 0.6) + 1) / 2;
        final Color faceColor =
            Color.lerp(mid, light, (0.35 + 0.65 * wave).clamp(0.0, 1.0))!;

        // 下摆：相邻褶皱一高一低，形成细密的锯齿形布边
        final double hem = 1.6 + 1.6 * (i.isEven ? 0 : 1);
        final Rect fold = Rect.fromLTWH(
          x,
          rect.top,
          stripeW + 0.5,
          rect.height - hem,
        );
        // 每条褶皱内部横向渐变：暗谷 → 亮脊 → 暗谷，得到平滑的圆柱受光
        canvas.drawRect(
          fold,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: <Color>[dark, faceColor, dark],
              stops: const <double>[0.0, 0.5, 1.0],
            ).createShader(fold),
        );
      }

      // 顶部略亮、底部略暗，模拟织物受光
      canvas.drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0x18FFFFFF),
              Color(0x00000000),
              Color(0x18000000),
            ],
          ).createShader(rect),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CurtainPainter old) =>
      old.progress != progress || old.sheer != sheer;
}
