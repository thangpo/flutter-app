import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/search_chat_result.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_page_chat.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/services/chat_search_service.dart';

class SearchChatScreen extends StatefulWidget {
  final String accessToken;
  const SearchChatScreen({super.key, required this.accessToken});

  @override
  State<SearchChatScreen> createState() => _SearchChatScreenState();
}

class _SearchChatScreenState extends State<SearchChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  bool _loading = false;
  String? _error;
  SearchChatResult _result = const SearchChatResult();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _search(value.trim());
    });
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() {
        _result = const SearchChatResult();
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ChatSearchService.search(
        accessToken: widget.accessToken,
        text: query,
        limit: 20,
      );
      if (!mounted) return;
      setState(() {
        _result = res;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _result = const SearchChatResult();
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onQueryChanged,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Tìm bạn bè, nhóm, page',
            border: InputBorder.none,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildResult(theme),
    );
  }

  Widget _buildResult(ThemeData theme) {
    if (_result.friends.isEmpty &&
        _result.groups.isEmpty &&
        _result.pages.isEmpty) {
      return const Center(child: Text('Nhập từ khóa để tìm kiếm'));
    }

    return ListView(
      children: [
        if (_result.friends.isNotEmpty) ...[
          const _SectionHeader(title: 'Bạn bè'),
          ..._result.friends.map((u) => ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      u.avatar != null ? NetworkImage(u.avatar!) : null,
                  child: u.avatar == null ? const Icon(Icons.person) : null,
                ),
                title: Text(u.name.isNotEmpty ? u.name : 'Bạn bè'),
                subtitle: u.lastMessageText != null
                    ? Text(u.lastMessageText!)
                    : null,
              )),
          const Divider(),
        ],
        if (_result.groups.isNotEmpty) ...[
          const _SectionHeader(title: 'Nhóm'),
          ..._result.groups.map((g) => ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      g.avatar != null ? NetworkImage(g.avatar!) : null,
                  child: g.avatar == null ? const Icon(Icons.group) : null,
                ),
                title: Text(g.name),
                subtitle: Text('Group #${g.groupId}'),
              )),
          const Divider(),
        ],
        if (_result.pages.isNotEmpty) ...[
          const _SectionHeader(title: 'Page'),
          ..._result.pages.cast<PageChatThread>().map((PageChatThread p) {
            final avatar = p.avatar;
            return ListTile(
              leading: CircleAvatar(
                backgroundImage:
                    avatar.isNotEmpty ? NetworkImage(avatar) : null,
                child: avatar.isEmpty ? const Icon(Icons.flag) : null,
              ),
              title: Text(p.pageTitle.isNotEmpty
                  ? p.pageTitle
                  : (p.pageName.isNotEmpty ? p.pageName : 'Page')),
              subtitle: Text(p.pageName),
            );
          }),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
