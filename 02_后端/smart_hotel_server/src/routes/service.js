/**
 * 客房服务域路由
 *
 *   POST /api/service/toggle   切换请勿打扰 / 清理房间
 *   POST /api/service/sos      触发 SOS（一次性事件，不保存状态）
 */

import { Router } from 'express'
import { ok, fail, CODE } from '../utils/result.js'
import { authRequired } from '../middleware/auth.js'
import { getRoom } from '../store/rooms.js'

export const serviceRouter = Router()

const VALID_KEYS = new Set(['doNotDisturb', 'cleaning'])
const KEY_NAME = { doNotDisturb: '请勿打扰', cleaning: '清理房间' }

/**
 * POST /api/service/toggle
 * body: { key: 'doNotDisturb' | 'cleaning', on: boolean }
 */
serviceRouter.post('/toggle', authRequired, (req, res) => {
  const { key, on } = req.body || {}
  if (!VALID_KEYS.has(key)) {
    return res.json(fail(CODE.PARAM_ERROR, `无效的服务键：${key}`))
  }
  if (typeof on !== 'boolean') {
    return res.json(fail(CODE.PARAM_ERROR, 'on 字段必须是布尔值'))
  }

  const room = getRoom(req.roomNo)
  room.services[key] = on
  res.json(ok(room.services, `已${on ? '开启' : '关闭'}${KEY_NAME[key]}`))
})

/**
 * POST /api/service/sos
 * 触发一次紧急求助事件（服务端打日志，不保存状态）
 */
serviceRouter.post('/sos', authRequired, (req, res) => {
  console.warn(`[SOS] 房间 ${req.roomNo} 触发紧急求助 ${new Date().toISOString()}`)
  res.json(ok(undefined, '紧急求助已发送，前台将立即与您联系'))
})
