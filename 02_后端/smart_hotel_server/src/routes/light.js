/**
 * 灯光域路由
 *
 *   POST /api/light/master   总开关
 *   POST /api/light/scene    切换场景模式
 *   POST /api/light/toggle   单灯开关
 */

import { Router } from 'express'
import { ok, fail, CODE } from '../utils/result.js'
import { authRequired } from '../middleware/auth.js'
import {
  getRoom,
  applyScene,
  setMasterLight,
  toggleLight,
  SCENES,
} from '../store/rooms.js'

export const lightRouter = Router()

/**
 * 公开场景 id 集合
 *   - SCENES 列表中的 5 个公开场景
 *   - goodnight：晚安模式（一键全关），不出现在 SCENES 列表里
 *   - off：用于"退出已激活的场景"，仅清 activeSceneId，不动灯具
 *     （首页 晚安卡片 重复点击时使用，让 UI 高亮回到未选中态）
 */
const VALID_SCENE_IDS = new Set([...SCENES.map(s => s.id), 'goodnight', 'off'])

/**
 * POST /api/light/master
 * body: { on: boolean }
 */
lightRouter.post('/master', authRequired, (req, res) => {
  const { on } = req.body || {}
  if (typeof on !== 'boolean') {
    return res.json(fail(CODE.PARAM_ERROR, 'on 字段必须是布尔值'))
  }

  const room = getRoom(req.roomNo)
  setMasterLight(room, on)
  // 总开关会把 activeSceneId 改为 bright / goodnight，一并返回，客户端据此同步场景高亮
  res.json(ok({
    activeSceneId: room.activeSceneId,
    masterLight: room.masterLight,
    lights: room.lights,
  }, on ? '已打开所有灯光' : '已关闭所有灯光'))
})

/**
 * POST /api/light/scene
 * body: { sceneId: SceneId }
 */
lightRouter.post('/scene', authRequired, (req, res) => {
  const { sceneId } = req.body || {}
  if (!sceneId || !VALID_SCENE_IDS.has(sceneId)) {
    return res.json(fail(CODE.PARAM_ERROR, '无效的场景 ID'))
  }

  const room = getRoom(req.roomNo)

  // 特殊场景：'off' 表示退出当前已选场景，仅清 activeSceneId 不动灯具
  // 给前端做"晚安模式重复点击→取消高亮"的能力（灯具保持现状）
  if (sceneId === 'off') {
    room.activeSceneId = null
    return res.json(ok({
      activeSceneId: null,
      masterLight: room.masterLight,
      lights: room.lights,
    }, '已退出场景模式'))
  }

  applyScene(room, sceneId)

  const sceneName = SCENES.find(s => s.id === sceneId)?.name ?? '晚安模式'
  res.json(ok({
    activeSceneId: room.activeSceneId,
    masterLight: room.masterLight,
    lights: room.lights,
  }, `已切换到${sceneName}`))
})

/**
 * POST /api/light/toggle
 * body: { id: LightId, on: boolean }
 */
lightRouter.post('/toggle', authRequired, (req, res) => {
  const { id, on } = req.body || {}
  if (typeof id !== 'string' || !id) {
    return res.json(fail(CODE.PARAM_ERROR, 'id 字段不能为空'))
  }
  if (typeof on !== 'boolean') {
    return res.json(fail(CODE.PARAM_ERROR, 'on 字段必须是布尔值'))
  }

  const room = getRoom(req.roomNo)
  const light = toggleLight(room, id, on)
  if (!light) {
    return res.json(fail(CODE.PARAM_ERROR, `未知的灯具 id：${id}`))
  }

  res.json(ok({
    light,
    masterLight: room.masterLight,
    activeSceneId: room.activeSceneId,
  }, `${light.name}已${on ? '开启' : '关闭'}`))
})
