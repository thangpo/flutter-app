// G:\flutter-app\lib\features\social\controllers\group_chat_controller.dart
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

  // ---------- Messages & pagination ----------
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

      final localList = (_messagesByGroup[groupId] ?? [])
          .where((m) => m['is_local'] == true)
          .toList();

      final normalized = serverList.map(_normalizeServerMessage).toList();

      _setMessages(groupId, [...normalized, ...localList]);
    } catch (e) {
      lastError = e.toString();
    } finally {
      _messagesLoadingByGroup[groupId] = false;
      notifyListeners();
    }
  }

  Future<void> loadOlderMessages(String groupId, String beforeMessageId) async {
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
      _setMessages(groupId, [...normalized, ...current]);
      notifyListeners();
    } catch (e) {
      lastError = e.toString();
      notifyListeners();
    }
  }

  // ---------- Send message (text / image / video / voice / file) ----------
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

    // 1) Optimistic UI
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

    try {
      final serverMsg = await repo.sendMessage(
        groupId: groupId,
        text: text,
        file: file,
        type: type,
        messageHashId: msgHash,
      );

      final list = _messagesByGroup[groupId];
      if (list == null) {
        notifyListeners();
        return;
      }

      final idx = list.indexWhere(
        (m) => m['is_local'] == true && m['message_hash_id'] == msgHash,
      );

      if (idx == -1) {
        if (serverMsg != null) {
          final normalized = _normalizeServerMessage(serverMsg);
          list.add(normalized);
          _setMessages(groupId, List<Map<String, dynamic>>.from(list));
          notifyListeners();
        }
        return;
      }

      final currentLocal = Map<String, dynamic>.from(list[idx]);
      currentLocal['uploading'] = false;
      currentLocal['failed'] = false;
      currentLocal['is_local'] = false;

      if (serverMsg != null) {
        final normalized = _normalizeServerMessage(serverMsg);
        currentLocal
          ..addAll({
            'id': normalized['id'] ?? currentLocal['id'],
            'display_text':
                normalized['display_text'] ?? currentLocal['display_text'],
            'text': normalized['text'] ?? currentLocal['text'],
            'media': normalized['media']?.toString().isNotEmpty == true
                ? normalized['media']
                : currentLocal['media'],
            'mediaFileName':
                normalized['mediaFileName'] ?? currentLocal['mediaFileName'],
            'type_two': normalized['type_two'] ?? currentLocal['type_two'],
            'is_image': normalized['is_image'] ?? currentLocal['is_image'],
            'is_video': normalized['is_video'] ?? currentLocal['is_video'],
            'is_audio': normalized['is_audio'] ?? currentLocal['is_audio'],
            'is_file': normalized['is_file'] ?? currentLocal['is_file'],
            'time': normalized['time'] ?? currentLocal['time'],
            'uploading': false,
            'failed': false,
            'is_local': false,
          });
      }

      list[idx] = currentLocal;
      _setMessages(groupId, List<Map<String, dynamic>>.from(list));
      notifyListeners();
    } catch (e) {
      final list = _messagesByGroup[groupId];
      if (list != null) {
        final idx = list.indexWhere(
          (m) => m['is_local'] == true && m['message_hash_id'] == msgHash,
        );
        if (idx != -1) {
          final failedMap = {
            ...list[idx],
            'uploading': false,
            'failed': true,
          };
          list[idx] = failedMap;
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

  // ---------- Edit group ----------
  bool editingGroup = false;

  Future<bool> editGroup({
    required String groupId,
    String? name,
    File? avatarFile,
  }) async {
    editingGroup = true;
    lastError = null;
    notifyListeners();

    try {
      final updated = await repo.editGroup(
        groupId: groupId,
        name: name,
        avatarFile: avatarFile,
      );

      final idx =
          groups.indexWhere((g) => '${g['group_id'] ?? g['id']}' == groupId);
      if (idx != -1) {
        final cur = Map<String, dynamic>.from(groups[idx]);

        final newName = (updated['group_name'] ?? name ?? '').toString().trim();
        if (newName.isNotEmpty) {
          cur['group_name'] = newName;
          cur['name'] = newName;
          addSystemMessage(groupId, '✏️ Đã đổi tên nhóm thành "$newName"');
        }

        var newAvatar = (updated['avatar'] ?? '').toString();
        if (newAvatar.isNotEmpty &&
            (newAvatar.startsWith('http://') ||
                newAvatar.startsWith('https://'))) {
          final sep = newAvatar.contains('?') ? '&' : '?';
          newAvatar =
              '$newAvatar${sep}cb=${DateTime.now().millisecondsSinceEpoch}';
          cur['avatar'] = newAvatar;
          cur['group_avatar'] = newAvatar;
          addSystemMessage(groupId, '🖼️ Đã đổi ảnh nhóm');
        }

        groups[idx] = cur;
      }

      notifyListeners();
      return true;
    } catch (e) {
      lastError = e.toString();
      notifyListeners();
      return false;
    } finally {
      editingGroup = false;
      notifyListeners();
    }
  }

  // ---------- Members ----------
  Map<String, List<Map<String, dynamic>>> _membersByGroup = {};

  Future<void> loadGroupMembers(String groupId) async {
    final members = await repo.fetchGroupMembers(groupId);
    _membersByGroup[groupId] = members;
    notifyListeners();
  }

  List<Map<String, dynamic>> membersOf(String groupId) =>
      _membersByGroup[groupId] ?? [];

  List<String> existingMemberIdsOf(String groupId) {
    final members = _membersByGroup[groupId];
    if (members == null) return [];
    return members
        .map((m) => '${m['user_id'] ?? m['id'] ?? ''}')
        .where((id) => id.isNotEmpty)
        .toList();
  }

  Future<bool> addUsers(String groupId, List<String> ids) async {
    try {
      final ok = await repo.addUsersToGroup(groupId, ids);
      if (ok) {
        await loadGroupMembers(groupId);

        final members = _membersByGroup[groupId] ?? [];
        final addedNames = members
            .where((m) {
              final idStr = '${m['user_id'] ?? m['id'] ?? ''}';
              return ids.contains(idStr);
            })
            .map((m) => (m['name'] ?? m['username'] ?? '').toString())
            .where((n) => n.isNotEmpty)
            .join(', ');

        addSystemMessage(
          groupId,
          addedNames.isNotEmpty
              ? '👥 Đã thêm $addedNames vào nhóm'
              : '👥 Đã thêm ${ids.length} thành viên vào nhóm',
        );
      }
      return ok;
    } catch (e) {
      lastError = e.toString();
      notifyListeners();
      return false;
    }
  }


  Future<bool> removeUsers(String groupId, List<String> ids) async {
    final ok = await repo.removeGroupUsers(groupId, ids);
    if (ok) {
      final removedNames = <String>[];
      final members = _membersByGroup[groupId] ?? [];
      for (final id in ids) {
        final user = members.firstWhere(
          (u) => '${u['user_id'] ?? u['id'] ?? ''}' == id,
          orElse: () => {},
        );
        if (user.isNotEmpty) {
          removedNames
              .add('${user['name'] ?? user['username'] ?? 'Người dùng'}');
        }
      }
      _membersByGroup[groupId]?.removeWhere(
          (u) => ids.contains('${u['user_id'] ?? u['id'] ?? ''}'));
      notifyListeners();

      final namesText = removedNames.join(', ');
      addSystemMessage(groupId, '❌ Đã xoá $namesText khỏi nhóm');
    }
    return ok;
  }

  // ---------- System Message ----------
  void addSystemMessage(String groupId, String text) {
    final list = _messagesByGroup[groupId] ?? [];
    final msg = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'display_text': text,
      'is_system': true,
      'time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
    list.add(msg);
    list.sort((a, b) {
      final aTime = int.tryParse('${a['time'] ?? 0}') ?? 0;
      final bTime = int.tryParse('${b['time'] ?? 0}') ?? 0;
      return aTime.compareTo(bTime);
    });
    _messagesByGroup[groupId] = list;
    notifyListeners();
  }

}
