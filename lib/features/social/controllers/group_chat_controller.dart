import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/repositories/group_chat_repository.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

class GroupChatController extends ChangeNotifier {
  final GroupChatRepository repo;
  String? currentUserId;

  GroupChatController({required this.repo}) {
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getString(AppConstants.socialUserId);
    debugPrint('👤 currentUserId = $currentUserId');
  }

  /// 🧱 Danh sách nhóm
  bool groupsLoading = false;
  List<Map<String, dynamic>> groups = [];

  /// 🧱 Tin nhắn nhóm
  bool messagesLoading = false;
  Map<String, List<Map<String, dynamic>>> messagesByGroup = {};

  /// 🧱 Trạng thái tạo nhóm
  bool creatingGroup = false;
  String? lastError;

  // 📦 Lấy danh sách nhóm
  Future<void> loadGroups() async {
    groupsLoading = true;
    notifyListeners();
    try {
      groups = await repo.fetchGroups();
      lastError = null;
    } catch (e) {
      lastError = e.toString();
      debugPrint('❌ Lỗi loadGroups: $e');
    } finally {
      groupsLoading = false;
      notifyListeners();
    }
  }

  // 🧩 Tạo nhóm mới
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
      debugPrint('❌ Lỗi createGroup: $e');
      return false;
    } finally {
      creatingGroup = false;
      notifyListeners();
    }
  }

  // 📥 Lấy tin nhắn trong nhóm
  Future<void> loadMessages(String groupId) async {
    messagesLoading = true;
    notifyListeners();
    try {
      final messages = await repo.fetchMessages(groupId);
      messagesByGroup[groupId] = messages;
      lastError = null;
    } catch (e) {
      lastError = e.toString();
      debugPrint('❌ Lỗi loadMessages ($groupId): $e');
    } finally {
      messagesLoading = false;
      notifyListeners();
    }
  }

  // 🚀 Gửi tin nhắn — hiển thị ngay mà không cần reload API
  Future<void> sendMessage(String groupId, String text) async {
    try {
      await repo.sendMessage(groupId: groupId, text: text);

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final localMsg = {
        'id': 'local_${DateTime.now().millisecondsSinceEpoch}',
        'from_id': currentUserId ?? 'me',
        'text': text,
        'time': now,
        'user_data': {
          'username': 'Bạn',
          'avatar': '',
          'user_id': currentUserId ?? 'me',
        }
      };

      final existing = messagesByGroup[groupId] ?? [];
      existing.add(localMsg);
      messagesByGroup[groupId] = existing;
      notifyListeners();
    } catch (e) {
      lastError = e.toString();
      debugPrint('❌ Lỗi sendMessage: $e');
      notifyListeners();
    }
  }

  /// 🔎 Kiểm tra tin nhắn có phải của user hiện tại không
  bool isMyMessage(Map<String, dynamic> msg) {
    final fromId = msg['from_id']?.toString() ?? '';
    return fromId == (currentUserId ?? '');
  }
}
