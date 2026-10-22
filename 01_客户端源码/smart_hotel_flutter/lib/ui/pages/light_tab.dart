import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/room_models.dart';
import '../../state/room_store.dart';
import '../widgets/common_widgets.dart';
import '../widgets/glass.dart';

/// 灯光页（设计图 02灯光）
///
/// 结构：居中标题 → 100dp 总开关方块 → "场景模式"卡片（2 列） → "独立控制"卡片（2 列 9 盏灯）
class LightTab extends StatelessWidget {
  const LightTab({super.key});

  @override
  Widget build(BuildContext context) {
    final RoomStore store = context.watch<RoomStore>();
    final List<SceneItem> scenes = store.pickScenes(SceneIds.lightList);

    return ListView(
      padding: const EdgeInsets.fromLTRB(D.page, 6, D.page, 24),
      children: <Widget>[
        const Center(
          child: Text(
            '灯光控制',
            style: TextStyle(
                fontSize: D.cardTitle, color: D.textPrimary, height: 1.4),
          ),
        ),
        const SizedBox(height: 16),
        _MasterSwitch(on: store.masterLight, onChanged: store.setMasterLight),
        const SizedBox(height: 22),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                '场景模式',
                style: TextStyle(fontSize: D.cardTitle, color: D.textPrimary),
              ),
              const SizedBox(height: 12),
              _TwoColumn(
                gap: D.gap,
                rowGap: 20,
                children: scenes.map((SceneItem item) {
                  return SceneChip(
                    icon: Icon(_sceneIcon(item.id),
                        size: 20, color: Colors.white),
                    label: item.name,
                    active: store.isSceneActive(item.id),
                    onTap: () => store.applyScene(item.id),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: D.gap),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                '独立控制',
                style: TextStyle(fontSize: D.cardTitle, color: D.textPrimary),
              ),
              const SizedBox(height: 8),
              _TwoColumn(
                gap: 10,
                rowGap: 0,
                children: store.lights.map((LightItem light) {
                  return _LightRow(light: light, onToggle: store.toggleLight);
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _sceneIcon(String id) {
    switch (id) {
      case SceneIds.bright:
        return Icons.wb_sunny_outlined;
      case SceneIds.soft:
        return Icons.nightlight_round;
      case SceneIds.reading:
        return Icons.menu_book;
      case SceneIds.cozy:
        return Icons.favorite;
      default:
        return Icons.bedtime;
    }
  }
}

class _MasterSwitch extends StatelessWidget {
  const _MasterSwitch({required this.on, required this.onChanged});

  final bool on;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(!on),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: on ? D.accent : D.glass,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: on ? const Color(0x59FFFFFF) : D.glassBorder,
                width: on ? 1.5 : 1,
              ),
            ),
            child: const Icon(Icons.power_settings_new,
                size: 40, color: Colors.white),
          ),
        ),
        const SizedBox(height: 10),
        const Text('总开关', style: TextStyle(fontSize: 15, color: D.textPrimary)),
      ],
    );
  }
}

class _LightRow extends StatelessWidget {
  const _LightRow({required this.light, required this.onToggle});

  final LightItem light;
  final void Function(LightItem light) onToggle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: Row(
        children: <Widget>[
          Icon(_icon(light.id), size: 18, color: D.textPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              light.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: D.label, color: D.textPrimary),
            ),
          ),
          PillSwitch(
            value: light.on,
            onChanged: (bool value) {
              if (value != light.on) {
                onToggle(light);
              }
            },
          ),
        ],
      ),
    );
  }

  IconData _icon(String id) {
    switch (id) {
      case 'bath':
        return Icons.water_drop_outlined;
      case 'wardrobe':
        return Icons.checkroom;
      case 'floor':
        return Icons.light;
      case 'bar':
        return Icons.local_bar_outlined;
      case 'readLeft':
      case 'readRight':
        return Icons.menu_book_outlined;
      case 'desk':
        return Icons.table_bar_outlined;
      case 'fan':
        return Icons.air;
      default:
        return Icons.lightbulb_outline;
    }
  }
}

/// 两列布局（行内元素高度由各自决定）
class _TwoColumn extends StatelessWidget {
  const _TwoColumn({
    required this.children,
    required this.gap,
    this.rowGap = 12,
  });

  final List<Widget> children;
  final double gap;
  final double rowGap;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < children.length; i += 2) {
      final Widget left = children[i];
      final Widget? right = i + 1 < children.length ? children[i + 1] : null;
      rows.add(
        Row(
          children: <Widget>[
            Expanded(child: left),
            SizedBox(width: gap),
            Expanded(child: right ?? const SizedBox()),
          ],
        ),
      );
      if (i + 2 < children.length) {
        rows.add(SizedBox(height: rowGap));
      }
    }
    return Column(children: rows);
  }
}
