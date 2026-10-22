/**
 * smart_hotel_server 入口文件
 *
 * 装配顺序：
 *   1. 初始化内存数据
 *   2. 启动温度逼近模拟器
 *   3. 全局中间件：CORS → JSON 解析 → 日志 → 随机延迟
 *   4. 业务路由：/api/auth、/api/room、/api/ac、/api/light、/api/curtain、/api/service
 *   5. 健康检查 /api/ping
 *   6. 404 兜底 + 全局错误兜底
 *   7. 监听端口（0.0.0.0，同时支持本机/模拟器/真机访问）
 */

import express from 'express'
import cors from 'cors'
import os from 'os'

import { config } from './config.js'
import { initRooms } from './store/rooms.js'
import { startTempSimulator } from './store/tempSimulator.js'

import { logger } from './middleware/logger.js'
import { delay } from './middleware/delay.js'
import { notFoundHandler, errorHandler } from './middleware/errorHandler.js'

import { authRouter } from './routes/auth.js'
import { roomRouter } from './routes/room.js'
import { acRouter } from './routes/ac.js'
import { lightRouter } from './routes/light.js'
import { curtainRouter } from './routes/curtain.js'
import { serviceRouter } from './routes/service.js'

import { ok } from './utils/result.js'

// ==================== 初始化 ====================

initRooms()
startTempSimulator()

const app = express()

// ==================== 全局中间件 ====================

// CORS 全开，允许真机/模拟器跨域联调
app.use(cors())

// JSON body 解析
app.use(express.json())

// 请求日志（受 config.ENABLE_LOG 控制）
app.use(logger)

// 随机延迟（受 config.ENABLE_DELAY 控制）
app.use(delay)

// ==================== 业务路由 ====================

// 健康检查：不需要鉴权，方便客户端启动时探活
app.get('/api/ping', (req, res) => {
  res.json(ok({ time: new Date().toISOString() }, 'pong'))
})

app.use('/api/auth', authRouter)
app.use('/api/room', roomRouter)
app.use('/api/ac', acRouter)
app.use('/api/light', lightRouter)
app.use('/api/curtain', curtainRouter)
app.use('/api/service', serviceRouter)

// ==================== 兜底 ====================

// 未匹配到任何路由：返回 404 + 业务码 1003（JSON）
app.use(notFoundHandler)

// 全局错误兜底（含请求体 JSON 解析失败）
app.use(errorHandler)

// ==================== 启动监听 ====================

/** 取本机所有非 internal IPv4 地址，便于打印真机访问地址 */
function getLanIPs() {
  const result = []
  const ifaces = os.networkInterfaces()
  for (const name of Object.keys(ifaces)) {
    for (const info of ifaces[name] || []) {
      if (info.family === 'IPv4' && !info.internal) {
        result.push(info.address)
      }
    }
  }
  return result
}

app.listen(config.PORT, config.HOST, () => {
  const lanIPs = getLanIPs()
  const lanLine = lanIPs.length > 0
    ? lanIPs.map(ip => `http://${ip}:${config.PORT}`).join('  ')
    : '（未检测到内网 IP，请用 ipconfig / ifconfig 查询）'

  console.log('')
  console.log('[smart_hotel_server] 服务已启动')
  console.log(`  ▸ 本机访问:    http://localhost:${config.PORT}`)
  console.log(`  ▸ 模拟器访问:  http://10.0.2.2:${config.PORT}`)
  console.log(`  ▸ 真机访问:    ${lanLine}`)
  console.log(`  ▸ 测试账号:    1209/乔安  1210/张明  1211/李娜`)
  console.log(`  ▸ 温度逼近:    已启动（每秒 ${config.TEMP_STEP}℃ 步长）`)
  console.log(`  ▸ 随机延迟:    ${config.ENABLE_DELAY ? `${config.DELAY_MIN_MS}-${config.DELAY_MAX_MS}ms` : '已关闭'}`)
  console.log('')
})
