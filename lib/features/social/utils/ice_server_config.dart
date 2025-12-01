// lib/features/social/utils/ice_server_config.dart
// Chứa cấu hình ICE (STUN/TURN) dùng chung cho 1-1 và group.

const List<Map<String, dynamic>> kDefaultIceServers = [
  {
    'urls': [
      'stun:stun.l.google.com:19302',
      'stun:stun1.l.google.com:19302',
    ],
  },
  // TURN UDP/TCP/TLS – cập nhật host/credential theo máy chủ coturn thực tế
  {
    'urls': [
      'turn:social.vnshop247.com:3478?transport=udp',
      'turn:social.vnshop247.com:3478?transport=tcp',
      'turns:social.vnshop247.com:5349?transport=tcp',
    ],
    'username': 'webrtc',
    'credential': 'supersecret',
  },
];

