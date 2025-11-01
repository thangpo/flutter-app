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

  String? currentUserId;
  Future<void> _reloadCurrentUser() async {
    try {
      final sp = await SharedPreferences.getInstance();
      currentUserId = sp.getString(AppConstants.socialUserId);
      notifyListeners();
    } catch (_) {}
  }

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
      if (ok) await loadGroups();
      return ok;
    } catch (e) {
      lastError = e.toString();
      return false;
    } finally {
      creatingGroup = false;
      notifyListeners();
    }
  }

  // ---------- Messages + Pagination ----------
  final Map<String, List<Map<String, dynamic>>> _messagesByGroup = {};
  final Map<String, bool> _messagesLoadingByGroup = {};
  final Map<String, bool> _hasMoreByGroup = {};
  String? lastError;

  List<Map<String, dynamic>> messagesOf(String groupId) =>
      _messagesByGroup[groupId] ?? const [];

  bool messagesLoading(String groupId) =>
      _messagesLoadingByGroup[groupId] == true;

  bool hasMore(String groupId) => _hasMoreByGroup[groupId] ?? true;

  Map<String, dynamic> _normalizeServerMsg(Map m) {
    final typeTwo = (m['type_two'] ?? '').toString();
    final media = (m['media'] ?? '').toString();
    final fileName = (m['mediaFileName'] ?? '').toString();

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
      'display_text': m['display_text'] ?? m['text'],
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

  void _sortByTimeAsc(List<Map<String, dynamic>> items) {
    items.sort((a, b) {
      final ta = int.tryParse('${a['time'] ?? 0}') ?? 0;
      final tb = int.tryParse('${b['time'] ?? 0}') ?? 0;
      return ta.compareTo(tb);
    });
  }

  void _setMessages(String groupId, List<Map<String, dynamic>> items) {
    _sortByTimeAsc(items);
    _messagesByGroup[groupId] = items;
  }

  Future<void> loadMessages(String groupId, {int limit = 200}) async {
    _messagesLoadingByGroup[groupId] = true;
    lastError = null;
    notifyListeners();
    try {
      final serverList = await repo.fetchMessages(groupId, limit: limit);

      // chỉ giữ local FAILED để retry – tránh overlay "đang gửi" dai dẳng
      final localFailed = (_messagesByGroup[groupId] ?? [])
          .where((m) => m['is_local'] == true && m['failed'] == true)
          .toList();

      final normalized =
          serverList.map<Map<String, dynamic>>(_normalizeServerMsg).toList();

      final merged = <String, Map<String, dynamic>>{};
      for (final m in [...normalized, ...localFailed]) {
        final id = (m['id'] ?? '').toString();
        merged[id.isEmpty ? UniqueKey().toString() : id] =
            Map<String, dynamic>.from(m);
      }

      _setMessages(groupId, merged.values.toList());
      _hasMoreByGroup[groupId] = serverList.length >= limit;
    } catch (e) {
      lastError = e.toString();
    } finally {
      _messagesLoadingByGroup[groupId] = false;
      notifyListeners();
    }
  }

  Future<void> loadOlder(String groupId, {int limit = 200}) async {
    if (messagesLoading(groupId) || !hasMore(groupId)) return;
    _messagesLoadingByGroup[groupId] = true;
    notifyListeners();

    try {
      final current = List<Map<String, dynamic>>.from(messagesOf(groupId));
      String? oldestId;
      if (current.isNotEmpty) {
        oldestId = (current.first['id'] ?? '').toString();
      }
      if (oldestId == null || oldestId.isEmpty) {
        await loadMessages(groupId, limit: limit);
        return;
      }

      final older = await repo.fetchOlderMessages(
        groupId,
        beforeMessageId: oldestId,
        limit: limit,
      );

      final normalized =
          older.map<Map<String, dynamic>>(_normalizeServerMsg).toList();

      final byId = <String, Map<String, dynamic>>{};
      for (final m in [...normalized, ...current]) {
        final id = (m['id'] ?? '').toString();
        byId[id.isEmpty ? UniqueKey().toString() : id] =
            Map<String, dynamic>.from(m);
      }

      _setMessages(groupId, byId.values.toList());
      _hasMoreByGroup[groupId] = older.length >= limit;
    } catch (e) {
      lastError = e.toString();
    } finally {
      _messagesLoadingByGroup[groupId] = false;
      notifyListeners();
    }
  }

  // ---------- Send ----------
  final _rng = Random();
  String _tempId() =>
      'local_${DateTime.now().millisecondsSinceEpoch}_${_rng.nextInt(999999)}';

  Map<String, dynamic> _makeLocalMessage({
    required String groupId,
    required String text,
    File? file,
    String? type,
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
      'user_data': {
        'user_id': currentUserId,
      },
    };
  }

  Future<void> sendMessage(
    String groupId,
    String text, {
    File? file,
    String? type,
  }) async {
    lastError = null;

    // 1) Placeholder
    final local = _makeLocalMessage(
      groupId: groupId,
      text: text,
      file: file,
      type: type,
    );
    final cur = [...messagesOf(groupId), local];
    _setMessages(groupId, cur);
    notifyListeners();

    // 2) API
    Map<String, dynamic>? serverMsg;
    try {
      serverMsg = await repo.sendMessage(
        groupId: groupId,
        text: text,
        file: file,
        type: type,
      );
    } catch (e) {
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
      return;
    }

    // 3) Thay thế 1-1 nếu có message server
    if (serverMsg != null) {
      final normalized = _normalizeServerMsg(serverMsg);
      final list = _messagesByGroup[groupId] ?? [];
      final idx = list.indexWhere((m) => m['id'] == local['id']);
      if (idx != -1) {
        list[idx] = {
          ...normalized,
          'failed': false,
          'is_local': false,
          'uploading': false,
        };
        _setMessages(groupId, List<Map<String, dynamic>>.from(list));
        notifyListeners();
      } else {
        _setMessages(groupId, [...list, normalized]);
        notifyListeners();
      }
      await loadMessages(groupId, limit: 200);
      return;
    }

    // 4) Backend không trả message: tắt uploading nhưng không xoá placeholder
    final list = _messagesByGroup[groupId] ?? [];
    final idx = list.indexWhere((m) => m['id'] == local['id']);
    if (idx != -1) {
      list[idx] = {
        ...list[idx],
        'uploading': false,
        'failed': false,
      };
      _setMessages(groupId, List<Map<String, dynamic>>.from(list));
      notifyListeners();
    }
    await loadMessages(groupId, limit: 200);
  }

  Future<void> retryFailedLocal(String groupId, String localId) async {
    final list = _messagesByGroup[groupId];
    if (list == null) return;
    final idx = list.indexWhere((m) => m['id'] == localId);
    if (idx == -1) return;

    final m = list[idx];
    if (m['failed'] != true || m['is_local'] != true) return;

    final String text = (m['text'] ?? '').toString();
    final String? type = m['is_image'] == true
        ? 'image'
        : m['is_video'] == true
            ? 'video'
            : m['is_audio'] == true
                ? 'voice'
                : m['is_file'] == true
                    ? 'file'
                    : null;

    File? file;
    final media = (m['media'] ?? '').toString();
    if (media.startsWith('file://') || media.startsWith('/')) {
      file = File(
          media.startsWith('file://') ? Uri.parse(media).toFilePath() : media);
      if (!file.existsSync()) {
        lastError = 'Tệp đính kèm không còn tồn tại để gửi lại';
        notifyListeners();
        return;
      }
    }

    list[idx] = {
      ...m,
      'uploading': file != null,
      'failed': false,
    };
    _setMessages(groupId, List<Map<String, dynamic>>.from(list));
    notifyListeners();

    await sendMessage(groupId, text, file: file, type: type);
  }

  bool isMyMessage(Map<String, dynamic> message) {
    final fromId = message['from_id']?.toString();
    final me = currentUserId?.toString();
    return (fromId != null && me != null && fromId == me);
  }
}
