import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/api/auth_api.dart';
import '../../state/room_store.dart';
import '../../state/session_store.dart';
import '../widgets/common_widgets.dart';

/// 服务页（设计图 04服务）
///
/// 版式：居中标题 + 右上 SOS → 两个 1:1 玻璃卡片（图标/名称/开关） → 底部红描边"退出登录"
class ServiceTab extends StatefulWidget {
  const ServiceTab({super.key});

  @override
  State<ServiceTab> createState() => _ServiceTabState();
}

class _ServiceTabState extends State<ServiceTab> {
  bool _loggingOut = false;

  Future<void> _confirmSos() async {
    final RoomStore store = context.read<RoomStore>();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: const Color(0xF2292E2B),
        title: const Text('紧急求助', style: TextStyle(color: Colors.white)),
        content: const Text('将立即通知酒店前台，确认发送？',
            style: TextStyle(color: D.textSecondary)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消', style: TextStyle(color: D.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('立即发送', style: TextStyle(color: D.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await store.sendSos();
    }
  }

  Future<void> _logout() async {
    if (_loggingOut) {
      return;
    }
    setState(() => _loggingOut = true);
    final AuthApi authApi = context.read<AuthApi>();
    final SessionStore session = context.read<SessionStore>();
    try {
      await authApi.logout();
    } catch (_) {
      // 服务端无状态，退出接口失败也不影响本地清理
    }
    await session.logout();
    if (!mounted) {
      return;
    }
    setState(() => _loggingOut = false);
    AppRouter.toLogin();
  }

  @override
  Widget build(BuildContext context) {
    final RoomStore store = context.watch<RoomStore>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(D.page, 6, D.page, 0),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              const SizedBox(width: 64),
              const Expanded(
                child: Center(
                  child: Text(
                    '服务控制',
                    style:
                        TextStyle(fontSize: D.cardTitle, color: D.textPrimary),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _confirmSos,
                child: Container(
                  height: 32,
                  width: 64,
                  decoration: BoxDecoration(
                    color: D.danger,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Center(
                    child: Text(
                      'SOS',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: _ServiceCard(
                  label: '请勿打扰',
                  icon: Icons.block,
                  active: store.services.doNotDisturb,
                  onChanged: () =>
                      store.toggleService(ServiceKeys.doNotDisturb),
                ),
              ),
              const SizedBox(width: D.gap),
              Expanded(
                child: _ServiceCard(
                  label: '清理房间',
                  icon: Icons.cleaning_services,
                  active: store.services.cleaning,
                  onChanged: () => store.toggleService(ServiceKeys.cleaning),
                ),
              ),
            ],
          ),
          const Spacer(),
          Center(
            child: SizedBox(
              width: 196,
              child: PrimaryButton(
                compact: true,
                label: _loggingOut ? '正在退出…' : '退出登录',
                outlinedDanger: true,
                enabled: !_loggingOut,
                icon: const Icon(Icons.logout, size: 18, color: D.danger),
                onPressed: _logout,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// 1:1 玻璃卡片：图标 / 名称 / 开关 居中排列
class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.label,
    required this.icon,
    required this.active,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 196,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: glassDecoration(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 44, color: Colors.white),
            const SizedBox(height: 14),
            Text(label,
                style: const TextStyle(
                    fontSize: D.cardBody, color: D.textPrimary)),
            const SizedBox(height: 16),
            PillSwitch(
              value: active,
              width: 52,
              height: 28,
              onChanged: (_) => onChanged(),
            ),
          ],
        ),
      ),
    );
  }
}
