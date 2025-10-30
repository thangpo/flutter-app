// 📁 lib/features/social/controllers/group_chat_controller.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../domain/repositories/group_chat_repository.dart';

class GroupChatController extends ChangeNotifier {
  final GroupChatRepository repo;
  GroupChatController({required this.repo});

  // ======= STATE =======
  bool groupsLoading = false;
  bool messagesLoading = false;
  bool creatingGroup = false;
  String? lastError;

  List<Map<String, dynamic>> groups = [];
  List<Map<String, dynamic>> messages = [];

  Timer? _autoReloadTimer;

  // =============================
  // 🟢 Danh sách nhóm
  // =============================
  Future<void> loadGroups(String accessToken) async {
    try {
      groupsLoading = true;
      notifyListeners();
      groups = await repo.fetchGroups(accessToken: accessToken);
    } catch (e) {
      if (kDebugMode) print('❌ loadGroups error: $e');
    } finally {
      groupsLoading = false;
      notifyListeners();
    }
  }

  // =============================
  // 🟢 Tin nhắn nhóm
  // =============================
  Future<void> loadMessages(String accessToken, String groupId) async {
    try {
      messagesLoading = true;
      notifyListeners();
      final result = await repo.fetchMessages(
        accessToken: accessToken,
        groupId: groupId,
      );
      messages = result.reversed.toList();
    } catch (e) {
      if (kDebugMode) print('❌ loadMessages error: $e');
    } finally {
      messagesLoading = false;
      notifyListeners();
    }
  }

  // 🟢 Tự động refresh tin nhắn
  void startAutoReload(String accessToken, String groupId,
      {Duration interval = const Duration(seconds: 5)}) {
    stopAutoReload();
    _autoReloadTimer = Timer.periodic(interval, (_) {
      loadMessages(accessToken, groupId);
    });
  }

  void stopAutoReload() {
    _autoReloadTimer?.cancel();
    _autoReloadTimer = null;
  }

  // =============================
  // 🟢 Gửi tin nhắn
  // =============================
  Future<void> sendMessage(
      String accessToken, String groupId, String text) async {
    if (text.trim().isEmpty) return;

    final tempMsg = {
      'orginal_text': text,
      'position': 'right',
      'onwer': 1,
      'time_text': '...',
    };
    messages.add(tempMsg);
    notifyListeners();

    try {
      final success = await repo.sendMessage(
        accessToken: accessToken,
        groupId: groupId,
        text: text,
      );
      if (success) {
        await loadMessages(accessToken, groupId);
      } else {
        if (kDebugMode) print('❌ sendMessage failed');
      }
    } catch (e) {
      if (kDebugMode) print('❌ sendMessage error: $e');
    }
  }

  // =============================
  // 🟢 Tạo nhóm
  // =============================
  Future<bool> createGroup({
    required String accessToken,
    required String name,
    required List<String> memberIds,
    File? avatarFile,
  }) async {
    lastError = null;
    try {
      creatingGroup = true;
      notifyListeners();

      final success = await repo.createGroup(
        accessToken: accessToken,
        groupName: name,
        memberIds: memberIds,
        avatar: avatarFile,
      );

      if (success) {
        await loadGroups(accessToken);
        return true;
      } else {
        lastError = 'Không thể tạo nhóm.';
        return false;
      }
    } catch (e) {
      lastError = 'Lỗi tạo nhóm: $e';
      if (kDebugMode) print(lastError);
      return false;
    } finally {
      creatingGroup = false;
      notifyListeners();
    }
  }

  // =============================
  // 🟢 Dispose
  // =============================
  @override
  void dispose() {
    stopAutoReload();
    super.dispose();
  }
}
