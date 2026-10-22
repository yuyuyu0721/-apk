# 智慧客房 · Flutter 客户端交付包

2026 深圳技能大赛 · 计算机程序设计员（鸿蒙智能体应用开发）赛题「智慧客房」。

## 目录结构

```
智慧客房交付包_20261022/
├─ 00_APK/                     可直接安装的调试包（含内嵌后端，装到手机即可完整演示）
│  └─ 智慧客房-app-debug.apk
├─ 01_客户端源码/smart_hotel_flutter/   Flutter 工程（已剔除 build/.dart_tool 等产物）
├─ 02_后端/smart_hotel_server/           Node 版模拟后端（13 个 REST 接口，含 node_modules）
├─ 03_文档/                             接口文档、环境说明、赛项梳理、真机运行脚本
└─ 04_素材/                             高清预览图、演示视频、背景原图
```

## 一、最快上手：直接装 APK

1. 把 `00_APK/智慧客房-app-debug.apk` 装到 Android 手机（Android 8.0+）。
2. 打开 App，用内置账号登录，例如 **房号 1209 / 姓名 乔安**（1209 乔安、1210 张明、1211 李娜）。
3. **不需要电脑、不需要开后端**：App 内嵌了 Dart 版后端（启动时监听 `127.0.0.1:3000`），
   接口契约、错误码与 Node 版完全一致。

## 二、源码运行

环境（路径已在 `03_文档/env.ps1`、`env.bat` 中固化）：

| 组件 | 版本 | 路径 |
| --- | --- | --- |
| Flutter | 3.47.7 / Dart 3.13.5 | `D:/tools/flutter` |
| JDK | 17.0.20.1 | `D:/tools/jdk-17` |
| Android SDK | platform 35/36 | `D:/tools/android-sdk` |

常用命令（在 `01_客户端源码/smart_hotel_flutter` 下）：

```bash
flutter pub get
flutter analyze          # 静态检查（当前 0 issue）
flutter build apk --debug
```

跑单元测试**必须清掉代理**，否则 HTTP 客户端会走代理导致回环地址连不通：

```bash
env -u HTTP_PROXY -u HTTPS_PROXY -u http_proxy -u https_proxy \
    NO_PROXY="localhost,127.0.0.1" flutter test
```

当前 43 条测试全部通过。

## 三、切换后端：内嵌 ↔ Node

`lib/core/config/app_config.dart` 里的唯一开关：

```dart
static const ServerMode serverMode = ServerMode.embedded;  // 改 remote 连电脑上的 Node
```

- `embedded`：App 自带后端（默认），装 APK 即可演示；
- `remote`：先 `cd 02_后端/smart_hotel_server && npm install && npm start`，
  再按真机 / 模拟器选择 `HostEnv`（`usbReverse` 需 `adb reverse tcp:3000 tcp:3000`）。

## 四、关键设计说明

- **状态管理**：`provider` + `RoomStore`（单一数据源）。写操作全部走
  “调接口 → 用返回值刷新快照 → 通知 UI”，不做乐观更新；并用 Future 串行队列保证连点不丢动作。
- **接口契约**：成功码是 `0`（不是 200），HTTP 2xx + code==0 双判；
  `logout` / `sos` 无 `data`；温度 16–30 整数；窗帘只有 opened/paused/closed，无位置量。
- **交互规范**（演示视频判据）：
  - 总开关未开启时点场景模式 → 提示“请先打开总开关”并拒绝执行（晚安 / off 例外）；
  - 窗帘褶皱总数守恒、等分铺满整片宽度，全开时两侧各留约 7% 的密集堆叠；
  - “全部打开 / 全部关闭”跟随状态点亮（全开→打开亮，全关→关闭亮，混合态都不亮）；
  - 提示条是白底黑字胶囊，水平居中、悬在导航条上方；
  - 导航条为深色半透明胶囊，高 90dp，选中块 92×58。
- **背景图**：由素材包原图经 `tool/generate_background.py` 生成
  （首页暖色 `bg_hotel.jpg`、登录页冷色 `bg_login.jpg`），参数在脚本顶部可改。

## 五、账号与演示路径

内置账号：`1209 / 乔安`、`1210 / 张明`、`1211 / 李娜`。

建议演示顺序：登录 → 首页（空调开关 / 场景模式 / 快捷服务 / 晚安模式）
→ 灯光（总开关 → 场景 → 独立控制 9 盏灯）→ 窗帘（单组开合暂停 / 批量开合）
→ 服务（请勿打扰 / 清理房间 / SOS / 退出登录）。
