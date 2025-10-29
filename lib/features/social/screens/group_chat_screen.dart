import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/group_chat_controller.dart';

class GroupChatScreen extends StatefulWidget {
  final String accessToken;
  final String groupId;
  final String groupName;
  final String? currentUserId;

  const GroupChatScreen({
    super.key,
    required this.accessToken,
    required this.groupId,
    required this.groupName,
    this.currentUserId,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    final ctrl = context.read<GroupChatController>();

    // 🟢 Tải tin nhắn lần đầu + bắt đầu auto reload
    ctrl.loadMessages(widget.accessToken, widget.groupId);
    ctrl.startAutoReload(widget.accessToken, widget.groupId);
  }

  @override
  void dispose() {
    context.read<GroupChatController>().stopAutoReload();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;

    final ctrl = context.read<GroupChatController>();
    ctrl.sendMessage(widget.accessToken, widget.groupId, text);
    _inputCtrl.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 18,
              child: const Icon(Icons.groups, color: Colors.blueAccent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.groupName,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          // 🟢 Khu vực tin nhắn
          Expanded(
            child: Consumer<GroupChatController>(
              builder: (context, ctrl, _) {
                if (ctrl.messagesLoading && ctrl.messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = ctrl.messages;

                if (messages.isEmpty) {
                  return const Center(child: Text('Chưa có tin nhắn.'));
                }

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final text = msg['orginal_text'] ?? msg['text'] ?? '';
                    final fromId = msg['from_id']?.toString();
                    final isMine =
                        fromId == widget.currentUserId || msg['onwer'] == 1;
                    final time = msg['time_text'] ?? '';

                    return Align(
                      alignment:
                          isMine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMine ? Colors.blueAccent : cs.surfaceVariant,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: Radius.circular(isMine ? 12 : 0),
                            bottomRight: Radius.circular(isMine ? 0 : 12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              text,
                              style: TextStyle(
                                color: isMine
                                    ? Colors.white
                                    : cs.onSurface.withOpacity(0.9),
                                fontSize: 15,
                              ),
                            ),
                            if (time.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  time,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isMine
                                        ? Colors.white70
                                        : cs.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 🟢 Thanh nhập tin nhắn
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: cs.surfaceVariant.withOpacity(0.7),
                border: Border(
                  top: BorderSide(color: cs.outlineVariant, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blueAccent),
                    onPressed: _sendMessage,
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
