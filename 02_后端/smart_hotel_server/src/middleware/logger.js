/**
 * 请求日志中间件
 *
 * 每次请求打印：
 *   [HH:MM:SS] → POST /api/auth/login   body={...}
 *   [HH:MM:SS] ← 200 code=0 (12ms)
 *
 * 受 config.ENABLE_LOG 控制，关闭后零开销。
 */

import { config } from '../config.js'

function ts() {
  const d = new Date()
  return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}:${String(d.getSeconds()).padStart(2, '0')}`
}

export function logger(req, res, next) {
  if (!config.ENABLE_LOG) return next()

  const start = Date.now()
  const bodyStr = req.body && Object.keys(req.body).length > 0
    ? ` body=${JSON.stringify(req.body)}`
    : ''
  console.log(`[${ts()}] → ${req.method} ${req.originalUrl}${bodyStr}`)

  // 用 res.on('finish') 拿真实响应耗时与业务码
  const originalJson = res.json.bind(res)
  let bizCode = '-'
  res.json = (body) => {
    if (body && typeof body === 'object' && 'code' in body) {
      bizCode = body.code
    }
    return originalJson(body)
  }

  res.on('finish', () => {
    const ms = Date.now() - start
    console.log(`[${ts()}] ← ${res.statusCode} code=${bizCode} (${ms}ms)`)
  })

  next()
}
