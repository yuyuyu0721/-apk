# smart_hotel_server —— 智慧客房模拟后端

> 智慧客房项目（HarmonyOS 应用开发赛项）配套模拟后端，基于 Node.js + Express 实现。  
> 本服务仅用于客户端联调与教学演示，**不是赛题的开发内容**，由命题方与 UI 素材一并提供给考生。  

---

## 1. 快速开始

### 1.1 环境要求

| 项目 | 版本 |
|---|---|
| Node.js | 18+（推荐 20 LTS / 22 LTS） |
| npm | 9+ |
| 端口占用 | 默认 `3000`，被占用时改 `src/config.js` |

### 1.2 安装与启动

```bash
# 1) 进入目录
cd smart_hotel_server

# 2) 安装依赖（仅需一次）
npm install

# 3) 启动服务
npm start

# 或者带文件监听的开发模式（修改代码自动重启）
npm run dev
```

启动成功后控制台输出：

```
[smart_hotel_server] 服务已启动
  ▸ 本机访问:    http://localhost:3000
  ▸ 模拟器访问:  http://10.0.2.2:3000
  ▸ 真机访问:    http://<电脑内网IP>:3000  （需手机与电脑同一 Wi-Fi）
  ▸ 测试账号:    1209/乔安  1210/张明  1211/李娜
  ▸ 温度逼近:    已启动（每秒 0.5℃ 步长）
```

### 1.3 第一次通过 curl 验证

```bash
# 登录拿 Token
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"roomNo\":\"1209\",\"guestName\":\"乔安\"}"
```

返回示例：

```json
{
  "code": 0,
  "msg": "登录成功",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIs...",
    "userInfo": { "roomNo": "1209", "guestName": "乔安", "checkInDate": "2026-05-26" }
  }
}
```

拿到 Token 后调其他接口需要带上 `Authorization: Bearer <token>` 头。

---

## 2. 测试账号

服务启动时在内存中预置 3 个测试房间，**每次重启都会还原为默认状态**：

| 房间号 | 客人姓名 | 入住日期 |
|---|---|---|
| `1209` | 乔安 | 2026-05-26 |
| `1210` | 张明 | 2026-05-26 |
| `1211` | 李娜 | 2026-05-26 |

如需扩展，编辑 `src/store/rooms.js` 中的 `DEFAULT_ROOMS` 数组。

---

## 3. 接口总览

13 个接口（含 1 个健康检查），详细参数与响应见 `智慧客房项目接口文档.docx`（与 `Code/` 目录同级，位于 `Product/` 下）。

| 方法 | 路径 | 鉴权 |
|---|---|---|
| GET | `/api/ping` | 否 |
| POST | `/api/auth/login` | 否 |
| POST | `/api/auth/logout` | 是 |
| GET | `/api/room/snapshot` | 是 |
| POST | `/api/ac/power` | 是 |
| POST | `/api/ac/temperature` | 是 |
| POST | `/api/light/master` | 是 |
| POST | `/api/light/scene` | 是 |
| POST | `/api/light/toggle` | 是 |
| POST | `/api/curtain/control` | 是 |
| POST | `/api/curtain/batch` | 是 |
| POST | `/api/service/toggle` | 是 |
| POST | `/api/service/sos` | 是 |

---

## 4. 目录结构

```
smart_hotel_server/
├── package.json
├── README.md                    # 本文件
├── src/
│   ├── index.js                 # 启动入口（装配中间件与路由）
│   ├── config.js                # 端口、JWT、延迟、温度模拟、日志开关
│   ├── middleware/
│   │   ├── logger.js            # 请求日志
│   │   ├── delay.js             # 100-300ms 随机延迟
│   │   ├── auth.js              # Bearer Token 校验
│   │   └── errorHandler.js      # 404 兜底 + 全局错误兜底
│   ├── routes/
│   │   ├── auth.js              # 登录/登出
│   │   ├── room.js              # 整房快照
│   │   ├── ac.js                # 空调
│   │   ├── light.js             # 灯光
│   │   ├── curtain.js           # 窗帘
│   │   └── service.js           # 客房服务
│   ├── store/
│   │   ├── rooms.js             # 房间状态内存存储 + 默认数据 + 场景预设
│   │   └── tempSimulator.js     # currentTemp 每秒逼近 targetTemp
│   └── utils/
│       ├── result.js            # ok()/fail() 响应包装
│       └── jwt.js               # JWT 签发与校验
```

---

## 5. 真机/模拟器联调指引

### 5.1 模拟器调试

DevEco 模拟器访问宿主机的特殊 IP 是 `10.0.2.2`，所以客户端 `AppConfig.BASE_URL` 应配置为：

```typescript
static readonly BASE_URL: string = 'http://10.0.2.2:3000'
```

### 5.2 真机调试

1. 查看本机内网 IP：Windows 用 `ipconfig` 看"以太网"或"WLAN"的 IPv4，如 `192.168.1.100`；
2. 客户端 `AppConfig.BASE_URL` 配置为 `http://192.168.1.100:3000`；
3. **手机与电脑必须连接同一 Wi-Fi**；
4. 如果连接失败，检查 Windows 防火墙是否放行 3000 端口（首次启动通常会弹窗，选"允许"即可）。

### 5.3 CORS 与跨域

服务端已开启 **CORS 全开**（允许任意 Origin）。这对 HarmonyOS App 调用并不必需（CORS 只约束浏览器），但能让考生用浏览器页面（如 Swagger UI、自写 HTML）测试接口时不被同源策略阻拦；Postman、curl 等工具本身不受 CORS 限制。

---

## 6. 行为说明

### 6.1 数据持久化

**所有数据保存在内存中，重启服务后还原为默认状态。** 这是有意为之：

- 教学场景下方便随时回到干净状态；
- 避免文件 I/O 引入新的考点（持久化是客户端的考点，不是后端的）；
- 多个考生用同一份代码做练习时互不污染。

如有持久化需求，可在 `src/store/rooms.js` 中替换为 SQLite / lowdb 等轻量存储。

### 6.2 Token 行为

- 使用 HS256 算法签发的 JWT；
- 默认有效期 **12 小时**（`src/config.js` 中的 `JWT_EXPIRES_IN`）；
- `/api/auth/logout` 仅返回成功响应，**不维护黑名单**，退出后该 Token 在有效期内仍然可用——客户端清空本地 Token 即可；
- 校验失败统一返回 HTTP 401 + 业务码 1101（无效）或 1102（过期）。

### 6.3 currentTemp 模拟

服务启动时会启动一个全局定时器，**每秒**对所有房间检查：

- 若空调 `on === true` 且 `currentTemp !== targetTemp`，则 `currentTemp` 向 `targetTemp` 走 **0.5℃** 步长；
- 若空调关闭，`currentTemp` 不变（模拟空调不工作时室温不变）；
- 这样客户端反复拉 `/api/room/snapshot` 能看到温度的连续变化。

### 6.4 随机延迟

每个请求会被注入 **100-300ms** 的随机延迟，模拟真实网络。如需关闭：在 `src/config.js` 中把 `ENABLE_DELAY` 改为 `false`。

---

## 7. 常见问题

**Q：手机调用报 ERR_CONNECTION_REFUSED**  
A：电脑防火墙拦截了 3000 端口；或者手机与电脑不在同一 Wi-Fi。

**Q：调用接口返回 401 业务码 1101**  
A：Token 无效。重新调 `/api/auth/login` 并把响应里的新 Token 用于后续请求。

**Q：调用空调温度返回 1001**  
A：`targetTemp` 不是整数，或不在 [16, 30] 范围内。

**Q：能不能加新房间号？**  
A：修改 `src/store/rooms.js` 中的 `DEFAULT_ROOMS` 数组后重启服务即可。

**Q：报错"EADDRINUSE: address already in use 0.0.0.0:3000"**  
A：3000 端口被占用。在 `src/config.js` 中改 `PORT`，或停掉占用端口的进程。

---

## 8. 许可

MIT，仅用于教学与赛项联调。
