/**
 * Bearer Token 校验中间件
 *
 * 从 Authorization 头取 Token 并校验：
 *   - 缺失/格式不对  → 401 业务码 1101（无效）
 *   - 已过期         → 401 业务码 1102（过期）
 *   - 签名错误       → 401 业务码 1101（无效）
 *   - 对应房间不存在 → 401 业务码 1101（无效）
 *
 * 校验通过后把房间号挂到 req.roomNo，后续路由直接使用。
 */

import { verifyToken, jwt } from '../utils/jwt.js'
import { fail, CODE } from '../utils/result.js'
import { getRoom } from '../store/rooms.js'

export function authRequired(req, res, next) {
  const header = req.headers['authorization'] || ''

  // 期望格式：Bearer <token>
  if (!header.startsWith('Bearer ')) {
    return res.status(401).json(fail(CODE.TOKEN_INVALID, 'Token 缺失或格式错误'))
  }
  const token = header.slice('Bearer '.length).trim()
  if (!token) {
    return res.status(401).json(fail(CODE.TOKEN_INVALID, 'Token 不能为空'))
  }

  let payload
  try {
    payload = verifyToken(token)
  } catch (e) {
    if (e instanceof jwt.TokenExpiredError) {
      return res.status(401).json(fail(CODE.TOKEN_EXPIRED, 'Token 已过期，请重新登录'))
    }
    // JsonWebTokenError 与其他签名错误统一按"无效"处理
    return res.status(401).json(fail(CODE.TOKEN_INVALID, 'Token 无效'))
  }

  // Token 合法但对应房间已不存在（如修改了 DEFAULT_ROOMS 后重启），同样按"无效"处理，
  // 避免后续路由拿到 undefined 房间而抛异常
  if (!getRoom(payload.roomNo)) {
    return res.status(401).json(fail(CODE.TOKEN_INVALID, 'Token 无效'))
  }

  req.roomNo = payload.roomNo
  next()
}
