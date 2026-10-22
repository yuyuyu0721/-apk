/**
 * 鉴权域路由：登录 / 退出登录
 *
 *   POST /api/auth/login    登录拿 Token（不需要鉴权）
 *   POST /api/auth/logout   退出登录（需要鉴权，无状态实现）
 */

import { Router } from 'express'
import { ok, fail, CODE } from '../utils/result.js'
import { signToken } from '../utils/jwt.js'
import { authRequired } from '../middleware/auth.js'
import { validateCredential, getRoom } from '../store/rooms.js'

export const authRouter = Router()

/**
 * POST /api/auth/login
 * body: { roomNo, guestName }
 * 响应 data: { token, userInfo }
 */
authRouter.post('/login', (req, res) => {
  const { roomNo, guestName } = req.body || {}

  if (typeof roomNo !== 'string' || !roomNo) {
    return res.json(fail(CODE.PARAM_ERROR, '房间号必须是非空字符串'))
  }
  if (typeof guestName !== 'string' || !guestName) {
    return res.json(fail(CODE.PARAM_ERROR, '客人姓名必须是非空字符串'))
  }

  if (!validateCredential(roomNo, guestName)) {
    return res.json(fail(CODE.LOGIN_FAILED, '房间号或客人姓名错误'))
  }

  const token = signToken(roomNo)
  const room = getRoom(roomNo)
  res.json(ok({
    token,
    userInfo: room.room,
  }, '登录成功'))
})

/**
 * POST /api/auth/logout
 * 无状态实现：仅返回成功响应，服务端不作废 Token（Token 在有效期内仍可使用），
 * 客户端清空本地 Token 即可。
 */
authRouter.post('/logout', authRequired, (req, res) => {
  res.json(ok(undefined, '已退出登录'))
})
