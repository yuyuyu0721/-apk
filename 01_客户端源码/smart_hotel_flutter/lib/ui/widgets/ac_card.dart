import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/room_models.dart';
import 'app_icons.dart';
import 'glass.dart';

/// 空调卡片
///
/// 设计要点：
///   - 大字是"目标温度"，小字是"当前温度"（别接反）
///   - 开机时：电源钮变主色、温度数字变主色、"已关闭"胶囊变白底"运行中"
class AcCard extends StatelessWidget {
  const AcCard({
    super.key,
    required this.ac,
    required this.onPower,
    required this.onTempDelta,
  });

  final AcState ac;
  final VoidCallback onPower;
  final ValueChanged<int> onTempDelta;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              const GlassTile(
                size: 48,
                radius: 14,
                child: AcUnitIcon(size: 26),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    '空调',
                    style:
                        TextStyle(fontSize: D.cardBody, color: D.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: ac.on ? Colors.white : const Color(0x1FFFFFFF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ac.on ? '运行中' : '已关闭',
                      style: TextStyle(
                        fontSize: D.tiny,
                        color: ac.on ? D.onWhite : D.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onPower,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ac.on ? D.accent : const Color(0x1FFFFFFF),
                  ),
                  child: const Icon(Icons.power_settings_new,
                      size: 24, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              _StepButton(plus: false, onTap: () => onTempDelta(-1)),
              Expanded(
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${ac.targetTemp}',
                          style: TextStyle(
                            fontSize: D.hero,
                            fontWeight: FontWeight.w500,
                            height: 1.05,
                            color: ac.on ? D.accent : D.textPrimary,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 2),
                          child: Text(
                            '℃',
                            style: TextStyle(
                              fontSize: 18,
                              color: ac.on ? D.accent : D.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '当前温度：${ac.currentTemp.toStringAsFixed(0)}℃',
                      style: const TextStyle(
                          fontSize: D.caption, color: D.textSecondary),
                    ),
                  ],
                ),
              ),
              _StepButton(plus: true, onTap: () => onTempDelta(1)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.plus, required this.onTap});

  final bool plus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0x1FFFFFFF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: MinusPlusIcon(plus: plus, size: 22, color: D.textPrimary),
      ),
    );
  }
}
