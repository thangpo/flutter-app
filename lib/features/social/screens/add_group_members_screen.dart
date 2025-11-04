// lib/features/social/screens/add_group_members_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/group_chat_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_friends_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/social_friends_repository.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_friend.dart';

class AddGroupMembersScreen extends StatefulWidget {
  final String groupId;
  final Set<String> existingMemberIds; // thành viên đã trong nhóm

  const AddGroupMembersScreen({
    super.key,
    required this.groupId,
    required this.existingMemberIds,
  });

  @override
  State<AddGroupMembersScreen> createState() => _AddGroupMembersScreenState();
}

class _AddGroupMembersScreenState extends State<AddGroupMembersScreen> {
  final friendsCtrl =
      Get.put(SocialFriendsController(SocialFriendsRepository()));
  final TextEditingController _searchCtrl = TextEditingController();

  final Set<String> _selectedIds = {};
  String _query = '';
  bool _loading = true;

  String? _currentUserId;

  @override
  void initState() {
    super.initState();

    // Lấy current user id
    try {
      _currentUserId = context.read<GroupChatController>().currentUserId;
    } catch (_) {}

    // Nếu chưa có danh sách bạn bè -> tự nạp từ token trong SP
    Future.microtask(() async {
      if (friendsCtrl.friends.isEmpty) {
        final sp = await SharedPreferences.getInstance();
        final token = sp.getString(AppConstants.socialAccessToken) ?? '';
        if (token.isNotEmpty) {
          await friendsCtrl.load(token, context: context);
        }
      }
      if (mounted) setState(() => _loading = false);
    });

    // Đồng bộ search local + controller để suggest hợp lý
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
      friendsCtrl.search(_searchCtrl.text);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ---------- Data helpers ----------
  List<SocialFriend> _baseListAll() {
    try {
      return List<SocialFriend>.from(friendsCtrl.friends);
    } catch (_) {
      return friendsCtrl.friends.cast<SocialFriend>();
    }
  }

  List<SocialFriend> _baseListFilteredByController() {
    try {
      return List<SocialFriend>.from(friendsCtrl.filtered);
    } catch (_) {
      return friendsCtrl.filtered.cast<SocialFriend>();
    }
  }

  SocialFriend? _findById(String id) {
    for (final f in _baseListAll()) {
      if (f.id == id) return f;
    }
    return null;
  }

  bool _shouldSkip(SocialFriend f) {
    final id = f.id;
    if (id.isEmpty) return true;
    if ((_currentUserId ?? '').isNotEmpty && id == _currentUserId)
      return true; // bỏ chính mình
    if (widget.existingMemberIds.contains(id))
      return true; // bỏ người đã trong nhóm
    return false;
  }

  List<SocialFriend> _eligible() {
    // lấy theo list đã filter của controller + filter bổ sung (skip & query)
    final src = _baseListFilteredByController();
    final list = src.where((f) => !_shouldSkip(f)).toList();
    if (_query.isEmpty) return list;

    return list.where((f) {
      final name = (f.name).toLowerCase();
      return name.contains(_query);
    }).toList();
  }

  List<SocialFriend> _selectedFriends() {
    final all = _baseListAll();
    return all.where((f) => _selectedIds.contains(f.id)).toList();
  }

  // ---------- Actions ----------
  Future<void> _submit() async {
    final ctrl = context.read<GroupChatController>();
    final ids = _selectedIds.toList();
    if (ids.isEmpty) return;

    final ok = await ctrl.addUsers(widget.groupId, ids);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ctrl.lastError ?? 'Thêm thành viên thất bại')),
      );
      return;
    }
    Navigator.pop(context, true);
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  // ---------- UI bits ----------
  Widget _searchPill(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TextField(
        controller: _searchCtrl,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: const Color(0xFFF2F4F7),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _selectedChips() {
    final sel = _selectedFriends();
    if (sel.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 96,
      child: ListView.separated(
        padding: const EdgeInsets.only(left: 16, right: 12, top: 6, bottom: 6),
        scrollDirection: Axis.horizontal,
        itemCount: sel.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) {
          final f = sel[i];
          final avatar = f.avatar ?? '';
          final hasAvatar = avatar.isNotEmpty;
          final displayName = f.name.isNotEmpty ? f.name : 'Người dùng';
          final initial =
              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

          return Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundImage: hasAvatar ? NetworkImage(avatar) : null,
                    child: hasAvatar
                        ? null
                        : Text(initial,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Positioned(
                    right: -2,
                    top: -2,
                    child: GestureDetector(
                      onTap: () => _toggleSelect(f.id),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.close,
                            size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 66,
                child: Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        children: [
          Text(text,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Color(0xFF5F6368))),
        ],
      ),
    );
  }

  Widget _selectCheck(bool selected) {
    final primary = Theme.of(context).colorScheme.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? primary : Colors.transparent,
        border: Border.all(
          color: selected ? primary : Colors.grey.shade400,
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }

  Widget _friendTile(SocialFriend f) {
    final id = f.id;
    final selected = _selectedIds.contains(id);
    final avatarUrl = f.avatar ?? '';
    final hasAvatar = avatarUrl.isNotEmpty;
    final displayName = f.name.isNotEmpty ? f.name : 'Người dùng';

    return InkWell(
      onTap: () => _toggleSelect(id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 22,
                backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                child: hasAvatar
                    ? null
                    : Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              _selectCheck(selected),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Build ----------
  @override
  Widget build(BuildContext context) {
    final canSubmit = _selectedIds.isNotEmpty && !_loading;
    final listNow = _eligible();
    final isBusy = _loading ||
        (friendsCtrl.isLoading.value && friendsCtrl.filtered.isEmpty);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: const Text('Thêm người'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: canSubmit ? _submit : null,
            style: TextButton.styleFrom(
              foregroundColor: canSubmit
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
            child: Text(
              canSubmit ? 'Thêm (${_selectedIds.length})' : 'Thêm',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _searchPill(context),
          _selectedChips(),
          _sectionLabel('Gợi ý'),
          Expanded(
            child: isBusy
                ? const Center(child: CircularProgressIndicator())
                : (listNow.isEmpty
                    ? const Center(child: Text('Không còn ai để thêm.'))
                    : ListView.separated(
                        itemCount: listNow.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: Colors.grey.shade200,
                          indent: 68,
                        ),
                        itemBuilder: (ctx, i) => _friendTile(listNow[i]),
                      )),
          ),
        ],
      ),
    );
  }
}
