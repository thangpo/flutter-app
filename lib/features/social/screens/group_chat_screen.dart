import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/group_chat_controller.dart';

class GroupChatScreen extends StatefulWidget {
  final String accessToken;
  final String groupId;
  final String groupName;
  final String currentUserId; // 🆕 thêm để phân biệt ai đang đăng nhập

  const GroupChatScreen({
    super.key,
    required this.accessToken,
    required this.groupId,
    required this.groupName,
    required this.currentUserId,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    final ctrl = context.read<GroupChatController>();
    ctrl
        .loadMessages(widget.accessToken, widget.groupId)
        .then((_) => _scrollToBottom());
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
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ctrl = context.watch<GroupChatController>();

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
      ),
      body: Column(
        children: [
          // 🧱 Danh sách tin nhắn
          Expanded(
            child: ctrl.messagesLoading
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

                      final isMine =
                          userId == widget.currentUserId || userId == 'me';

                      // 🧩 Kiểm tra tin trước để gộp nhóm
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
                                  Text(username,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: cs.onSurface.withOpacity(0.7),
                                      )),
                                ],
                              ),
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
                                        left: isMine ? 60 : 0,
                                        right: isMine ? 0 : 60),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isMine
                                          ? Colors.blue[200]
                                          : Colors.white,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(14),
                                        topRight: const Radius.circular(14),
                                        bottomLeft: isMine
                                            ? const Radius.circular(14)
                                            : Radius.zero,
                                        bottomRight: isMine
                                            ? Radius.zero
                                            : const Radius.circular(14),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 3,
                                          offset: const Offset(0, 1),
                                        )
                                      ],
                                    ),
                                    child: Text(
                                      text,
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: isMine
                                            ? Colors.black87
                                            : cs.onSurface,
                                      ),
                                    ),
                                  ),
                                ),
                                if (isMine) const SizedBox(width: 40),
                              ],
                            ),
                            if (showTime)
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 3, left: 10, right: 10),
                                child: Text(
                                  "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: cs.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // 🧩 Khung nhập tin nhắn
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
                      await ctrl.sendMessage(
                          widget.accessToken, widget.groupId, text);
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
