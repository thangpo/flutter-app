import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/social_chat_repository.dart';

class SocialChatController extends GetxController {
  final SocialChatRepository repo;
  SocialChatController(this.repo);

  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final messages = <Map<String, dynamic>>[].obs;

  String? _token;
  String? _peerId;
  Timer? _pollTimer;

  Future<void> loadMessages(String token, String peerUserId) async {
    _token = token;
    _peerId = peerUserId;

    isLoading.value = true;
    final list = await repo.getUserMessages(
      token: token,
      peerUserId: peerUserId,
      limit: 25,
    );
    list.sort((a, b) => _msgId(a).compareTo(_msgId(b)));
    messages.assignAll(list);
    isLoading.value = false;

    await _markRead();
    _startPolling();
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || messages.isEmpty) return;
    if (_token == null || _peerId == null) return;

    isLoadingMore.value = true;
    final beforeId = _msgIdStr(messages.first);

    final older = await repo.getUserMessages(
      token: _token!,
      peerUserId: _peerId!,
      beforeMessageId: beforeId,
      limit: 25,
    );
    older.sort((a, b) => _msgId(a).compareTo(_msgId(b)));
    if (older.isNotEmpty) {
      messages.insertAll(0, older);
    }
    isLoadingMore.value = false;
  }

  Future<void> sendMessage(String token, String peerUserId, String text) async {
    final m = await repo.sendMessage(
        token: token, peerUserId: peerUserId, text: text);
    if (m != null) {
      messages.add(m);
      await _markRead();
    }
  }

  Future<void> sendGif(String token, String peerUserId, String gifUrl) async {
    final m = await repo.sendMessage(
        token: token, peerUserId: peerUserId, gifUrl: gifUrl);
    if (m != null) {
      messages.add(m);
      await _markRead();
    }
  }

  Future<void> sendFile(
      String token, String peerUserId, String filePath) async {
    final m = await repo.sendMessage(
        token: token, peerUserId: peerUserId, filePath: filePath);
    if (m != null) {
      messages.add(m);
      await _markRead();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 7), (_) async {
      if (_token == null || _peerId == null) return;
      final fresh = await repo.getUserMessages(
        token: _token!,
        peerUserId: _peerId!,
        limit: 25,
      );
      fresh.sort((a, b) => _msgId(a).compareTo(_msgId(b)));
      final seen = messages.map(_msgIdStr).toSet();
      for (final e in fresh) {
        final id = _msgIdStr(e);
        if (!seen.contains(id)) messages.add(e);
      }
    });
  }

  Future<void> _markRead() async {
    if (_token == null || _peerId == null) return;
    await repo.readChats(token: _token!, peerUserId: _peerId!);
  }

  int _msgId(Map<String, dynamic> m) => int.tryParse(_msgIdStr(m)) ?? 0;
  String _msgIdStr(Map<String, dynamic> m) =>
      '${m['id'] ?? m['message_id'] ?? m['msg_id'] ?? ''}';

  @override
  void onClose() {
    _pollTimer?.cancel();
    super.onClose();
  }
}
