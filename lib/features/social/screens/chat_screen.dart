import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_chat_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/social_chat_repository.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/utils/wowonder_text.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String accessToken;
  final String? title;
  final String? avatar;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.accessToken,
    this.title,
    this.avatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final chatCtrl = Get.put(SocialChatController(SocialChatRepository()));
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    chatCtrl.loadMessages(widget.accessToken, widget.receiverId);
    ever(chatCtrl.messages, (_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent + 120);
      }
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final txt = _textCtrl.text.trim();
    if (txt.isEmpty) return;
    chatCtrl.sendMessage(widget.accessToken, widget.receiverId, txt);
    _textCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage:
                  (widget.avatar != null && widget.avatar!.isNotEmpty)
                      ? NetworkImage(widget.avatar!)
                      : null,
              child: (widget.avatar == null || widget.avatar!.isEmpty)
                  ? Text(
                      (widget.title ?? '').isNotEmpty
                          ? widget.title![0].toUpperCase()
                          : '?',
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(widget.title ?? 'Đoạn chat',
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              final data = chatCtrl.messages;
              if (chatCtrl.isLoading.value && data.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView.builder(
                controller: _scrollCtrl,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: data.length,
                itemBuilder: (_, i) {
                  final m = data[i];

                  // Xác định bubble của mình hay của đối phương.
                  // WoWonder trả from_id/to_id; nếu from_id != receiverId => là mình.
                  final mine = (m['from_id']?.toString() != widget.receiverId);

                  // LẤY TEXT HIỂN THỊ
                  final text =
                      (m['display_text'] ?? pickWoWonderText(m)).toString();

                  return Align(
                    alignment:
                        mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.78,
                      ),
                      decoration: BoxDecoration(
                        color: mine ? cs.primary : cs.surfaceVariant,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        text,
                        style: TextStyle(
                          color: mine ? cs.onPrimary : cs.onSurface,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),

          // Thanh nhập tin nhắn
          SafeArea(
            top: false,
            child: _ComposerBar(
              controller: _textCtrl,
              onSend: _send,
              onTapPlus: () {},
              onTapCamera: () {},
              onTapGallery: () {},
              onTapMic: () {},
              onTapLike: () {
                if (_textCtrl.text.trim().isEmpty) {
                  chatCtrl.sendMessage(
                      widget.accessToken, widget.receiverId, '👍');
                } else {
                  _send();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ComposerBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onTapPlus;
  final VoidCallback onTapCamera;
  final VoidCallback onTapGallery;
  final VoidCallback onTapMic;
  final VoidCallback onTapLike;

  const _ComposerBar({
    required this.controller,
    required this.onSend,
    required this.onTapPlus,
    required this.onTapCamera,
    required this.onTapGallery,
    required this.onTapMic,
    required this.onTapLike,
  });

  @override
  State<_ComposerBar> createState() => _ComposerBarState();
}

class _ComposerBarState extends State<_ComposerBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    final now = widget.controller.text.trim().isNotEmpty;
    if (now != _hasText) setState(() => _hasText = now);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(.9),
        border: Border(
            top: BorderSide(
                color: cs.outlineVariant.withOpacity(.6), width: .5)),
      ),
      child: Row(
        children: [
          _CircleIcon(icon: Icons.add, onTap: widget.onTapPlus),
          const SizedBox(width: 6),
          _CircleIcon(
              icon: Icons.photo_camera_outlined, onTap: widget.onTapCamera),
          const SizedBox(width: 6),
          _CircleIcon(icon: Icons.image_outlined, onTap: widget.onTapGallery),
          const SizedBox(width: 6),
          _CircleIcon(icon: Icons.mic_none_outlined, onTap: widget.onTapMic),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: widget.controller,
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Nhắn tin',
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: cs.surfaceVariant.withOpacity(.6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.emoji_emotions_outlined),
                  onPressed: () {},
                ),
              ),
              onSubmitted: (_) => widget.onSend(),
            ),
          ),
          const SizedBox(width: 8),
          _CircleIcon(
            icon: _hasText ? Icons.send_rounded : Icons.thumb_up_alt_outlined,
            onTap: _hasText ? widget.onSend : widget.onTapLike,
          ),
        ],
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _CircleIcon({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: cs.surfaceVariant.withOpacity(.6),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: cs.primary),
        ),
      ),
    );
  }
}
