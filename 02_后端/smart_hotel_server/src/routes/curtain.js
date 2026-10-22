/**
 * 窗帘域路由
 *
 *   POST /api/curtain/control   单窗帘 open/pause/close
 *   POST /api/curtain/batch     全部 open/close
 */

import { Router } from 'express'
import { ok, fail, CODE } from '../utils/result.js'
import { authRequired } from '../middleware/auth.js'
import { getRoom, controlCurtain, batchCurtain } from '../store/rooms.js'

export const curtainRouter = Router()

const VALID_ACTIONS = new Set(['open', 'pause', 'close'])
const VALID_BATCH_ACTIONS = new Set(['open', 'close'])
// 模拟后端没有"运动中"的过渡状态：收到动作即直接落到目标状态，文案与状态保持一致
const ACTION_MSG = { open: '已打开', pause: '已暂停', close: '已关闭' }

/**
 * POST /api/curtain/control
 * body: { id: CurtainId, action: 'open'|'pause'|'close' }
 * 动作直接映射为状态：open→opened、pause→paused、close→closed（任何当前状态下均生效）
 */
curtainRouter.post('/control', authRequired, (req, res) => {
  const { id, action } = req.body || {}
  if (typeof id !== 'string' || !id) {
    return res.json(fail(CODE.PARAM_ERROR, 'id 字段不能为空'))
  }
  if (!VALID_ACTIONS.has(action)) {
    return res.json(fail(CODE.PARAM_ERROR, `无效的动作：${action}`))
  }

  const room = getRoom(req.roomNo)
  const curtain = controlCurtain(room, id, action)
  if (!curtain) {
    return res.json(fail(CODE.PARAM_ERROR, `未知的窗帘 id：${id}`))
  }

  res.json(ok(curtain, `${curtain.name}${ACTION_MSG[action]}`))
})

/**
 * POST /api/curtain/batch
 * body: { action: 'open' | 'close' }
 */
curtainRouter.post('/batch', authRequired, (req, res) => {
  const { action } = req.body || {}
  if (!VALID_BATCH_ACTIONS.has(action)) {
    return res.json(fail(CODE.PARAM_ERROR, `批量操作仅支持 open 或 close`))
  }

  const room = getRoom(req.roomNo)
  batchCurtain(room, action)
  res.json(ok({
    curtains: room.curtains,
  }, action === 'open' ? '全部窗帘已打开' : '全部窗帘已关闭'))
})
