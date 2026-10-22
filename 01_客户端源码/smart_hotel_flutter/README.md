# 智慧客房 · Flutter 客户端工程

> 2026 深圳技能大赛（计算机程序设计员 / 鸿蒙智能体应用开发）赛题配套前端
> **后端已内置进 APK**：13 个 REST 接口用 Dart 复刻，随 App 进程启动，装到手机上即可完整演示

---

## 一、技术选型与运行载体

| 项目 | 选择 |
|---|---|
| 形态 | **Flutter 原生应用（非 Web 网页）** |
| 运行载体 | Android 真机 / 模拟器（Windows 桌面目标已移除，见 §九） |
| 渲染 | Flutter 自绘引擎（Skia/Impeller），不使用浏览器内核，不是 WebView 套壳 |
| 语言 | Dart 3（null-safety + records） |
| 状态管理 | `provider` + `ChangeNotifier` |
| 网络 | `package:http` |
| 持久化 | `shared_preferences` |
| 路由 | `Navigator` + `onGenerateRoute` 路由表 |
| **后端** | **App 内置**：`dart:io HttpServer` 监听 `127.0.0.1:3000` |

一条命令即可启动：`flutter run`。全程不打开浏览器、不需要另起 Node 服务。

---

## 二、快速开始

### 1. 环境

本机已装好，**新开终端直接可用**（路径与版本见 `../开发环境说明.md`）：

| 组件 | 版本 | 路径 |
|---|---|---|
| Flutter | 3.47.7 / Dart 3.13.5 | `D:\tools\flutter` |
| JDK | Temurin 17.0.20.1 | `D:\tools\jdk-17` |
| Android SDK | 36 + 35、build-tools 36.0.0、NDK 28.2 | `D:\tools\android-sdk` |

```bash
flutter --version     # Flutter 3.47.7
flutter doctor        # [√] Android toolchain；Windows/设备两项 crash 是沙箱禁了 wmic/reg，可忽略
```

已开着的终端窗口需要先激活：`.\env.ps1`（PowerShell）或 `env.bat`（cmd）。

### 2. 直接运行（后端已内置，无需 npm start）

```bash
flutter pub get
flutter run          # 插上安卓手机即可
```

App 启动时会先拉起内置后端（失败会降级为"无法连接后端服务"提示，不崩溃），
登录页底部会显示当前模式，例如 `embedded · http://127.0.0.1:3000`。

测试账号：`1209 / 乔安`、`1210 / 张明`、`1211 / 李娜`。

### 3. 想改用电脑上的 Node 后端？

打开 `lib/core/config/app_config.dart`，把 `serverMode` 改成 `remote`，再按载体选 `env`：

```dart
static const ServerMode serverMode = ServerMode.remote;  // 默认 embedded
static const HostEnv env = HostEnv.usbReverse;
```

| 载体 | env | 实际地址 | 额外操作 |
|---|---|---|---|
| 真机（USB 线） | `usbReverse` | `http://localhost:3000` | 先执行 `adb reverse tcp:3000 tcp:3000` |
| 真机（Wi-Fi） | `physicalDevice` | `http://<电脑内网IP>:3000` | 手机与电脑同一 Wi-Fi，防火墙放行 3000 |
| Android 模拟器 | `androidEmulator` | `http://10.0.2.2:3000` | 无需额外操作 |

两种模式**接口契约完全一致**，`ApiClient` / `Store` / 页面一行都不用改。

### 4. 运行

```bash
flutter pub get
flutter run                     # 自动选当前设备（插着手机就是手机）
flutter run -d <device-id>      # 指定设备
flutter build apk --debug       # 只出包
```

### 5. 验证

```bash
flutter analyze    # 静态检查
flutter test       # 单元测试 + Widget 测试（不需要模拟器）
```

---

## 三、目录结构与模块划分

```
smart_hotel_flutter/
├── lib/
│   ├── main.dart                  # 入口：初始化存储 → 恢复会话 → 装配依赖 → runApp
│   ├── app.dart                   # 根组件：Provider 注入 + MaterialApp + 路由
│   │
│   ├── core/                      # 基础设施（与业务无关）
│   │   ├── config/app_config.dart      # 环境 / 端口 / 超时
│   │   ├── constants/app_constants.dart# 路由名、存储键、场景/窗帘/服务枚举、温度边界
│   │   ├── theme/app_theme.dart        # 设计令牌 + ThemeData
│   │   ├── network/
│   │   │   ├── api_client.dart         # 唯一请求出口：URL/鉴权/解包/401/异常翻译
│   │   │   └── api_exception.dart      # 业务码常量 + ApiException
│   │   ├── storage/token_storage.dart  # SharedPreferences 封装
│   │   └── router/app_router.dart      # 路由表 + 全局 navigatorKey
│   │
│   ├── data/                      # 数据层
│   │   ├── models/room_models.dart     # 与接口文档第 4 节逐字段对齐
│   │   └── api/                        # 一域一文件
│   │       ├── auth_api.dart  room_api.dart  ac_api.dart
│   │       ├── light_api.dart curtain_api.dart service_api.dart
│   │
│   ├── state/                     # 状态层
│   │   ├── session_store.dart          # Token / 用户 / 记住我的信息
│   │   └── room_store.dart             # 房间快照 + 全部写操作
│   │
│   ├── local_server/              # 【内置后端】Node 版的 Dart 复刻
│   │   ├── hotel_server.dart           # HttpServer + 13 个路由 + 鉴权 + 统一响应
│   │   ├── hotel_state.dart            # 房间内存状态 + 场景预设 + 温度模拟
│   │   └── jwt_hs256.dart              # HS256 JWT 签发/校验
│   │
│   └── ui/
│       ├── pages/
│       │   ├── login_page.dart          # 登录页（路由入口）
│       │   ├── main_shell.dart          # 主框架：底部四页签
│       │   ├── home_tab.dart            # 首页：空调 / 场景 / 快捷服务 / 晚安
│       │   ├── light_tab.dart           # 灯光：总开关 / 5 场景 / 9 灯
│       │   ├── curtain_tab.dart         # 窗帘：批量 + 两组单控
│       │   └── service_tab.dart         # 服务：SOS / 两个开关 / 退出登录
│       └── widgets/
│           ├── common_widgets.dart      # SectionTitle / PrimaryButton / PillSwitch /
│           │                            # SceneTile / LoadingOverlay
│           ├── ac_card.dart             # 空调卡片
│           ├── curtain_panel.dart       # 窗帘面板（AnimationController 补间）
│           └── app_toast.dart           # 全局 SnackBar 出口
│
├── test/
│   ├── api_client_test.dart       # 接口层：解包、鉴权头、错误码、401
│   ├── room_store_test.dart       # 状态层：快照填充、开机、切场景、单灯、错误提示
│   └── login_page_test.dart       # 登录页：本地校验、服务端错误文案
│
├── pubspec.yaml
└── analysis_options.yaml
```

### 依赖方向（单向）

```
ui/pages → ui/widgets → state → data/api → core/network
                             ↘ data/models

local_server  ← 只被 main.dart 启动，不反向依赖任何 UI/Store
```

- `ui` 层只 `context.watch<RoomStore>()`，不直接 `new XxxApi()`；
- `state` 层不 import 任何 Flutter Widget（只依赖 `foundation` 的 `ChangeNotifier`）；
- `data/api` 不认识页面，401 由 `ApiClient` 回调交给上层处理；
- `local_server` 与客户端代码零耦合：它只吐 JSON，客户端只认 HTTP，**所以能随时换成真后端**。

---

## 四、各模块职责

| 模块 | 职责 | 关键点 |
|---|---|---|
| `main.dart` | 启动编排 | 先拉起内置后端并回写端口 → 存储就绪 → 恢复会话 → 装配 `ApiClient`/`RoomStore` → `runApp` |
| `app.dart` | 根组件 | `MultiProvider` 注入 Session/Room/AuthApi；`MaterialApp` 挂 `navigatorKey` 与 `scaffoldMessengerKey` |
| `AppRouter` | 路由 | 只有 `login` / `main` 两个顶层路由；退出与 401 统一 `pushNamedAndRemoveUntil`，栈不会堆积 |
| `ApiClient` | 网络出口 | 拼 BaseURL、注入 `Bearer`、解析 `Result<T>`、业务码判定、401 回调、异常中文化。可注入 `http.Client`，便于测试 |
| `XxxApi` | 接口封装 | 一域一文件，方法即语义；请求体用强类型 Map，响应直接 `fromJson` 成模型 |
| `room_models.dart` | 契约 | 字段名与后端完全一致，不做改名；`RoomSnapshot.empty` 让 UI 不必到处判空 |
| `RoomStore` | 业务状态 | 全应用唯一数据源；写操作走"请求 → 用返回值刷新 → 提示"闭环；`busy` 全局锁防连点 |
| `SessionStore` | 会话 | Token 持久化、冷启动恢复、记住我的信息；不依赖 api 层（避免循环依赖） |
| **`HotelServer`** | **内置后端** | `dart:io HttpServer` 监听 `127.0.0.1:3000`（占用则顺延 3001/3100）；13 个路由、统一响应、401 鉴权、404 兜底，行为对齐 Express 版 |
| **`HotelState`** | **服务端状态** | 房间内存数据、场景预设、总开关/单灯联动、窗帘三态、温度每秒 0.5℃ 逼近；App 重启即还原 |
| **`JwtHs256`** | **令牌** | 与 jsonwebtoken 一致的 HS256 签发/校验，含 exp 过期判定与定长比较 |
| `TokenStorage` | 持久化 | SharedPreferences 的唯一读写点 |
| `Theme` | 样式 | 颜色/间距/圆角/字号常量 + `cardDecoration()`；组件里不写字面量 |
| `widgets` | 复用件 | 只收数据和回调，不持有业务状态 |

### 一次点击的完整链路（点"阅读模式"）

```
SceneTile.onTap
  → RoomStore.applyScene('reading')
    → _guard 加锁
      → LightApi.scene('reading')
        → ApiClient.postJson → POST /api/light/scene {"sceneId":"reading"}
          → 解包 Result → code==0 → 返回 data
      ← LightStateResult{activeSceneId, masterLight, lights[]}
    → _merge 生成新 RoomSnapshot → notifyListeners()
    → AppToast 提示"已切换到阅读模式"
  ← context.watch 的四个 Tab 同时重建，场景高亮与 9 个灯同步
```

---

## 五、接口层对接

统一约定（接口文档 2.x）：

- BaseURL 由 `AppConfig.baseUrl` 生成，业务代码不出现 host/port
- 请求头 `Content-Type: application/json`；除 `login`、`ping` 外注入 `Authorization: Bearer {token}`
- 响应统一 `{ code, msg, data? }`，**业务成功码是 0（不是 200）**
- `ApiClient` 只把 `data` 交给上层；`code != 0` 一律抛 `ApiException(code, msg)`

| # | 接口 | 封装方法 | 返回模型 |
|---|---|---|---|
| 1 | `GET /api/ping` | `AuthApi.ping()` | `void` |
| 2 | `POST /api/auth/login` | `AuthApi.login(roomNo, guestName)` | `LoginResult` |
| 3 | `POST /api/auth/logout` | `AuthApi.logout()` | `void` |
| 4 | `GET /api/room/snapshot` | `RoomApi.snapshot()` | `RoomSnapshot` |
| 5 | `POST /api/ac/power` | `AcApi.power(on)` | `AcState` |
| 6 | `POST /api/ac/temperature` | `AcApi.setTemperature(t)` | `AcState` |
| 7 | `POST /api/light/master` | `LightApi.master(on)` | `LightStateResult` |
| 8 | `POST /api/light/scene` | `LightApi.scene(sceneId)` | `LightStateResult` |
| 9 | `POST /api/light/toggle` | `LightApi.toggle(id, on)` | `LightToggleResult` |
| 10 | `POST /api/curtain/control` | `CurtainApi.control(id, action)` | `CurtainItem` |
| 11 | `POST /api/curtain/batch` | `CurtainApi.batch(action)` | `List<CurtainItem>` |
| 12 | `POST /api/service/toggle` | `ServiceApi.toggle(key, on)` | `ServiceState` |
| 13 | `POST /api/service/sos` | `ServiceApi.sos()` | `void` |

**错误码策略**

| 业务码 | 处理位置 | 行为 |
|---|---|---|
| `0` | `ApiClient` | 返回 data |
| `1001 / 1002 / 1003 / 5000` | `RoomStore._guard` | SnackBar 原文提示 |
| `1101 / 1102` | `ApiClient.onUnauthorized` | 清会话 → `AppRouter.toLogin()` |
| `1201 / 1202` | 同 1001 分支 | 保留码，Mock 不触发，分支已留 |
| 网络失败 | `ApiClient` | "无法连接后端服务（地址），请确认服务已启动" |

---

## 六、状态管理

- **单一数据源**：`RoomStore` 持有 `RoomSnapshot`，所有页面 `context.watch<RoomStore>()`。
- **不可变更新**：每次都是 `_snapshot = _merge(...)` 生成新对象，`notifyListeners()` 一次性通知，不会出现"改了字段但界面不刷新"。
- **不做乐观更新**：后端切场景会联动 9 个灯 + 总开关 + `activeSceneId`，必须用返回值覆盖。
- **`busy` 全局锁**：后端注入 100–300ms 延迟，防连点。
- **`_keepScene` 哨兵**：`activeSceneId` 合法值包含 `null`，用哨兵区分"没传"与"显式置空"，避免开机把场景高亮误清掉。

---

## 七、测试与验证结果

```bash
flutter analyze   # 结果：No issues found!
flutter test      # 结果：All tests passed! (34 个用例)
flutter build apk --debug
# √ Built build\app\outputs\flutter-apk\app-debug.apk
```

| 测试文件 | 覆盖 |
|---|---|
| `api_client_test.dart` | data 解包、Bearer 注入、免鉴权不带头、业务码异常、401 回调、无 data 接口、非 JSON 响应（7 例） |
| `room_store_test.dart` | 快照填充、开机请求体与状态刷新、切场景联动、单灯清空场景、服务端错误转提示（5 例） |
| `login_page_test.dart` | 空房号本地拦截不发请求、1002 错误文案展示（2 例） |
| `app_smoke_test.dart` | **端到端**：真实装配 Provider + 路由 + Store + 网络层（只把 HTTP 换成 MockClient），走完 登录 → 跳主框架 → 拉快照 → 四个页签轮转（1 例） |
| **`local_server_test.dart`** | **真起 HttpServer**，用真 http 客户端打 13 个接口：登录/令牌过期/快照结构/开关机/温度越界/场景预设/总开关/单灯/窗帘/服务/SOS/404/非法 JSON（**19 例**） |

前四组用 `MockClient`，不依赖真实后端；`local_server_test` 跑的是**真实的内置服务**，
等于把 Node 版的行为逐条回归了一遍。

> **验证边界（如实说明）**：已完成 `flutter analyze` 0 问题、34 个用例全过（含内置后端 19 例契约测试）、
> 并**实际编译出可安装的 debug APK**。
> 仍未在真机或模拟器上运行过（本机无硬件虚拟化，未装模拟器镜像），
> 你在本机 `flutter run` 或 `adb install` 即为最终验证。


---

## 八、已实现 / 待办

**已实现**

- 登录闭环：本地校验 → 调接口 → 保存 Token → 跳主框架；记住我的信息；401 自动回登录页
- 首页：空调（开关 / 16–30 步进 / 当前温度）、4 场景、2 快捷服务、晚安模式（可再次点击取消高亮）
- 灯光：总开关、5 场景、9 盏灯独立控制，场景与单灯互斥高亮
- 窗帘：批量开合、单组三动作、`AnimationController` 补间动画、暂停停在当前位置
- 服务：两个独立开关、SOS 二次确认、退出登录
- 统一 Loading 遮罩、SnackBar 提示、异常文案

**待办**

- 图标目前用 Material Icons + 少量字形，接入 UI 素材包后替换为 `Image.asset`
- 背景目前是渐变，替换为客房实景图 + `BackdropFilter` 毛玻璃
- 窗帘用纯色块模拟布纹，素材到位后换成贴图

---

## 九、已知取舍

1. **窗帘进度不落库**：接口只有三态、没有位置量，暂停位置只存在 `AnimationController.value` 里，重进页面会回到 0.5 的估算值。
2. **首页只放 4 个场景**：接口 `scenes` 返回 5 个，但效果图首页是 4 个 + 晚安卡片，故 `SceneIds.homeList` 与 `lightList` 分开定义。
3. **`goodnight` 不在 scenes 列表**：关总开关后 `activeSceneId` 会变成它，用 `isSceneActive('goodnight')` 直接比对，映射到首页晚安卡片。
4. **`masterLight` 语义漂移**：快照里是"总开关状态"，单灯接口返回的是"任意灯亮即 true"，UI 只用它渲染，不做逻辑判断。
5. **内置后端不模拟网络延迟**：`HotelServer.enableDelay` 默认 `false`（回环地址没有真实网速问题）。想复现视频里的 Loading 态，置为 `true` 即恢复 100–300ms 随机延迟。
6. **内置后端与 Node 版的差异**（其余全部对齐）：
   - 数据同样只在内存，**App 重启即还原**；
   - CORS 未实现（同进程直连，用不到；若在浏览器里访问需另加）；
   - JWT 密钥与 Node 版同值（仅演示用）；
   - 请求日志走 `debugPrint`，在 DevEco/Logcat 里看。
7. **Windows 桌面目标已移除**：本机没有 Visual Studio，`windows/` 目录留着会导致 `flutter run` 误选桌面并失败，
   同时它的插件符号链接要求与未开启的开发者模式冲突。需要时执行 `flutter create --platforms=windows .` 可恢复。

---

## 十、常见问题

| 现象 | 处理 |
|---|---|
| 登录提示"无法连接后端服务" | 内置模式下多半是端口被占用（看日志里的实际端口）；远程模式检查 `env` 与载体是否匹配 |
| 内置后端起不来 | 3000/3001/3100 全被占用。改 `AppConfig.defaultPort` 或释放端口 |
| 想回到"电脑跑后端"的模式 | `serverMode` 改 `remote`，再按 §二.3 选 `env`；两种模式接口完全一致 |
| Android 9+ 明文 HTTP 被拦 | 本工程用 `http://`，`AndroidManifest.xml` 已置 `usesCleartextTraffic="true"` |
| 改了 `AppConfig` 不生效 | `static const` 是编译期常量，需重新 `flutter run`（热重载不生效） |
| `flutter pub get` 慢 | 配镜像：`PUB_HOSTED_URL=https://pub.flutter-io.cn`、`FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn` |
| `flutter test` 报 WebSocket 握手失败 | 系统代理拦了本地回环，清 `HTTP_PROXY` 并设 `NO_PROXY=localhost,127.0.0.1` |

---

## 十一、UI 还原说明（对照 `7.高清预览图`）

### 设计基准

设计图为 **880×1904 @2x**，即 **440×952dp** 的手机版式，所有尺寸按像素 ÷2 换算。

| 令牌 | 实测值 | 用在哪 |
|---|---|---|
| 主色 `#999854` | 场景选中块 / 导航选中块 / 开启态开关 | 全局强调色 |
| 玻璃卡片 | 白 10% 底 + 白 18% 1px 描边 + 18px 背景模糊 | 所有卡片 |
| 图标底座 | 白 14%（选中时 20%） | 卡片内小方块 |
| 页边距 | 16dp（登录页表单 48dp） | 全局 |
| 卡片圆角 | 20dp（小块 14dp，胶囊 999） | 全局 |
| 字号 | 46 主标题 / 30 页面标题 / 20 区块 / 17 卡片 / 16 列表 / 13 说明 / 12 胶囊 | 全局 |

> 卡片用 `BackdropFilter` 实时模糊，而不是静态半透明色——静态色在照片背景上会发灰，与设计图的通透感不一致。

### 页面映射

| 设计图 | 实现 | 状态覆盖 |
|---|---|---|
| `00登录.png` | `login_page.dart` | 空表单 + 记住我勾选 |
| `01首页.png` / `01首页_act.png` | `home_tab.dart` + `ac_card.dart` | 空调开/关、场景选中、快捷服务选中 |
| `02灯光.png` / `02灯光_act.png` | `light_tab.dart` | 总开关开/关、场景选中、单灯开/关 |
| `03窗帘.png` / `03窗帘_opening.png` | `curtain_tab.dart` + `curtain_panel.dart` | 全关 / 开合中、暂停态 |
| `04服务.png` | `service_tab.dart` | 两个开关的独立开/关 |

自检方式：`flutter test tool/preview_test.dart --update-goldens` 会把五个页面渲染到 `test/goldens/`，
与设计图逐张对照（字体用系统 SimHei，图标用 MaterialIcons，保证不是方块）。

### 图中未明确、由实现决定的部分（假设）

1. **背景照片无法从截图分离**：原图是整屏模糊的客房实景照，被 UI 覆盖。做法是把登录截图中已知的
   UI 区域按行做左右插值抹除、再整体高斯模糊，重建出 `assets/images/bg_hotel.png`（440×952）。
   色调与构图与设计图一致，但**不是原始素材**。
2. **窗帘织物**：设计图是实物贴图，这里用 `CustomPainter` 按同色系画竖向褶皱（布帘 `#B4B36A/#7C7B3C`，
   窗纱 `#F6F6F2/#D9D9D2`），带顶亮底暗的受光渐变。开合进度仍由 `AnimationController` 驱动。
3. **图标**：空调出风口、窗帘开合符号、暂停、加减、闭眼（睫毛）为自绘 `CustomPainter`；
   其余用 Material Icons 近似——场景（太阳/弯月/书/心/月）、服务（禁止/清洁）、导航（首页/灯泡/百叶窗/四宫格）、退出。
4. **批量按钮高亮规则**：设计图"全关"时两个批量按钮为灰玻璃，"开合中"时两个都为主色。
   实现为：任一窗帘不处于 closed 时，两个按钮都进入主色态。
5. **服务页大卡片不随状态变色**：设计图中"清理房间"已开启，但卡片仍是玻璃底，只有开关变主色；
   首页的快捷服务卡则会整块变主色（`01首页_act` 为准）。
6. **登录页默认空表单**：设计图是空输入框 + 未勾选；勾选"记住我的信息"登录后，下次启动才回填房号与姓名。
7. **宽屏适配**：设计稿是 440dp 手机版式，平板/折叠屏上限宽 460dp 居中，避免卡片被拉宽变形。
8. 顶部留白按屏高比例收缩（952dp 上为 148dp），保证小屏（600dp 高）不溢出。
