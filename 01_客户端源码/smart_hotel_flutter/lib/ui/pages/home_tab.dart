import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/room_models.dart';
import '../../state/room_store.dart';
import '../../state/session_store.dart';
import '../widgets/ac_card.dart';
import '../widgets/app_icons.dart';
import '../widgets/common_widgets.dart';
import '../widgets/glass.dart';

/// 首页（设计图 01首页）
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final RoomStore store = context.watch<RoomStore>();
    final SessionStore session = context.watch<SessionStore>();
    final String name = store.room.guestName.isNotEmpty
        ? store.room.guestName
        : (session.user?.guestName ?? '客人');
    final List<SceneItem> scenes = store.pickScenes(SceneIds.homeList);
    final bool goodnightOn = store.isSceneActive(SceneIds.goodnight);

    return ListView(
      padding: const EdgeInsets.fromLTRB(D.page, 6, D.page, 24),
      children: <Widget>[
        _Header(name: name, roomNo: store.room.roomNo),
        const SizedBox(height: D.gap),
        AcCard(
          ac: store.ac,
          onPower: store.toggleAcPower,
          onTempDelta: store.changeTargetTemp,
        ),
        const SectionHeader(title: '场景模式'),
        _Grid(
          items: scenes.map((SceneItem item) {
            return SceneTile(
              icon: Icon(_sceneIcon(item.id), size: 26, color: Colors.white),
              label: item.name,
              active: store.isSceneActive(item.id),
              onTap: () => store.applyScene(item.id),
            );
          }).toList(),
          gap: D.gap,
        ),
        const SectionHeader(title: '快捷服务'),
        Row(
          children: <Widget>[
            Expanded(
              child: _QuickService(
                label: '请勿打扰',
                icon: Icons.block,
                active: store.services.doNotDisturb,
                onTap: () => store.toggleService(ServiceKeys.doNotDisturb),
              ),
            ),
            const SizedBox(width: D.gap),
            Expanded(
              child: _QuickService(
                label: '清理房间',
                icon: Icons.cleaning_services,
                active: store.services.cleaning,
                onTap: () => store.toggleService(ServiceKeys.cleaning),
              ),
            ),
          ],
        ),
        const SizedBox(height: D.gap),
        _Goodnight(
          active: goodnightOn,
          onTap: store.toggleGoodnight,
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

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.roomNo});

  final String name;
  final String roomNo;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                '智慧客房',
                style: TextStyle(
                  fontSize: D.pageTitle,
                  fontWeight: FontWeight.w600,
                  color: D.textPrimary,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$name，欢迎回家。',
                style: const TextStyle(fontSize: 15, color: D.textPrimary),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: glassDecoration(radius: 10),
          child: Text(
            '房号 ${roomNo.isEmpty ? '--' : roomNo}',
            style: const TextStyle(fontSize: D.tiny, color: D.textPrimary),
          ),
        ),
      ],
    );
  }
}

/// 两列网格（设计图列宽 196dp、间距 16dp）
class _Grid extends StatelessWidget {
  const _Grid({required this.items, required this.gap});

  final List<Widget> items;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < items.length; i += 2) {
      final Widget left = items[i];
      final Widget? right = i + 1 < items.length ? items[i + 1] : null;
      rows.add(
        Row(
          children: <Widget>[
            Expanded(child: left),
            SizedBox(width: gap),
            Expanded(child: right ?? const SizedBox()),
          ],
        ),
      );
      if (i + 2 < items.length) {
        rows.add(SizedBox(height: gap));
      }
    }
    return Column(children: rows);
  }
}

class _QuickService extends StatelessWidget {
  const _QuickService({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 82,
        padding: const EdgeInsets.all(12),
        decoration: glassDecoration(
          color: active ? D.accent : D.glass,
          borderColor: active ? D.accent : D.glassBorder,
        ),
        child: Row(
          children: <Widget>[
            GlassTile(
              size: 56,
              radius: 18,
              color: active ? const Color(0x33FFFFFF) : D.glassStrong,
              child: Icon(icon, size: 26, color: Colors.white),
            ),
            const SizedBox(width: 10),
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

class _Goodnight extends StatelessWidget {
  const _Goodnight({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 78,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: glassDecoration(
          color: active ? D.accent : D.glass,
          borderColor: active ? D.accent : D.glassBorder,
        ),
        child: Row(
          children: <Widget>[
            GlassTile(
              size: 52,
              shape: BoxShape.circle,
              color: active ? const Color(0x33FFFFFF) : D.glassStrong,
              child: const Icon(Icons.bedtime, size: 26, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '晚安模式',
                    style:
                        TextStyle(fontSize: D.cardBody, color: D.textPrimary),
                  ),
                  SizedBox(height: 3),
                  Text(
                    '一键关闭所有灯光',
                    style: TextStyle(fontSize: D.tiny, color: D.textSecondary),
                  ),
                ],
              ),
            ),
            const EyelashIcon(size: 30, color: D.textPrimary),
          ],
        ),
      ),
    );
  }
}
