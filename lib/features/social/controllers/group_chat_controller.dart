import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/group_chat_repository.dart';

class GroupChatController extends ChangeNotifier {
  GroupChatController(this.repo) {
    _reloadCurrentUser();
  }

  final GroupChatRepository repo;

  // ---------- User ----------
  String? currentUserId;
  Future<void> _reloadCurrentUser() async {
    try {
      final sp = await SharedPreferences.getInstance();
      currentUserId = sp.getString(AppConstants.socialUserId);
      notifyListeners();
    } catch (_) {}
  }

  // ---------- Groups ----------
  bool groupsLoading = false;
  List<Map<String, dynamic>> groups = [];

  Future<void> loadGroups() async {
    groupsLoading = true;
    lastError = null;
    notifyListeners();
    try {
      final list = await repo.fetchGroups();
      groups = list;
    } catch (e) {
      lastError = e.toString();
    } finally {
      groupsLoading = false;
      notifyListeners();
    }
  }

  bool creatingGroup = false;
  Future<bool> createGroup({
    required String name,
    required List<String> memberIds,
    File? avatarFile,
  }) async {
    creatingGroup = true;
    lastError = null;
    notifyListeners();
    try {
      final ok = await repo.createGroup(
        name: name,
        memberIds: memberIds,
        avatarFile: avatarFile,
      );
      if (ok) {
        await loadGroups();
      }
      return ok;
    } catch (e) {
      lastError = e.toString();
      return false;
    } finally {
      creatingGroup = false;
      notifyListeners();
    }
  }

  // ---------- Messages ----------
  final Map<String, List<Map<String, dynamic>>> _messagesByGroup = {};
  final Map<String, bool> _messagesLoadingByGroup = {};
  String? lastError;

  List<Map<String, dynamic>> messagesOf(String groupId) =>
      _messagesByGroup[groupId] ?? const [];

  bool messagesLoading(String groupId) =>
      _messagesLoadingByGroup[groupId] == true;

  void _setMessages(String groupId, List<Map<String, dynamic>> items) {
    items.sort((a, b) {
      final ta = int.tryParse('${a['time'] ?? 0}') ?? 0;
      final tb = int.tryParse('${b['time'] ?? 0}') ?? 0;
      return ta.compareTo(tb);
    });
    _messagesByGroup[groupId] = items;
  }

  Map<String, dynamic> _normalizeServerMessage(Map raw) {
    final m = Map<String, dynamic>.from(raw);
    final typeTwo = (m['type_two'] ?? '').toString();
    final media = (m['media'] ?? '').toString();
    final fileName = (m['mediaFileName'] ?? '').toString();
    final text = (m['text'] ?? '').toString();

    final isImage = (m['is_image'] == true) ||
        media.endsWith('.jpg') ||
        media.endsWith('.jpeg') ||
        media.endsWith('.png') ||
        media.endsWith('.gif') ||
        media.endsWith('.webp');
    final isVideo = (m['is_video'] == true) ||
        media.endsWith('.mp4') ||
        media.endsWith('.mov') ||
        media.endsWith('.mkv');
    final isAudio = (m['is_audio'] == true) || typeTwo == 'voice';
    final isFile = (m['is_file'] == true) ||
        (!isImage && !isVideo && !isAudio && media.isNotEmpty);

    return {
      ...m,
      'display_text': m['display_text'] ?? text,
      'media': media,
      'mediaFileName': fileName.isNotEmpty
          ? fileName
          : (media.split('?').first.split('/').last),
      'is_image': isImage,
      'is_video': isVideo,
      'is_audio': isAudio,
      'is_file': isFile,
      'is_local': false,
      'uploading': false,
      'failed': false,
    };
  }

  Future<void> loadMessages(String groupId) async {
    _messagesLoadingByGroup[groupId] = true;
    lastError = null;
    notifyListeners();
    try {
      final serverList = await repo.fetchMessages(groupId);

      // Giữ local chưa sync
      final localList = (_messagesByGroup[groupId] ?? [])
          .where((m) => m['is_local'] == true)
          .toList();

      // FIX: loại local trùng message_hash_id với server
      final serverHashes = serverList
          .map((m) => m['message_hash_id']?.toString())
          .where((h) => h != null && h!.isNotEmpty)
          .toSet();

      final localFiltered = localList
          .where(
              (m) => !serverHashes.contains(m['message_hash_id']?.toString()))
          .toList();

      final normalized = serverList.map(_normalizeServerMessage).toList();
      _setMessages(groupId, [...normalized, ...localFiltered]);
    } catch (e) {
      lastError = e.toString();
    } finally {
      _messagesLoadingByGroup[groupId] = false;
      notifyListeners();
    }
  }

  /// 🔼 Tải thêm tin nhắn cũ (prepend)
  Future<void> loadOlderMessages(String groupId, String beforeMessageId) async {
    // Nếu đang loading chính thì bỏ qua
    if (messagesLoading(groupId)) return;
    lastError = null;
    try {
      final older = await repo.fetchOlderMessages(
        groupId,
        beforeMessageId: beforeMessageId,
      );
      if (older.isEmpty) return;

      final normalized = older.map(_normalizeServerMessage).toList();
      final current = List<Map<String, dynamic>>.from(messagesOf(groupId));

      // Gộp (older trước, current sau) rồi khử trùng theo 'id'
      final merged = [...normalized, ...current];
      final seen = <String>{};
      final dedup = <Map<String, dynamic>>[];
      for (final m in merged) {
        final id = '${m['id'] ?? ''}';
        if (id.isEmpty || !seen.contains(id)) {
          dedup.add(m);
          if (id.isNotEmpty) seen.add(id);
        }
      }

      _setMessages(groupId, dedup);
      notifyListeners();
    } catch (e) {
      lastError = e.toString();
      notifyListeners();
    }
  }

  // ---------- Send message ----------
  final _rng = Random();
  String _tempId() =>
      'local_${DateTime.now().millisecondsSinceEpoch}_${_rng.nextInt(999999)}';
  String _tempHash() =>
      'hash_${DateTime.now().millisecondsSinceEpoch}_${_rng.nextInt(999999)}';

  Map<String, dynamic> _makeLocalMessage({
    required String groupId,
    required String text,
    File? file,
    String? type,
    required String msgHash,
  }) {
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final isImage = type == 'image';
    final isVideo = type == 'video';
    final isAudio = type == 'voice';
    final isFile = type == 'file';

    final mediaUri = file == null
        ? ''
        : (file.path.startsWith('file://') ? file.path : 'file://${file.path}');

    return {
      'id': _tempId(),
      'group_id': groupId,
      'from_id': currentUserId,
      'text': text,
      'display_text': text,
      'media': mediaUri,
      'mediaFileName': file == null ? null : p.basename(file.path),
      'type_two': isAudio ? 'voice' : null,
      'is_image': isImage,
      'is_video': isVideo,
      'is_audio': isAudio,
      'is_file': isFile,
      'is_local': true,
      'uploading': file != null,
      'failed': false,
      'time': nowSec,
      'message_hash_id': msgHash,
      'user_data': {'user_id': currentUserId},
    };
  }

  Future<void> sendMessage(
    String groupId,
    String text, {
    File? file,
    String? type,
  }) async {
    lastError = null;
    final msgHash = _tempHash();

    // 1️⃣ Optimistic UI: thêm local trước
    final local = _makeLocalMessage(
      groupId: groupId,
      text: text,
      file: file,
      type: type,
      msgHash: msgHash,
    );
    final cur = [...messagesOf(groupId), local];
    _setMessages(groupId, cur);
    notifyListeners();

    // 2️⃣ Gửi API
    try {
      await repo.sendMessage(
        groupId: groupId,
        text: text,
        file: file,
        type: type,
        messageHashId: msgHash,
      );

      // 🟢 FIX: sau khi gửi xong, xóa local message tạm để không bị trùng
      final list = _messagesByGroup[groupId];
      if (list != null) {
        list.removeWhere((m) => m['id'] == local['id']);
        _setMessages(groupId, List<Map<String, dynamic>>.from(list));
      }

      // 3️⃣ Reload để lấy message thật từ server
      await loadMessages(groupId);
    } catch (e) {
      // ❌ Đánh dấu lỗi lên local
      final list = _messagesByGroup[groupId];
      if (list != null) {
        final idx = list.indexWhere((m) => m['id'] == local['id']);
        if (idx != -1) {
          list[idx] = {
            ...list[idx],
            'uploading': false,
            'failed': true,
          };
          _setMessages(groupId, List<Map<String, dynamic>>.from(list));
        }
      }
      lastError = e.toString();
      notifyListeners();
    }
  }

  // ---------- Utils ----------
  bool isMyMessage(Map<String, dynamic> message) {
    final fromId = message['from_id']?.toString();
    final me = currentUserId?.toString();
    return (fromId != null && me != null && fromId == me);
  }
}
