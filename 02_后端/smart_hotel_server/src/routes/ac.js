/**
 * 空调域路由
 *
 *   POST /api/ac/power         开关
 *   POST /api/ac/temperature   设置目标温度
 */

import { Router } from 'express'
import { ok, fail, CODE } from '../utils/result.js'
import { authRequired } from '../middleware/auth.js'
import { getRoom } from '../store/rooms.js'

export const acRouter = Router()

/**
 * POST /api/ac/power
 * body: { on: boolean }
 */
acRouter.post('/power', authRequired, (req, res) => {
  const { on } = req.body || {}
  if (typeof on !== 'boolean') {
    return res.json(fail(CODE.PARAM_ERROR, 'on 字段必须是布尔值'))
  }

  const room = getRoom(req.roomNo)
  room.ac.on = on
  res.json(ok(room.ac, on ? '已开机' : '已关机'))
})

/**
 * POST /api/ac/temperature
 * body: { targetTemp: number }   整数，范围 [minTemp, maxTemp]
 *
 * 限制为整数：currentTemp 按 0.5℃ 步长逼近并保留 1 位小数，
 * 若允许 24.37 这类值，currentTemp 会停在 24.4 永远达不到目标温度。
 */
acRouter.post('/temperature', authRequired, (req, res) => {
  const { targetTemp } = req.body || {}

  if (typeof targetTemp !== 'number' || !Number.isInteger(targetTemp)) {
    return res.json(fail(CODE.PARAM_ERROR, 'targetTemp 必须是整数'))
  }

  const room = getRoom(req.roomNo)
  const { minTemp, maxTemp } = room.ac
  if (targetTemp < minTemp || targetTemp > maxTemp) {
    return res.json(fail(
      CODE.PARAM_ERROR,
      `目标温度必须在 ${minTemp}℃ 到 ${maxTemp}℃ 之间`
    ))
  }

  room.ac.targetTemp = targetTemp
  res.json(ok(room.ac, `温度已设置为 ${targetTemp}℃`))
})
