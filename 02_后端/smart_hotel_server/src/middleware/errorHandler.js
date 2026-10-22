/**
 * 全局兜底中间件
 *
 * notFoundHandler：没有任何路由匹配时返回 HTTP 404 + 业务码 1003，
 *                  保证未知路径也返回 Result 结构的 JSON，而不是 Express 默认的 HTML 页面。
 *
 * errorHandler：路由层未捕获的异常会冒泡到这里：
 *   - 请求体不是合法 JSON（express.json 解析失败）→ HTTP 200 + 业务码 1001（参数错误）
 *   - 其他异常 → HTTP 500 + 业务码 5000，避免把 stack trace 直接吐给客户端
 *
 * 注意：两者都必须挂在所有路由之后才能生效。
 * errorHandler 必须保留 4 个形参（err, req, res, next），Express 据此识别错误中间件。
 */

import { fail, CODE } from '../utils/result.js'

export function notFoundHandler(req, res) {
  res.status(404).json(fail(CODE.NOT_FOUND, `接口不存在：${req.method} ${req.path}`))
}

// eslint-disable-next-line no-unused-vars
export function errorHandler(err, req, res, next) {
  // express.json() 解析失败时抛出 type 为 entity.parse.failed 的错误，属于客户端参数错误
  if (err && err.type === 'entity.parse.failed') {
    return res.json(fail(CODE.PARAM_ERROR, '请求体不是合法的 JSON'))
  }

  console.error(`[ERROR] ${req.method} ${req.originalUrl}`)
  console.error(err && err.stack ? err.stack : err)

  res.status(500).json(fail(CODE.INTERNAL_ERROR, '服务器内部错误'))
}
