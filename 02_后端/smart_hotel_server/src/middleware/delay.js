/**
 * 随机延迟中间件
 *
 * 给每个请求注入 100-300ms 的随机延迟（范围由 config 决定），
 * 让客户端 Loading 状态/防抖逻辑有真实体感。
 */

import { config } from '../config.js'

export function delay(req, res, next) {
  if (!config.ENABLE_DELAY) return next()

  const span = config.DELAY_MAX_MS - config.DELAY_MIN_MS
  const ms = config.DELAY_MIN_MS + Math.floor(Math.random() * (span + 1))
  setTimeout(next, ms)
}
