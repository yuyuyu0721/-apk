/**
 * Result<T> 响应包装工具
 *
 * 后端所有路由都通过这两个函数返回响应，
 * 保证响应体结构（code/msg/data）与接口文档完全一致。
 */

/**
 * 成功响应
 * @param {object|array|null} [data] 业务数据（可选）
 * @param {string} [msg='success']   提示信息
 * @returns {{code: 0, msg: string, data?: any}}
 */
export function ok(data, msg = 'success') {
  const body = { code: 0, msg }
  if (data !== undefined) {
    body.data = data
  }
  return body
}

/**
 * 失败响应
 * @param {number} code 业务状态码（非 0）
 * @param {string} msg  失败原因
 * @returns {{code: number, msg: string}}
 */
export function fail(code, msg) {
  return { code, msg }
}

/**
 * 业务状态码常量（与接口文档 2.4 节一致）
 */
export const CODE = {
  OK: 0,
  PARAM_ERROR: 1001,
  LOGIN_FAILED: 1002,
  NOT_FOUND: 1003,
  TOKEN_INVALID: 1101,
  TOKEN_EXPIRED: 1102,
  DEVICE_OFFLINE: 1201,
  DEVICE_BUSY: 1202,
  INTERNAL_ERROR: 5000,
}
