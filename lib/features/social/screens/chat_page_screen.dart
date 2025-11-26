import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;   // 👈 thêm thư viện decrypt
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_page_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_page_mess.dart';

class PageChatScreen extends StatefulWidget {
  final int pageId;
  final String pageTitle;
  final String pageAvatar;
  final String recipientId;
  final String pageSubtitle;

  const PageChatScreen({
    super.key,
    required this.pageId,
    required this.pageTitle,
    required this.pageAvatar,
    required this.recipientId,
    required this.pageSubtitle,
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

  // ============================================================
  // 🔐 1) DECRYPT giống ChatScreen
  // ============================================================

  String _plainTextOf(SocialPageMessage m) {
    final raw = m.text.trim();
    final timeStr = m.time.toString();

    if (raw.isEmpty) return "";
    if (raw.startsWith("http")) return raw; // tránh decrypt media

    final dec = _tryDecryptWoWonder(raw, timeStr);
    return dec ?? raw;
  }

  String? _tryDecryptWoWonder(String base64Text, String timeStr) {
    if (base64Text.isEmpty || timeStr.isEmpty) return null;

    try {
      final keyStr = timeStr.padRight(16, '0').substring(0, 16);

      final data = base64.decode(base64.normalize(base64Text));
      final aes = enc.Encrypter(enc.AES(
        enc.Key(Uint8List.fromList(utf8.encode(keyStr))),
        mode: enc.AESMode.ecb,
        padding: 'PKCS7',
      ));

      final decrypted = aes.decrypt(enc.Encrypted(data));
      return decrypted.replaceAll('\x00', '').trim();
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // UI
  // ============================================================

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.pageTitle,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(
                    widget.pageSubtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
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
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _scrollToBottom());
                }

                return Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (msg.reply != null)
                      _buildReplyBubble(msg.reply!, isMe),

                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color:
                        isMe ? Colors.blue.shade600 : Colors.grey.shade300,
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
  // MESSAGE BODY (UPDATE để dùng decrypt)
  // ============================================================

  Widget _buildMessageBody(SocialPageMessage msg, bool isMe) {
    // 1) Ảnh
    if (msg.media.isNotEmpty &&
        (msg.media.endsWith(".jpg") ||
            msg.media.endsWith(".jpeg") ||
            msg.media.endsWith(".png") ||
            msg.media.endsWith(".gif") ||
            msg.media.endsWith(".webp"))) {
      return Image.network(msg.media, width: 240, fit: BoxFit.cover);
    }

    // 2) Sticker
    if (msg.stickers.isNotEmpty) {
      return Image.network(msg.stickers, width: 160);
    }

    // 3) TEXT — dùng decrypt
    final txt = _plainTextOf(msg);

    return Text(
      txt.isNotEmpty ? txt : "[Media]",
      style: TextStyle(color: isMe ? Colors.white : Colors.black87),
    );
  }

  // ============================================================
  // REPLY
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
        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
      ),
    );
  }

  // ============================================================
  // INPUT
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
  // SCROLL
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
