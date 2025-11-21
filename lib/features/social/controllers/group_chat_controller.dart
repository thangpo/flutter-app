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
    // Gộp & chống trùng tin nhắn theo id / message_hash_id
    final dedup = <Map<String, dynamic>>[];

    for (final m in items) {
      final idStr = '${m['id'] ?? m['message_id'] ?? ''}';
      final hashStr = '${m['message_hash_id'] ?? ''}';

      // Nếu cả id lẫn hash đều trống thì cứ add (vd: system message)
      if (idStr.isEmpty && hashStr.isEmpty) {
        dedup.add(m);
        continue;
      }

      // Tìm phần tử đã có cùng id/hash trong dedup (ưu tiên phần tử mới hơn)
      int? existingIndex;
      for (var i = dedup.length - 1; i >= 0; i--) {
        final prev = dedup[i];
        final prevId = '${prev['id'] ?? prev['message_id'] ?? ''}';
        final prevHash = '${prev['message_hash_id'] ?? ''}';

        final sameId = idStr.isNotEmpty && prevId == idStr;
        final sameHash = hashStr.isNotEmpty && prevHash == hashStr;
        if (sameId || sameHash) {
          existingIndex = i;
          break;
        }
      }

      if (existingIndex != null) {
        // merge dữ liệu mới vào (server override local)
        dedup[existingIndex] = {
          ...dedup[existingIndex],
          ...m,
        };
      } else {
        dedup.add(m);
      }
    }

    // Sắp xếp lại theo time tăng dần
    dedup.sort((a, b) {
      final ta = int.tryParse('${a['time'] ?? 0}') ?? 0;
      final tb = int.tryParse('${b['time'] ?? 0}') ?? 0;
      return ta.compareTo(tb);
    });

    _messagesByGroup[groupId] = dedup;
  }

  Map<String, dynamic> _normalizeServerMessage(Map raw) {
    final m = Map<String, dynamic>.from(raw);
    final typeTwo = (m['type_two'] ?? '').toString();
    final media = (m['media'] ?? '').toString();
    final fileName = (m['mediaFileName'] ?? '').toString();
    final text = (m['text'] ?? '').toString();

    // giữ lại hash từ server nếu có
    final msgHash = (m['message_hash_id'] ??
            m['msg_hash'] ??
            m['hash'] ??
            m['message_hash'])
        ?.toString();

    // đảm bảo reply có display_text (phục vụ UI quote)
    if (m['reply'] is Map) {
      final r = Map<String, dynamic>.from(m['reply']);
      final replyText = (r['display_text'] ?? r['text'] ?? '').toString();
      r['display_text'] = replyText;
      m['reply'] = r;
    }

    final lowerMedia = media.toLowerCase();

    final isImage = (m['is_image'] == true) ||
        lowerMedia.endsWith('.jpg') ||
        lowerMedia.endsWith('.jpeg') ||
        lowerMedia.endsWith('.png') ||
        lowerMedia.endsWith('.gif') ||
        lowerMedia.endsWith('.webp');
    final isVideo = (m['is_video'] == true) ||
        lowerMedia.endsWith('.mp4') ||
        lowerMedia.endsWith('.mov') ||
        lowerMedia.endsWith('.mkv');
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
      'is_local': m['is_local'] == true,
      'uploading': m['uploading'] == true,
      'failed': m['failed'] == true,
      if (msgHash != null && msgHash.isNotEmpty) 'message_hash_id': msgHash,
    };
  }

  Future<void> loadMessages(String groupId) async {
    _messagesLoadingByGroup[groupId] = true;
    lastError = null;
    notifyListeners();
    try {
      final serverList = await repo.fetchMessages(groupId);

      // giữ lại local messages (optimistic) nếu có
      final current = List<Map<String, dynamic>>.from(
        (_messagesByGroup[groupId] ?? []),
      );

      // map id/hash -> index
      final Map<String, int> byId = {};
      final Map<String, int> byHash = {};
      for (var i = 0; i < current.length; i++) {
        final idStr = '${current[i]['id'] ?? ''}';
        if (idStr.isNotEmpty) byId[idStr] = i;
        final h = current[i]['message_hash_id']?.toString();
        if (h != null && h.isNotEmpty) byHash[h] = i;
      }

      for (final raw in serverList) {
        final normalized = _normalizeServerMessage(raw);
        final idStr = '${normalized['id'] ?? ''}';
        final h = normalized['message_hash_id']?.toString();

        int? idx;
        if (h != null && h.isNotEmpty && byHash.containsKey(h)) {
          idx = byHash[h];
        } else if (idStr.isNotEmpty && byId.containsKey(idStr)) {
          idx = byId[idStr];
        }

        if (idx != null) {
          // merge vào message hiện có (giữ flag local nếu cần)
          final merged = {
            ...current[idx],
            ...normalized,
            'is_local': false,
            'uploading': false,
            'failed':
                current[idx]['failed'] == true && normalized['failed'] == true
                    ? true
                    : false,
          };
          current[idx] = merged;
        } else {
          current.add(normalized);
          final newIndex = current.length - 1;
          if (idStr.isNotEmpty) byId[idStr] = newIndex;
          if (h != null && h.isNotEmpty) byHash[h] = newIndex;
        }
      }

      _setMessages(groupId, current);
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

      // chèn vào đầu, tránh trùng id
      final existingIds = current
          .map((m) => '${m['id'] ?? ''}')
          .where((s) => s.isNotEmpty)
          .toSet();

      final toAdd = <Map<String, dynamic>>[];
      for (final m in normalized) {
        final idStr = '${m['id'] ?? ''}';
        if (idStr.isEmpty || !existingIds.contains(idStr)) {
          toAdd.add(m);
        }
      }

      _setMessages(groupId, [...toAdd, ...current]);
      notifyListeners();
    } catch (e) {
      lastError = e.toString();
      notifyListeners();
    }
  }

  /// 🔄 Lấy thêm tin mới (phục vụ realtime) dựa trên id server cuối cùng
  /// Có chống trùng theo id + message_hash_id để không bị x2 tin nhắn.
  Future<void> fetchNewMessages(String groupId) async {
    try {
      // Copy list hiện tại để merge
      final current = List<Map<String, dynamic>>.from(messagesOf(groupId));

      // Tìm message cuối cùng đã nhận từ server (bỏ qua local_xxx)
      Map<String, dynamic>? lastServer;
      for (var i = current.length - 1; i >= 0; i--) {
        final m = current[i];
        final idStr = '${m['id'] ?? m['message_id'] ?? ''}';
        final isLocal = m['is_local'] == true;
        if (!isLocal && idStr.isNotEmpty && int.tryParse(idStr) != null) {
          lastServer = m;
          break;
        }
      }

      final afterId = lastServer == null ? '' : '${lastServer['id']}';
      if (afterId.isEmpty) return;

      // Gọi API lấy tin mới
      final newer = await repo.fetchNewerMessages(
        groupId,
        afterMessageId: afterId,
      );
      if (newer.isEmpty) return;

      final normalizedNew = newer.map(_normalizeServerMessage).toList();

      // Index các message hiện có theo id / message_hash_id để chống trùng
      final byId = <String, int>{};
      final byHash = <String, int>{};
      for (var i = 0; i < current.length; i++) {
        final m = current[i];
        final idStr = '${m['id'] ?? m['message_id'] ?? ''}';
        final hashStr = '${m['message_hash_id'] ?? ''}';
        if (idStr.isNotEmpty) byId[idStr] = i;
        if (hashStr.isNotEmpty) byHash[hashStr] = i;
      }

      // Merge từng message mới vào list, nếu trùng thì update, không add mới
      for (final raw in normalizedNew) {
        final idStr = '${raw['id'] ?? raw['message_id'] ?? ''}';
        final hashStr = '${raw['message_hash_id'] ?? ''}';

        int? idx;
        if (hashStr.isNotEmpty && byHash.containsKey(hashStr)) {
          idx = byHash[hashStr];
        } else if (idStr.isNotEmpty && byId.containsKey(idStr)) {
          idx = byId[idStr];
        }

        if (idx != null) {
          // Update message cũ bằng dữ liệu server (xoá cờ local/uploading)
          final merged = {
            ...current[idx],
            ...raw,
            'is_local': false,
            'uploading': false,
            'failed': false,
          };
          current[idx] = merged;
        } else {
          // Tin nhắn hoàn toàn mới -> add vào cuối
          current.add(raw);
          final newIndex = current.length - 1;
          if (idStr.isNotEmpty) byId[idStr] = newIndex;
          if (hashStr.isNotEmpty) byHash[hashStr] = newIndex;
        }
      }

      // Sắp xếp lại theo time cho chắc
      current.sort((a, b) {
        final ta = int.tryParse('${a['time'] ?? 0}') ?? 0;
        final tb = int.tryParse('${b['time'] ?? 0}') ?? 0;
        return ta.compareTo(tb);
      });

      _setMessages(groupId, current);
      notifyListeners();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('fetchNewMessages error: $e\n$st');
      }
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
    Map<String, dynamic>? replyTo,
  }) {
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final isImage = type == 'image';
    final isVideo = type == 'video';
    final isAudio = type == 'voice';
    final isFile = type == 'file';

    final mediaUri = file == null
        ? ''
        : (file.path.startsWith('file://') ? file.path : 'file://${file.path}');

    Map<String, dynamic>? reply;
    String? replyId;
    if (replyTo != null) {
      replyId = '${replyTo['id'] ?? replyTo['message_id'] ?? ''}';
      if (replyId.isEmpty) replyId = null;
      reply = Map<String, dynamic>.from(replyTo);
      final rText = (reply['display_text'] ?? reply['text'] ?? '').toString();
      reply['display_text'] = rText;
    }

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
      // reaction mặc định
      'my_reaction': null,
      'reactions_count': 0,
      'reaction': null,
      if (reply != null) 'reply': reply,
      if (replyId != null) 'reply_id': replyId,
    };
  }

  Future<void> sendMessage(
    String groupId,
    String text, {
    File? file,
    String? type,
    Map<String, dynamic>? replyTo,
  }) async {
    lastError = null;

    try {
      String? replyId;
      if (replyTo != null) {
        final rawId = replyTo['id'] ?? replyTo['message_id'];
        if (rawId != null && '$rawId'.isNotEmpty) {
          replyId = '$rawId';
        }
      }

      // Gửi lên server, KHÔNG dùng optimistic local để tránh x2
      await repo.sendMessage(
        groupId: groupId,
        text: text,
        file: file,
        type: type,
        messageHashId: null,
        replyToMessageId: replyId,
      );

      // Sau khi gửi xong: reload lại từ server cho chắc ăn
      await loadMessages(groupId);
    } catch (e) {
      lastError = e.toString();
      notifyListeners();
    }
  }

  // ---------- Reaction ----------
  /// Bật/tắt reaction cho 1 message trong group
  ///
  /// [reactionKey] là key bên WoWonder (vd: "Like", "Love", "Sad"...)
  Future<void> reactToMessage({
    required String groupId,
    required String messageId,
    required String reactionKey,
  }) async {
    lastError = null;

    final list = _messagesByGroup[groupId];
    if (list == null) return;

    final idx = list.indexWhere((m) => '${m['id'] ?? ''}' == messageId);
    if (idx == -1) return;

    final current = Map<String, dynamic>.from(list[idx]);
    final prevMy = current['my_reaction']?.toString();
    final prevCount = (current['reactions_count'] as int?) ?? 0;

    final removing = (prevMy == reactionKey);

    // 🔮 Optimistic update
    current['my_reaction'] = removing ? null : reactionKey;
    int newCount = prevCount;
    if (removing) {
      if (newCount > 0) newCount--;
    } else {
      newCount++;
    }
    current['reactions_count'] = newCount;

    list[idx] = current;
    _setMessages(groupId, List<Map<String, dynamic>>.from(list));
    notifyListeners();

    try {
      // Gọi API reaction
      final res = await repo.reactToMessage(
        groupId: groupId,
        messageId: messageId,
        reactionKey: reactionKey,
      );

      // Thử reload message từ server để lấy reaction chính xác
      final updated = await repo.fetchMessageById(groupId, messageId);
      if (updated != null) {
        final normalized = _normalizeServerMessage(updated);
        final newList = _messagesByGroup[groupId];
        if (newList != null) {
          final jdx =
              newList.indexWhere((m) => '${m['id'] ?? ''}' == messageId);
          if (jdx != -1) {
            newList[jdx] = {
              ...newList[jdx],
              ...normalized,
              // giữ các flag local nếu có
              'is_local': false,
            };
            _setMessages(groupId, List<Map<String, dynamic>>.from(newList));
            notifyListeners();
          }
        }
      } else {
        // nếu server không trả về, ít nhất giữ lại reaction theo res
        final newList = _messagesByGroup[groupId];
        if (newList != null) {
          final jdx =
              newList.indexWhere((m) => '${m['id'] ?? ''}' == messageId);
          if (jdx != -1) {
            final m = Map<String, dynamic>.from(newList[jdx]);
            m['my_reaction'] = res['my_reaction'] ?? m['my_reaction'];
            if (res['reactions_count'] != null) {
              m['reactions_count'] = res['reactions_count'];
            }
            if (res['reaction'] != null) {
              m['reaction'] = res['reaction'];
            }
            newList[jdx] = m;
            _setMessages(groupId, List<Map<String, dynamic>>.from(newList));
            notifyListeners();
          }
        }
      }
    } catch (e) {
      // rollback nếu lỗi
      final list2 = _messagesByGroup[groupId];
      if (list2 != null) {
        final jdx = list2.indexWhere((m) => '${m['id'] ?? ''}' == messageId);
        if (jdx != -1) {
          final m = Map<String, dynamic>.from(list2[jdx]);
          m['my_reaction'] = prevMy;
          m['reactions_count'] = prevCount;
          list2[jdx] = m;
          _setMessages(groupId, List<Map<String, dynamic>>.from(list2));
        }
      }
      lastError = e.toString();
      notifyListeners();
    }
  }

  /// Xoá 1 message trong group
  Future<bool> deleteMessage({
    required String groupId,
    required String messageId,
  }) async {
    lastError = null;
    try {
      final ok = await repo.deleteMessage(messageId);
      if (ok) {
        final list = _messagesByGroup[groupId];
        if (list != null) {
          list.removeWhere((m) => '${m['id'] ?? ''}' == messageId);
          _setMessages(groupId, List<Map<String, dynamic>>.from(list));
        }
      }
      notifyListeners();
      return ok;
    } catch (e) {
      lastError = e.toString();
      notifyListeners();
      return false;
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
