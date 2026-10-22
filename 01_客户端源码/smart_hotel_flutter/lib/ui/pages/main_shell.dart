import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../state/room_store.dart';
import '../widgets/app_icons.dart';
import '../widgets/common_widgets.dart';
import '../widgets/glass.dart';
import 'curtain_tab.dart';
import 'home_tab.dart';
import 'light_tab.dart';
import 'service_tab.dart';

/// 主框架：内容区 + 悬浮玻璃导航
///
/// 设计图里导航是"浮在内容之上的胶囊条"，选中项用主色圆角块托起图标与文字，
/// 所以不用 Scaffold.bottomNavigationBar，改为 Stack 内绝对定位。
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<RoomStore>().refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final RoomStore store = context.watch<RoomStore>();

    return Scaffold(
      backgroundColor: const Color(0xFF4E5450),
      body: AppBackground(
        child: Stack(
          children: <Widget>[
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 108),
                // 设计稿是 440dp 宽的手机版式，宽屏（平板/折叠）居中并限宽
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: IndexedStack(
                      index: _index,
                      children: const <Widget>[
                        HomeTab(),
                        LightTab(),
                        CurtainTab(),
                        ServiceTab(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(D.page, 0, D.page, D.navBottom),
                  child: _NavBar(
                    current: _index,
                    onSelect: (int index) => setState(() => _index = index),
                  ),
                ),
              ),
            ),
            if (store.loading && !store.hasData)
              const Positioned.fill(child: LoadingOverlay()),
          ],
        ),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({required this.current, required this.onSelect});

  final int current;
  final ValueChanged<int> onSelect;

  /// 图标与文字尺寸按设计图实测：图标 21dp、文字 12sp、图标与文字间距 8dp
  static const double _iconSize = 21;

  static List<({String label, Widget Function() icon})> get _items =>
      <({String label, Widget Function() icon})>[
        (
          label: '首页',
          icon: () => const Icon(Icons.home, size: _iconSize,
              color: Colors.white),
        ),
        (
          label: '灯光',
          icon: () => const DomeLightIcon(size: _iconSize),
        ),
        (
          label: '窗帘',
          icon: () => const BlindsIcon(size: _iconSize),
        ),
        (
          label: '服务',
          icon: () => const ServiceGridIcon(size: _iconSize),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(D.navHeight / 2),
      child: BackdropFilter(
        filter: glassBlur(),
        child: Container(
          height: D.navHeight,
          // 参考图里导航条是**深色**半透明胶囊（不是浅色玻璃）：
          // 压一层 20% 黑 + 背景模糊，图标/文字用白色才够跳。
          decoration: BoxDecoration(
            color: const Color(0x33000000),
            borderRadius: BorderRadius.circular(D.navHeight / 2),
            border: Border.all(color: const Color(0x14FFFFFF)),
          ),
          // 左右各留 16dp，让四个页签的中心与设计图实测值对齐
          // （79 / 173 / 267 / 361dp，间距 94dp）
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List<Widget>.generate(_items.length, (int index) {
                final ({String label, Widget Function() icon}) item =
                    _items[index];
                final bool active = current == index;
                // 选中态：92×58 的橄榄色胶囊（设计图实测 94×58）
                return Expanded(
                  child: Center(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelect(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 33,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: active ? D.accent : Colors.transparent,
                          borderRadius:
                              BorderRadius.circular(D.navHeight / 2),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            item.icon(),
                            const SizedBox(height: 8),
                            Text(
                              item.label,
                              style: const TextStyle(
                                  fontSize: D.tiny,
                                  height: 1.1,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
