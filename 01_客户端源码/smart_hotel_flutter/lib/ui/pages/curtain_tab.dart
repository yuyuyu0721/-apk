import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/room_models.dart';
import '../../state/room_store.dart';
import '../widgets/app_icons.dart';
import '../widgets/curtain_panel.dart';

/// 窗帘页（设计图 03窗帘 / 03窗帘_opening）
class CurtainTab extends StatelessWidget {
  const CurtainTab({super.key});

  String _statusOf(RoomStore store, String id) {
    final CurtainItem? item = store.findCurtain(id);
    return item?.status ?? CurtainStatus.closed;
  }

  /// 是否所有窗帘都处于同一状态（空列表不算）
  bool _allAre(RoomStore store, String status) {
    return store.curtains.isNotEmpty &&
        store.curtains.every((CurtainItem item) => item.status == status);
  }

  /// 批量按钮跟随实际状态：全部打开 → "全部打开"亮；全部关闭 → "全部关闭"亮；
  /// 有暂停或一开一关的混合态 → 两个都不亮。
  /// 这样既不会两个一起亮，也保证状态与高亮始终一致。
  bool _batchActive(RoomStore store, String action) {
    return _allAre(
      store,
      action == CurtainActions.open
          ? CurtainStatus.opened
          : CurtainStatus.closed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final RoomStore store = context.watch<RoomStore>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(D.page, 6, D.page, 24),
      children: <Widget>[
        const Center(
          child: Text(
            '窗帘控制',
            style: TextStyle(
                fontSize: D.cardTitle, color: D.textPrimary, height: 1.4),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: _BatchButton(
                key: const ValueKey<String>('curtain-batch-open'),
                label: '全部打开',
                opened: true,
                highlighted: _batchActive(store, CurtainActions.open),
                onTap: () => store.batchCurtain(CurtainActions.open),
              ),
            ),
            const SizedBox(width: D.gap),
            Expanded(
              child: _BatchButton(
                key: const ValueKey<String>('curtain-batch-close'),
                label: '全部关闭',
                opened: false,
                highlighted: _batchActive(store, CurtainActions.close),
                onTap: () => store.batchCurtain(CurtainActions.close),
              ),
            ),
          ],
        ),
        const SizedBox(height: D.gap),
        CurtainPanel(
          name: '布帘',
          isSheer: false,
          status: _statusOf(store, CurtainIds.cloth),
          onAction: (String action) =>
              store.controlCurtain(CurtainIds.cloth, action),
        ),
        const SizedBox(height: D.gap),
        CurtainPanel(
          name: '窗纱',
          isSheer: true,
          status: _statusOf(store, CurtainIds.sheer),
          onAction: (String action) =>
              store.controlCurtain(CurtainIds.sheer, action),
        ),
      ],
    );
  }
}

class _BatchButton extends StatelessWidget {
  const _BatchButton({
    super.key,
    required this.label,
    required this.opened,
    required this.highlighted,
    required this.onTap,
  });

  final String label;
  final bool opened;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 49,
        alignment: Alignment.center,
        decoration: glassDecoration(
          color: highlighted ? D.accent : D.glass,
          borderColor: highlighted ? D.accent : D.glassBorder,
          radius: D.radiusChip,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CurtainIcon(opened: opened, size: 20, color: Colors.white),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(fontSize: D.label, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
