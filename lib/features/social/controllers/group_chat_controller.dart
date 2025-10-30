import 'dart:io';
import 'package:flutter/foundation.dart';
import '../domain/repositories/group_chat_repository.dart';

class GroupChatController extends ChangeNotifier {
  final GroupChatRepository repo;
String? currentUserId;
  GroupChatController({required this.repo});

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
  Future<void> loadGroups(String accessToken) async {
    groupsLoading = true;
    notifyListeners();
    try {
      groups = await repo.fetchGroups(accessToken: accessToken);
      lastError = null;
    } catch (e) {
      lastError = e.toString();
    } finally {
      groupsLoading = false;
      notifyListeners();
    }
  }

  // 🧩 Tạo nhóm mới
  Future<bool> createGroup({
    required String accessToken,
    required String name,
    required List<String> memberIds,
    File? avatarFile,
  }) async {
    creatingGroup = true;
    lastError = null;
    notifyListeners();

    try {
      final ok = await repo.createGroup(
        accessToken: accessToken,
        name: name,
        memberIds: memberIds,
        avatarFile: avatarFile,
      );
      if (ok) await loadGroups(accessToken);
      return ok;
    } catch (e) {
      lastError = e.toString();
      return false;
    } finally {
      creatingGroup = false;
      notifyListeners();
    }
  }

  // 📥 Lấy tin nhắn trong nhóm
  Future<void> loadMessages(String accessToken, String groupId) async {
    messagesLoading = true;
    notifyListeners();
    try {
      final messages = await repo.fetchMessages(
        accessToken: accessToken,
        groupId: groupId,
      );
      messagesByGroup[groupId] = messages;
      lastError = null;
    } catch (e) {
      lastError = e.toString();
    } finally {
      messagesLoading = false;
      notifyListeners();
    }
  }

  // 🚀 Gửi tin nhắn — hiển thị ngay mà không cần reload API
  Future<void> sendMessage(
    String accessToken,
    String groupId,
    String text,
  ) async {
    try {
      // ✅ Gửi lên server
      await repo.sendMessage(
        accessToken: accessToken,
        groupId: groupId,
        text: text,
      );

      // ✅ Tự thêm vào danh sách tạm (giúp hiển thị ngay)
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final localMsg = {
        'id': 'local_${DateTime.now().millisecondsSinceEpoch}',
        'from_id': 'me', // tự đánh dấu user hiện tại
        'text': text,
        'time': now,
        'user_data': {
          'username': 'Bạn',
          'avatar': '',
          'user_id': 'me',
        }
      };

      final existing = messagesByGroup[groupId] ?? [];
      existing.add(localMsg);
      messagesByGroup[groupId] = existing;
      notifyListeners();
    } catch (e) {
      lastError = e.toString();
      notifyListeners();
    }
  }
}
