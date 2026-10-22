/**
 * 房间域路由：整房快照
 *
 *   GET /api/room/snapshot   一次性返回房间基础信息 + 全部设备当前状态
 */

import { Router } from 'express'
import { ok, fail, CODE } from '../utils/result.js'
import { authRequired } from '../middleware/auth.js'
import { buildSnapshot } from '../store/rooms.js'

export const roomRouter = Router()

/**
 * GET /api/room/snapshot
 * 房间号由 Token 解出（req.roomNo），无需客户端传参
 */
roomRouter.get('/snapshot', authRequired, (req, res) => {
  const snapshot = buildSnapshot(req.roomNo)
  if (!snapshot) {
    return res.status(500).json(fail(CODE.INTERNAL_ERROR, '房间数据丢失'))
  }
  res.json(ok(snapshot))
})
