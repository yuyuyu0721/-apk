import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'glass.dart';

/// 区块标题（"场景模式" / "快捷服务"），设计图 20sp、白色、页边距对齐
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.top = 24});

  final String title;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: D.cardTitle,
          fontWeight: FontWeight.w500,
          color: D.textPrimary,
          height: 1.2,
        ),
      ),
    );
  }
}

/// 胶囊开关：关=半透明白轨道，开=主色轨道；白色滑块
class PillSwitch extends StatelessWidget {
  const PillSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.width = 48,
    this.height = 26,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final double knob = height - 6;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: width,
        height: height,
        padding: const EdgeInsets.all(3),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: value ? D.accent : const Color(0x40FFFFFF),
          borderRadius: BorderRadius.circular(height / 2),
        ),
        child: Container(
          width: knob,
          height: knob,
          decoration:
              const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

/// 首页场景卡：80dp 高，圆角 20，内含 52dp 图标底座
class SceneTile extends StatelessWidget {
  const SceneTile({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: glassDecoration(
          color: active ? D.accent : D.glass,
          borderColor: active ? D.accent : D.glassBorder,
          radius: D.radiusCard,
        ),
        child: Row(
          children: <Widget>[
            GlassTile(
              size: 52,
              color: active ? const Color(0x33FFFFFF) : D.glassStrong,
              child: icon,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: D.cardBody, color: D.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 灯光页场景条：45dp 高，圆角 14
class SceneChip extends StatelessWidget {
  const SceneChip({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 45,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: glassDecoration(
          color: active ? D.accent : D.glass,
          borderColor: active ? D.accent : D.glassBorder,
          radius: D.radiusChip,
        ),
        child: Row(
          children: <Widget>[
            icon,
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: D.label, color: D.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 窗帘动作按钮：图标底座 + 下方文字
class ActionTile extends StatelessWidget {
  const ActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 58,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? D.accent : const Color(0x26FFFFFF),
              borderRadius: BorderRadius.circular(D.radiusChip),
            ),
            child: icon,
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(fontSize: D.label, color: D.textPrimary)),
        ],
      ),
    );
  }
}

/// 主按钮：56dp 高、胶囊；outlinedDanger 用于"退出登录"红描边样式
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.enabled = true,
    this.outlinedDanger = false,
    this.icon,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  /// 服务页"退出登录"：红描边 + 红字
  final bool outlinedDanger;
  final Widget? icon;

  /// 紧凑尺寸（服务页"退出登录" 44dp）
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onPressed : null,
        child: Container(
          height: compact ? 44 : 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: outlinedDanger ? Colors.transparent : D.accent,
            borderRadius: BorderRadius.circular(D.radiusPill),
            border:
                outlinedDanger ? Border.all(color: D.danger, width: 1.2) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[icon!, const SizedBox(width: 8)],
              Text(
                label,
                style: TextStyle(
                  fontSize: compact ? 16 : 18,
                  fontWeight: FontWeight.w500,
                  color: outlinedDanger ? D.danger : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 全屏加载遮罩
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0x66000000),
      child: Center(
        child: SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
        ),
      ),
    );
  }
}
