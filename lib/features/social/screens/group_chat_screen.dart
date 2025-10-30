import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/group_chat_controller.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  Timer? _autoRefresh;

  @override
  void initState() {
    super.initState();
    final ctrl = context.read<GroupChatController>();
    ctrl.loadMessages(widget.groupId).then((_) => _scrollToBottom());

    // 🔁 Tự động reload 5s
    _autoRefresh = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) ctrl.loadMessages(widget.groupId);
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<GroupChatController>();
    final currentUserId = ctrl.currentUserId ?? '';
    final cs = Theme.of(context).colorScheme;

    final messages = (ctrl.messagesByGroup[widget.groupId] ?? [])
      ..sort((a, b) {
        final aTime = int.tryParse(a['time'].toString()) ?? 0;
        final bTime = int.tryParse(b['time'].toString()) ?? 0;
        return aTime.compareTo(bTime);
      });

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          widget.groupName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // 🧱 Danh sách tin nhắn
          Expanded(
            child: ctrl.messagesLoading && messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
                      final msg = messages[i];
                      final fromUser = msg['user_data'] ?? {};
                      final userId = fromUser['user_id']?.toString() ?? '';
                      final username = fromUser['username'] ?? 'Ẩn danh';
                      final avatar = fromUser['avatar'] ?? '';
                      final text = msg['text'] ?? '';
                      final timeInt = int.tryParse(msg['time'].toString()) ?? 0;
                      final time =
                          DateTime.fromMillisecondsSinceEpoch(timeInt * 1000);

                      final isMine = userId == currentUserId || userId == 'me';

                      // Gộp tin cùng người
                      bool showAvatar = true;
                      if (i > 0) {
                        final prev = messages[i - 1];
                        final prevId =
                            prev['user_data']?['user_id']?.toString() ?? '';
                        if (prevId == userId) showAvatar = false;
                      }

                      bool showTime = true;
                      if (i < messages.length - 1) {
                        final next = messages[i + 1];
                        final nextId =
                            next['user_data']?['user_id']?.toString() ?? '';
                        if (nextId == userId) showTime = false;
                      }

                      return Padding(
                        padding: EdgeInsets.only(
                          top: showAvatar ? 8 : 2,
                          bottom: showTime ? 8 : 2,
                        ),
                        child: Column(
                          crossAxisAlignment: isMine
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            if (showAvatar && !isMine)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundImage: avatar.isNotEmpty
                                        ? NetworkImage(avatar)
                                        : null,
                                    backgroundColor: cs.surfaceVariant,
                                    child: avatar.isEmpty
                                        ? Text(
                                            username[0].toUpperCase(),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    username,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: cs.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),

                            // 💬 Bong bóng tin nhắn
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: isMine
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              children: [
                                if (!isMine) const SizedBox(width: 40),
                                Flexible(
                                  child: Container(
                                    margin: EdgeInsets.only(
                                      left: isMine ? 80 : 0,
                                      right: isMine ? 8 : 80,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isMine
                                          ? Colors.blue[600]
                                          : Colors.white,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(16),
                                        topRight: const Radius.circular(16),
                                        bottomLeft: isMine
                                            ? const Radius.circular(16)
                                            : const Radius.circular(4),
                                        bottomRight: isMine
                                            ? const Radius.circular(4)
                                            : const Radius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      text,
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: isMine
                                            ? Colors.white
                                            : Colors.black87,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // ⏰ Thời gian
                            if (showTime)
                              Padding(
                                padding: EdgeInsets.only(
                                  top: 3,
                                  right: isMine ? 12 : 0,
                                  left: isMine ? 0 : 50,
                                ),
                                child: Text(
                                  "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: cs.onSurface.withOpacity(0.5),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // ✏️ Ô nhập tin nhắn
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(
                  top: BorderSide(
                    color: cs.outlineVariant.withOpacity(.4),
                    width: .5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: cs.surfaceVariant.withOpacity(.5),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: () async {
                      final text = _inputCtrl.text.trim();
                      if (text.isEmpty) return;
                      await ctrl.sendMessage(widget.groupId, text);
                      _inputCtrl.clear();
                      _scrollToBottom();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
