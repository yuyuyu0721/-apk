/**
 * 房间状态内存存储
 *
 * 数据结构：Map<roomNo, RoomState>
 *   - 一个房间一份完整的 snapshot 对象
 *   - 所有路由处理函数都通过 getRoom(roomNo) 拿到 RoomState 后直接 mutation
 *   - 重启服务会清空 Map 并重新填充 DEFAULT_ROOMS，所以不用考虑长期演化
 *
 * 本文件还集中维护：
 *   - 灯具默认列表（顺序与 UI 一致）
 *   - 5 + 1 个场景的灯具预设（明亮/柔和/阅读/温馨/睡眠/晚安）
 *   - 默认测试账号
 */

// ==================== 静态元数据 ====================

/** 灯具元数据（顺序与 UI"独立控制"区一致）*/
const LIGHT_META = [
  { id: 'bath',      name: '洗漱间',   icon: 'bath' },
  { id: 'wardrobe',  name: '衣柜灯',   icon: 'wardrobe' },
  { id: 'floor',     name: '落地灯',   icon: 'floor' },
  { id: 'bar',       name: '吧灯',     icon: 'bar' },
  { id: 'readLeft',  name: '左阅读灯', icon: 'readLeft' },
  { id: 'readRight', name: '右阅读灯', icon: 'readRight' },
  { id: 'desk',      name: '书桌灯',   icon: 'desk' },
  { id: 'fan',       name: '排风扇',   icon: 'fan' },
  { id: 'corridor',  name: '廊灯',     icon: 'corridor' },
]

/** 场景元数据（5 个公开场景；goodnight 隐藏，仅由首页晚安卡片触发）*/
export const SCENES = [
  { id: 'bright',  name: '明亮模式', icon: 'sun' },
  { id: 'soft',    name: '柔和模式', icon: 'moon' },
  { id: 'reading', name: '阅读模式', icon: 'book' },
  { id: 'cozy',    name: '温馨模式', icon: 'heart' },
  { id: 'sleep',   name: '睡眠模式', icon: 'crescent' },
]

/**
 * 场景灯具预设
 *   key   = sceneId
 *   value = 该场景下应该开启的灯具 id 集合
 *   不在集合中的灯一律关闭
 */
const SCENE_PRESETS = {
  bright:    new Set(['bath', 'wardrobe', 'floor', 'bar', 'readLeft', 'readRight', 'desk', 'fan', 'corridor']),
  soft:      new Set(['floor', 'readLeft', 'readRight']),
  reading:   new Set(['readLeft', 'readRight', 'desk']),
  cozy:      new Set(['floor', 'bar']),
  sleep:     new Set(['corridor']),
  goodnight: new Set(),   // 一键全关
}

/** 窗帘元数据 */
const CURTAIN_META = [
  { id: 'cloth', name: '布帘' },
  { id: 'sheer', name: '窗纱' },
]

// ==================== 默认房间数据 ====================

/** 默认测试账号（roomNo + guestName 用于登录校验）*/
const DEFAULT_ROOMS = [
  { roomNo: '1209', guestName: '乔安', checkInDate: '2026-05-26' },
  { roomNo: '1210', guestName: '张明', checkInDate: '2026-05-26' },
  { roomNo: '1211', guestName: '李娜', checkInDate: '2026-05-26' },
]

/**
 * 构造一份房间的初始 snapshot
 * @param {{roomNo: string, guestName: string, checkInDate: string}} info
 * @returns {RoomState}
 */
function buildDefaultRoom(info) {
  return {
    room: { ...info },
    ac: {
      on: false,
      targetTemp: 20,
      currentTemp: 22,
      minTemp: 16,
      maxTemp: 30,
    },
    activeSceneId: null,
    masterLight: false,
    lights: LIGHT_META.map(meta => ({ ...meta, on: false })),
    curtains: CURTAIN_META.map(meta => ({ ...meta, status: 'closed' })),
    services: {
      doNotDisturb: false,
      cleaning: false,
    },
  }
}

// ==================== 存储与访问 ====================

/** 内存存储：Map<roomNo, RoomState> */
const rooms = new Map()

/** 启动时调用：把所有默认房间灌入内存 */
export function initRooms() {
  rooms.clear()
  for (const info of DEFAULT_ROOMS) {
    rooms.set(info.roomNo, buildDefaultRoom(info))
  }
}

/**
 * 取房间状态
 * @param {string} roomNo
 * @returns {RoomState | undefined}
 */
export function getRoom(roomNo) {
  return rooms.get(roomNo)
}

/** 取全部房间状态（温度逼近定时器用）*/
export function getAllRooms() {
  return rooms.values()
}

/**
 * 校验登录凭证
 * @param {string} roomNo
 * @param {string} guestName
 * @returns {boolean}
 */
export function validateCredential(roomNo, guestName) {
  const room = rooms.get(roomNo)
  return room !== undefined && room.room.guestName === guestName
}

/**
 * 组装整房快照（GET /api/room/snapshot 的响应数据）
 * 把 SCENES 静态元数据拼到 RoomState 上一起返回
 */
export function buildSnapshot(roomNo) {
  const room = rooms.get(roomNo)
  if (!room) return null
  return {
    room: room.room,
    ac: room.ac,
    scenes: SCENES,
    activeSceneId: room.activeSceneId,
    masterLight: room.masterLight,
    lights: room.lights,
    curtains: room.curtains,
    services: room.services,
  }
}

// ==================== 业务操作 ====================

/**
 * 按场景 ID 应用灯具预设
 * @param {RoomState} room
 * @param {string} sceneId
 * @returns {boolean} 是否是有效场景 ID
 */
export function applyScene(room, sceneId) {
  const preset = SCENE_PRESETS[sceneId]
  if (!preset) return false

  for (const light of room.lights) {
    light.on = preset.has(light.id)
  }
  // 总开关：任意灯亮即为 true
  room.masterLight = room.lights.some(l => l.on)
  room.activeSceneId = sceneId
  return true
}

/**
 * 设置总开关
 * @param {RoomState} room
 * @param {boolean} on
 */
export function setMasterLight(room, on) {
  for (const light of room.lights) {
    light.on = on
  }
  room.masterLight = on
  room.activeSceneId = on ? 'bright' : 'goodnight'
}

/**
 * 切换单灯
 * @param {RoomState} room
 * @param {string} lightId
 * @param {boolean} on
 * @returns {LightItem | null} 被更新的灯，找不到返回 null
 */
export function toggleLight(room, lightId, on) {
  const light = room.lights.find(l => l.id === lightId)
  if (!light) return null
  light.on = on
  room.masterLight = room.lights.some(l => l.on)
  room.activeSceneId = null   // 单灯操作打破场景
  return light
}

/**
 * 控制单个窗帘
 * @param {RoomState} room
 * @param {string} curtainId
 * @param {'open'|'pause'|'close'} action
 * @returns {CurtainItem | null}
 */
export function controlCurtain(room, curtainId, action) {
  const curtain = room.curtains.find(c => c.id === curtainId)
  if (!curtain) return null
  const statusMap = { open: 'opened', pause: 'paused', close: 'closed' }
  curtain.status = statusMap[action]
  return curtain
}

/**
 * 批量窗帘
 * @param {RoomState} room
 * @param {'open'|'close'} action
 */
export function batchCurtain(room, action) {
  const status = action === 'open' ? 'opened' : 'closed'
  for (const curtain of room.curtains) {
    curtain.status = status
  }
}
