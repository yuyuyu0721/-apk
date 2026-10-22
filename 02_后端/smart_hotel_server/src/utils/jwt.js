/**
 * JWT 签发与校验工具
 *
 * 使用 HS256 算法签名，密钥与有效期从 config.js 读取。
 * payload 中只放 roomNo（房间号），客户端无需额外传递——
 * 后续接口可通过 req.roomNo 直接取到。
 */

import jwt from 'jsonwebtoken'
import { config } from '../config.js'

/**
 * 签发 Token
 * @param {string} roomNo 房间号（如 '1209'）
 * @returns {string} JWT 字符串
 */
export function signToken(roomNo) {
  return jwt.sign({ roomNo }, config.JWT_SECRET, {
    expiresIn: config.JWT_EXPIRES_IN,
  })
}

/**
 * 校验 Token
 * @param {string} token Bearer Token 字符串
 * @returns {{roomNo: string}} 解码后的 payload
 * @throws {jwt.TokenExpiredError} Token 已过期
 * @throws {jwt.JsonWebTokenError} Token 无效（签名错误、格式错误等）
 */
export function verifyToken(token) {
  return jwt.verify(token, config.JWT_SECRET)
}

export { jwt }
