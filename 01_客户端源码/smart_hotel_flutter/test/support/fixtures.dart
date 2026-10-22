import 'dart:convert';

import 'package:http/http.dart' as http;

/// 测试夹具：一份完整整房快照 + 统一响应构造，避免各测试文件重复拼 JSON
Map<String, dynamic> snapshotJson({bool acOn = false, bool masterLight = false}) {
  return <String, dynamic>{
    'room': <String, dynamic>{
      'roomNo': '1209',
      'guestName': '乔安',
      'checkInDate': '2026-05-26',
    },
    'ac': <String, dynamic>{
      'on': acOn,
      'targetTemp': 20,
      'currentTemp': 22,
      'minTemp': 16,
      'maxTemp': 30,
    },
    'scenes': <Map<String, dynamic>>[
      <String, dynamic>{'id': 'bright', 'name': '明亮模式', 'icon': 'sun'},
      <String, dynamic>{'id': 'soft', 'name': '柔和模式', 'icon': 'moon'},
      <String, dynamic>{'id': 'reading', 'name': '阅读模式', 'icon': 'book'},
      <String, dynamic>{'id': 'cozy', 'name': '温馨模式', 'icon': 'heart'},
      <String, dynamic>{'id': 'sleep', 'name': '睡眠模式', 'icon': 'crescent'},
    ],
    'activeSceneId': null,
    'masterLight': masterLight,
    'lights': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'bath',
        'name': '洗漱间',
        'icon': 'bath',
        'on': false
      },
      <String, dynamic>{
        'id': 'wardrobe',
        'name': '衣柜灯',
        'icon': 'wardrobe',
        'on': false
      },
      <String, dynamic>{
        'id': 'floor',
        'name': '落地灯',
        'icon': 'floor',
        'on': false
      },
      <String, dynamic>{'id': 'bar', 'name': '吧灯', 'icon': 'bar', 'on': false},
      <String, dynamic>{
        'id': 'readLeft',
        'name': '左阅读灯',
        'icon': 'readLeft',
        'on': false
      },
      <String, dynamic>{
        'id': 'readRight',
        'name': '右阅读灯',
        'icon': 'readRight',
        'on': false
      },
      <String, dynamic>{
        'id': 'desk',
        'name': '书桌灯',
        'icon': 'desk',
        'on': false
      },
      <String, dynamic>{'id': 'fan', 'name': '排风扇', 'icon': 'fan', 'on': false},
      <String, dynamic>{
        'id': 'corridor',
        'name': '廊灯',
        'icon': 'corridor',
        'on': false
      },
    ],
    'curtains': <Map<String, dynamic>>[
      <String, dynamic>{'id': 'cloth', 'name': '布帘', 'status': 'closed'},
      <String, dynamic>{'id': 'sheer', 'name': '窗纱', 'status': 'closed'},
    ],
    'services': <String, dynamic>{'doNotDisturb': false, 'cleaning': false},
  };
}

Map<String, dynamic> loginJson() {
  return <String, dynamic>{
    'token': 'test-token',
    'userInfo': <String, dynamic>{
      'roomNo': '1209',
      'guestName': '乔安',
      'checkInDate': '2026-05-26',
    },
  };
}

http.Response jsonResponse(Object body, int status) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: <String, String>{
      'content-type': 'application/json; charset=utf-8'
    },
  );
}

http.Response okResponse(Object data, {String msg = 'success'}) {
  return jsonResponse(
      <String, dynamic>{'code': 0, 'msg': msg, 'data': data}, 200);
}
