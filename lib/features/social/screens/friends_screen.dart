import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  bool isLoading = false;
  List<dynamic> friends = [];
  String? errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchRecommendedFriends();
  }

  Future<void> fetchRecommendedFriends() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final authController =
      Provider.of<AuthController>(context, listen: false);
      final accessToken =
      await authController.authServiceInterface.getSocialAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = 'Token mạng xã hội không hợp lệ, vui lòng đăng nhập lại.';
        });
        return;
      }

      final url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialFetchRecommendedUri}?access_token=$accessToken';

      final response = await http.post(
        Uri.parse(url),
        body: {
          'server_key': AppConstants.socialServerKey,
          'type': 'users',
          'limit': '20',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['api_status'] == 200) {
          setState(() {
            friends = (data['data'] ?? []).map((f) {
              f['is_following'] = false;
              return f;
            }).toList();
          });
        } else {
          errorMessage =
              data['errors']?['error_text'] ?? 'Không lấy được danh sách bạn bè.';
        }
      } else {
        errorMessage = 'Lỗi máy chủ (${response.statusCode})';
      }
    } catch (e) {
      errorMessage = 'Lỗi: $e';
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> searchFriendByUsername() async {
    final username = _searchController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Vui lòng nhập tên người dùng.')));
      return;
    }

    final authController = Provider.of<AuthController>(context, listen: false);
    final accessToken =
    await authController.authServiceInterface.getSocialAccessToken();

    final url =
        '${AppConstants.socialBaseUrl}${AppConstants.socialCheckUsernameUri}?access_token=$accessToken';

    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          'server_key': AppConstants.socialServerKey,
          'username': username,
        },
      );

      print('🔎 Search response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['api_status'] == 200 && data['user_data'] != null) {
          final user = data['user_data'];
          showFriendDetail(user['user_id'].toString());
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['errors']?['error_text'] ?? 'Không tìm thấy người dùng.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi máy chủ (${response.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> showFriendDetail(String userId) async {
    final authController = Provider.of<AuthController>(context, listen: false);
    final accessToken =
    await authController.authServiceInterface.getSocialAccessToken();

    final url =
        '${AppConstants.socialBaseUrl}${AppConstants.socialGetUserDataInfoUri}?access_token=$accessToken';

    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          'server_key': AppConstants.socialServerKey,
          'type': 'get_user_data',
          'fetch': 'user_data,followers,following,liked_pages',
          'user_id': userId,
        },
      );

      print('📩 User detail response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['api_status'] == 200 && data['user_data'] != null) {
          final user = data['user_data'];
          final details = user['details'] ?? {};

          if (!mounted) return;
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(user['name'] ?? user['username'] ?? 'Người dùng'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage: user['avatar'] != null
                            ? NetworkImage(user['avatar'])
                            : const AssetImage('assets/images/profile_placeholder.png')
                        as ImageProvider,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                        child: Text('@${user['username'] ?? ''}',
                            style:
                            const TextStyle(fontWeight: FontWeight.bold))),
                    const SizedBox(height: 8),
                    Text(
                        'Giới tính: ${user['gender_text'] ?? user['gender'] ?? 'Không xác định'}'),
                    Text('Email: ${user['email'] ?? 'Không có'}'),
                    const Divider(height: 20, thickness: 1),
                    const Text('Thống kê hoạt động:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    _buildDetailRow('Bài viết', details['post_count']),
                    _buildDetailRow('Album', details['album_count']),
                    _buildDetailRow('Người theo dõi', details['followers_count']),
                    _buildDetailRow('Đang theo dõi', details['following_count']),
                    _buildDetailRow('Nhóm đã tham gia', details['groups_count']),
                    _buildDetailRow('Lượt thích', details['likes_count']),
                    _buildDetailRow('Bạn chung', details['mutual_friends_count']),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không lấy được thông tin người dùng.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi máy chủ (${response.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> followUser(String userId, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận theo dõi'),
        content: const Text('Bạn có chắc muốn theo dõi người này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Theo dõi'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final authController = Provider.of<AuthController>(context, listen: false);
    final accessToken =
    await authController.authServiceInterface.getSocialAccessToken();

    final url =
        '${AppConstants.socialBaseUrl}/api/follow-user?access_token=$accessToken';

    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          'server_key': AppConstants.socialServerKey,
          'user_id': userId,
          'type': 'follow_user',
        },
      );

      final data = jsonDecode(response.body);
      if (data['api_status'] == 200) {
        setState(() {
          friends[index]['is_following'] = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã theo dõi thành công!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Theo dõi thất bại: ${data['error_text'] ?? 'Lỗi không xác định'}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách bạn bè'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchRecommendedFriends,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!))
          : friends.isEmpty
          ? const Center(child: Text('Không có bạn bè được đề xuất.'))
          : ListView.builder(
        itemCount: friends.length,
        itemBuilder: (context, index) {
          final user = friends[index];
          final name = user['name'] ?? 'Người dùng';
          final avatar = user['avatar'] ?? '';
          final username = user['username'] ?? '';
          final userId = user['user_id']?.toString() ?? '';
          final isFollowing = user['is_following'] ?? false;

          return ListTile(
            leading: GestureDetector(
              onTap: () => showFriendDetail(userId),
              child: CircleAvatar(
                backgroundImage: avatar.isNotEmpty
                    ? NetworkImage(avatar)
                    : const AssetImage(
                    'assets/images/profile_placeholder.png')
                as ImageProvider,
              ),
            ),
            title: GestureDetector(
              onTap: () => showFriendDetail(userId),
              child: Text(name),
            ),
            subtitle: Text('@$username'),
            trailing: ElevatedButton(
              onPressed: isFollowing
                  ? null
                  : () => followUser(userId, index),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                isFollowing ? Colors.grey : Colors.blue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                  isFollowing ? 'Đã theo dõi' : 'Theo dõi'),
            ),
          );
        },
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tìm bạn bè'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Nhập username cần tìm...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              searchFriendByUsername();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Tìm'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black87)),
          Text(value?.toString() ?? '0',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
