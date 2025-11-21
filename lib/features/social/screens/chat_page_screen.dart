import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_page_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_page_mess.dart';

class PageChatScreen extends StatefulWidget {
  final int pageId;
  final String pageTitle;
  final String pageAvatar;
  final String recipientId;

  const PageChatScreen({
    super.key,
    required this.pageId,
    required this.pageTitle,
    required this.pageAvatar,
    required this.recipientId,
  });

  @override
  State<PageChatScreen> createState() => _PageChatScreenState();
}

class _PageChatScreenState extends State<PageChatScreen> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<SocialPageController>().initPageChat(
        pageId: widget.pageId,
        recipientId: widget.recipientId,
      );
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    context.read<SocialPageController>().disposePageChat();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pageCtrl = context.watch<SocialPageController>();
    final List<SocialPageMessage> messages = pageCtrl.pageMessages;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: widget.pageAvatar.isNotEmpty
                  ? NetworkImage(widget.pageAvatar)
                  : null,
              child: widget.pageAvatar.isEmpty
                  ? Text(widget.pageTitle.isNotEmpty
                  ? widget.pageTitle[0].toUpperCase()
                  : 'P')
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.pageTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: pageCtrl.loadingPageMessages
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (_, i) {
                final msg = messages[i];
                final bool isMe = msg.position == "right";

                if (i == messages.length - 1) {
                  WidgetsBinding.instance.addPostFrameCallback(
                        (_) => _scrollToBottom(),
                  );
                }

                return Column(
                  crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (msg.reply != null)
                      _buildReplyBubble(msg.reply!, isMe),

                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isMe
                            ? Colors.blue.shade600
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _buildMessageBody(msg, isMe),
                    ),
                  ],
                );
              },
            ),
          ),

          _buildInputArea(pageCtrl),
        ],
      ),
    );
  }

  // ============================================================
  // MESSAGE BODY
  // ============================================================

  Widget _buildMessageBody(SocialPageMessage msg, bool isMe) {
    // 1) Media: ảnh
    if (msg.media.isNotEmpty &&
        (msg.media.endsWith('.jpg') ||
            msg.media.endsWith('.jpeg') ||
            msg.media.endsWith('.png') ||
            msg.media.endsWith('.gif') ||
            msg.media.endsWith('.webp'))) {
      return Image.network(msg.media, width: 240, fit: BoxFit.cover);
    }

    // 2) Sticker
    if (msg.stickers.isNotEmpty) {
      return Image.network(msg.stickers, width: 160);
    }

    // 3) Text (đã được repo decode sẵn)
    final text = msg.text;

    return Text(
      text.isNotEmpty ? text : "[Media]",
      style: TextStyle(
        color: isMe ? Colors.white : Colors.black87,
      ),
    );
  }

  // ============================================================
  // REPLY BUBBLE
  // ============================================================

  Widget _buildReplyBubble(SocialPageReplyMessage reply, bool isMe) {
    final replyText = reply.text;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      width: 240,
      decoration: BoxDecoration(
        color: isMe ? Colors.white24 : Colors.black12,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        replyText.isNotEmpty ? replyText : "[Media]",
        style: const TextStyle(
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  // ============================================================
  // INPUT FIELD
  // ============================================================

  Widget _buildInputArea(SocialPageController pageCtrl) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(.4),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputCtrl,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Nhập tin nhắn...",
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.blue),
              onPressed: () async {
                final text = _inputCtrl.text.trim();
                if (text.isEmpty) return;

                _inputCtrl.clear();
                await pageCtrl.sendPageChatMessage(text: text);
                _scrollToBottom();
              },
            )
          ],
        ),
      ),
    );
  }

  // ============================================================
  // AUTO SCROLL
  // ============================================================

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
