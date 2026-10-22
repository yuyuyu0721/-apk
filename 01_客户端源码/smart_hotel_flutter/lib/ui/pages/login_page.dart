import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/api/auth_api.dart';
import '../../data/models/room_models.dart';
import '../../state/session_store.dart';
import '../widgets/app_toast.dart';
import '../widgets/common_widgets.dart';
import '../widgets/glass.dart';

/// 登录页（设计图 00登录）
///
/// 版式：模糊客房背景 → 大标题 → 两个白色胶囊输入框 → 记住我的信息 → 橄榄色胶囊按钮 → 底部两行文案。
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final TextEditingController _roomController;
  late final TextEditingController _nameController;
  bool _remember = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final ({String roomNo, String guestName})? account =
        context.read<SessionStore>().rememberedAccount;
    // 设计图为空表单态；只有"记住我的信息"存过账号才回填
    _roomController = TextEditingController(text: account?.roomNo ?? '');
    _nameController = TextEditingController(text: account?.guestName ?? '');
    _remember = account != null;
  }

  @override
  void dispose() {
    _roomController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }
    final String roomNo = _roomController.text.trim();
    final String guestName = _nameController.text.trim();

    if (roomNo.isEmpty) {
      setState(() => _error = '请输入房间号');
      return;
    }
    if (guestName.isEmpty) {
      setState(() => _error = '请输入姓名');
      return;
    }

    final AuthApi authApi = context.read<AuthApi>();
    final SessionStore session = context.read<SessionStore>();

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final LoginResult result =
          await authApi.login(roomNo: roomNo, guestName: guestName);
      await session.save(
          token: result.token, user: result.userInfo, remember: _remember);
      if (!mounted) {
        return;
      }
      AppToast.show('登录成功');
      AppRouter.toMain();
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _error = e.message);
      AppToast.show(e.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _error = '登录失败，请稍后重试');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3E4A4C),
      body: AppBackground(
        // 登录页用同源的冷色调背景（对照视频登录页的蓝灰冷调）
        asset: 'assets/images/bg_login.jpg',
        scrim: const Color(0x1A0B1F26),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              // 顶部留白按屏高比例收缩（设计图 440×952 上为 148dp）
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints c) {
                  final double h = c.maxHeight;
                  final double topGap = (h * 0.155).clamp(40.0, 148.0);
                  final double titleGap = (h * 0.055).clamp(24.0, 52.0);
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Column(
                        children: <Widget>[
                          SizedBox(height: topGap),
                          const Text(
                            '智慧客房',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: D.hero,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 3,
                              color: D.textPrimary,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            '深圳技能竞赛',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 18,
                                letterSpacing: 1,
                                color: D.textPrimary),
                          ),
                          SizedBox(height: titleGap),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 48),
                            child: Column(
                              children: <Widget>[
                                _LoginField(
                                  controller: _roomController,
                                  hint: '请输入房号',
                                  icon: Icons.badge_outlined,
                                  numeric: true,
                                ),
                                const SizedBox(height: D.gap),
                                _LoginField(
                                  controller: _nameController,
                                  hint: '请输入姓名',
                                  icon: Icons.person_outline,
                                  numeric: false,
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: <Widget>[
                                    _CheckSquare(
                                      checked: _remember,
                                      onTap: () => setState(
                                          () => _remember = !_remember),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      '记住我的信息',
                                      style: TextStyle(
                                          fontSize: 15, color: D.textPrimary),
                                    ),
                                  ],
                                ),
                                if (_error != null) ...<Widget>[
                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      _error!,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFFFFB4B4)),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 22),
                                PrimaryButton(
                                  label: _submitting ? '正在入住…' : '立即入住',
                                  enabled: !_submitting,
                                  onPressed: _submit,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Column(
                        children: <Widget>[
                          Text(
                            '重塑智臻旅居体验，让科技赋能每一次下榻',
                            style:
                                TextStyle(fontSize: 12, color: D.textSecondary),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '欢迎回家，尽享未来舒适之旅',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: D.textPrimary,
                            ),
                          ),
                          SizedBox(height: 22),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.numeric,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool numeric;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontSize: 16, color: Color(0xFF2B2B2B)),
      cursorColor: D.accent,
      decoration: loginInputDecoration(
        hint: hint,
        icon: Padding(
          padding: const EdgeInsets.only(left: 20, right: 12),
          child: Icon(icon, size: 24, color: const Color(0xFF8A8A8A)),
        ),
      ),
    );
  }
}

/// 设计图里的方形勾选框（未选中为白色描边空框）
class _CheckSquare extends StatelessWidget {
  const _CheckSquare({required this.checked, required this.onTap});

  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: checked ? Colors.white : Colors.transparent,
          border: Border.all(color: Colors.white, width: 1.5),
          borderRadius: BorderRadius.circular(3),
        ),
        child:
            checked ? const Icon(Icons.check, size: 15, color: D.accent) : null,
      ),
    );
  }
}
