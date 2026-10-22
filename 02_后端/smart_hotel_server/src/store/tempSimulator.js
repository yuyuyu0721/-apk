/**
 * 空调当前温度（currentTemp）逼近模拟器
 *
 * 模拟真实空调"设定温度后室温慢慢逼近"的物理过程：
 *   - 每秒检查所有房间
 *   - 若空调 on=true 且 currentTemp != targetTemp，则向 targetTemp 走 0.5℃
 *   - 空调关闭时室温保持不变
 *
 * 启动一次即可（在 index.js 中调用 startTempSimulator()），
 * 进程退出时 Node 自动回收 setInterval。
 */

import { config } from '../config.js'
import { getAllRooms } from './rooms.js'

let timer = null

export function startTempSimulator() {
  if (timer) return

  timer = setInterval(() => {
    for (const room of getAllRooms()) {
      const ac = room.ac
      if (!ac.on) continue
      if (ac.currentTemp === ac.targetTemp) continue

      const diff = ac.targetTemp - ac.currentTemp
      const step = Math.sign(diff) * Math.min(config.TEMP_STEP, Math.abs(diff))
      // 用 round 防止浮点数累计误差（如 22.499999...）
      ac.currentTemp = Math.round((ac.currentTemp + step) * 10) / 10
    }
  }, config.TEMP_INTERVAL_MS)
}

export function stopTempSimulator() {
  if (timer) {
    clearInterval(timer)
    timer = null
  }
}
