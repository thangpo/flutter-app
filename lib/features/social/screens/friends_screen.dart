import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  bool isLoading = false;
  List<dynamic> friendRequests = [];
  List<dynamic> recommendedFriends = [];
  List<dynamic> searchResults = [];
  String? errorMessage;
  final TextEditingController _searchController = TextEditingController();
  bool isSearchMode = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchRecommendedFriends();
    fetchFriendRequests();
    _searchController.addListener(_filterFriendsByUsername);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterFriendsByUsername);
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Color primaryColor(bool isDark) => isDark ? const Color(0xFF242526) : Colors.white;
  Color secondaryColor(bool isDark) => isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
  Color textColor(bool isDark) => isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
  Color subtextColor(bool isDark) => isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);
  Color dividerColor(bool isDark) => isDark ? const Color(0xFF3E4042) : const Color(0xFFE4E6EB);
  Color get accentColor => const Color(0xFF0866FF);

  Future<void> _refreshData() async {
    if (_tabController.index == 0) {
      await fetchFriendRequests();
    } else {
      await fetchRecommendedFriends();
    }
  }

  Future<void> fetchRecommendedFriends() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final authController = Provider.of<AuthController>(context, listen: false);
      final accessToken = await authController.authServiceInterface.getSocialAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = 'Token mạng xã hội không hợp lệ, vui lòng đăng nhập lại.';
        });
        return;
      }

      final url = '${AppConstants.socialBaseUrl}${AppConstants.socialFetchRecommendedUri}?access_token=$accessToken';

      final response = await http.post(
        Uri.parse(url),
        body: {
          'server_key': AppConstants.socialServerKey,
          'type': 'users',
          'limit': '50',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['api_status'] == 200) {
          setState(() {
            recommendedFriends = (data['data'] ?? []).map((f) {
              f['is_following'] = false;
              return f;
            }).toList();
            if (!isSearchMode) {
              searchResults = List.from(recommendedFriends);
            }
          });
        } else {
          errorMessage = data['errors']?['error_text'] ?? 'Không lấy được danh sách bạn bè.';
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

  Future<void> fetchFriendRequests() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final authController = Provider.of<AuthController>(context, listen: false);
      final userId = await authController.authServiceInterface.getSocialUserId();
      final accessToken = await authController.authServiceInterface.getSocialAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = 'Token mạng xã hội không hợp lệ, vui lòng đăng nhập lại.';
        });
        return;
      }

      final url = '${AppConstants.socialBaseUrl}/api/get-friends?access_token=$accessToken';

      final response = await http.post(
        Uri.parse(url),
        body: {
          'server_key': AppConstants.socialServerKey,
          'type': 'followers',
          'user_id': userId,
          'limit': '50',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['api_status'] == 200) {
          final followers = List<Map<String, dynamic>>.from(data['data']['followers'] ?? []);

          final requests = followers.where((f) {
            final isFollowing = f['is_following'] == 1 || f['is_following'] == true;
            final isFollowingMe = f['is_following_me'] == 1 || f['is_following_me'] == true;
            return isFollowingMe && !isFollowing;
          }).toList();

          setState(() {
            friendRequests = requests.map((u) {
              u['is_following'] = false;
              return u;
            }).toList();
          });
        } else {
          setState(() {
            errorMessage = data['errors']?['error_text'] ?? 'Không lấy được danh sách lời mời.';
          });
        }
      } else {
        setState(() {
          errorMessage = 'Lỗi máy chủ (${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Lỗi: $e';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _filterFriendsByUsername() {
    final input = _searchController.text.trim().toLowerCase();
    if (input.isEmpty) {
      setState(() {
        searchResults = _tabController.index == 0 ? List.from(friendRequests) : List.from(recommendedFriends);
        isSearchMode = false;
        errorMessage = null;
      });
      return;
    }

    setState(() {
      isSearchMode = true;
      final sourceList = _tabController.index == 0 ? friendRequests : recommendedFriends;
      searchResults = sourceList.where((f) {
        final username = (f['username'] ?? '').toLowerCase();
        return username.startsWith(input);
      }).toList();
      errorMessage = searchResults.isEmpty ? 'Không tìm thấy người dùng.' : null;
    });
  }

  Future<void> searchFriendByApi() async {
    final input = _searchController.text.trim();
    if (input.isEmpty) {
      final isDark = Provider.of<ThemeController>(context, listen: false).darkTheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng nhập username.'),
          backgroundColor: isDark ? const Color(0xFF3A3B3C) : null,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      isSearchMode = true;
    });

    final authController = Provider.of<AuthController>(context, listen: false);
    final accessToken = await authController.authServiceInterface.getSocialAccessToken();

    final url = '${AppConstants.socialBaseUrl}${AppConstants.socialGetUsername}?access_token=$accessToken';

    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          'server_key': AppConstants.socialServerKey,
          'fetch': 'user_data',
          'username': input,
          'send_notify': '1',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['api_status'] == 200 && data['user_data'] != null) {
          final user = data['user_data'];
          user['is_following'] = false;

          setState(() {
            searchResults = [user];
            isLoading = false;
          });
        } else {
          setState(() {
            searchResults = [];
            errorMessage = data['errors']?['error_text'] ?? 'Không tìm thấy người dùng.';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          searchResults = [];
          errorMessage = 'Lỗi máy chủ (${response.statusCode})';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        searchResults = [];
        errorMessage = 'Lỗi: $e';
        isLoading = false;
      });
    }
  }

  Future<void> showFriendDetail(String userId, bool isDark) async {
    final authController = Provider.of<AuthController>(context, listen: false);
    final accessToken = await authController.authServiceInterface.getSocialAccessToken();

    final url = '${AppConstants.socialBaseUrl}${AppConstants.socialGetUserDataInfoUri}?access_token=$accessToken';

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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['api_status'] == 200 && data['user_data'] != null) {
          final user = data['user_data'];
          final details = user['details'] ?? {};

          if (!mounted) return;
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: primaryColor(isDark),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Text(
                user['name'] ?? user['username'] ?? 'Người dùng',
                style: TextStyle(color: textColor(isDark), fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: dividerColor(isDark),
                            backgroundImage: user['avatar'] != null
                                ? NetworkImage(user['avatar'])
                                : const AssetImage('assets/images/profile_placeholder.png') as ImageProvider,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: primaryColor(isDark),
                                shape: BoxShape.circle,
                                border: Border.all(color: primaryColor(isDark), width: 2),
                              ),
                              child: Icon(Icons.camera_alt, size: 20, color: subtextColor(isDark)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        '@${user['username'] ?? ''}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: subtextColor(isDark),
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard([
                      _buildDetailRow('Giới tính', user['gender_text'] ?? user['gender'] ?? 'Không xác định', isDark),
                      _buildDetailRow('Email', user['email'] ?? 'Không có', isDark),
                    ], isDark),
                    const SizedBox(height: 12),
                    Text(
                      'Thống kê hoạt động',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor(isDark),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoCard([
                      _buildDetailRow('Bài viết', details['post_count'], isDark),
                      _buildDetailRow('Album', details['album_count'], isDark),
                      _buildDetailRow('Người theo dõi', details['followers_count'], isDark),
                      _buildDetailRow('Đang theo dõi', details['following_count'], isDark),
                      _buildDetailRow('Nhóm đã tham gia', details['groups_count'], isDark),
                      _buildDetailRow('Lượt thích', details['likes_count'], isDark),
                      _buildDetailRow('Bạn chung', details['mutual_friends_count'], isDark),
                    ], isDark),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: accentColor,
                  ),
                  child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Không lấy được thông tin người dùng.'),
              backgroundColor: isDark ? const Color(0xFF3A3B3C) : null,
            ),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi máy chủ (${response.statusCode})'),
            backgroundColor: isDark ? const Color(0xFF3A3B3C) : null,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: isDark ? const Color(0xFF3A3B3C) : null,
        ),
      );
    }
  }

  Future<void> followUser(String userId, int index, bool isDark) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: primaryColor(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Xác nhận theo dõi', style: TextStyle(color: textColor(isDark))),
        content: Text('Bạn có chắc muốn theo dõi người này không?', style: TextStyle(color: subtextColor(isDark))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy', style: TextStyle(color: subtextColor(isDark))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Theo dõi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final authController = Provider.of<AuthController>(context, listen: false);
    final accessToken = await authController.authServiceInterface.getSocialAccessToken();

    final url = '${AppConstants.socialBaseUrl}/api/follow-user?access_token=$accessToken';

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
          if (isSearchMode) {
            searchResults[index]['is_following'] = true;
          } else {
            if (_tabController.index == 0) {
              friendRequests[index]['is_following'] = true;
            } else {
              recommendedFriends[index]['is_following'] = true;
            }
          }
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã theo dõi thành công!'),
            backgroundColor: isDark ? const Color(0xFF3A3B3C) : null,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Theo dõi thất bại: ${data['error_text'] ?? 'Lỗi không xác định'}'),
            backgroundColor: isDark ? const Color(0xFF3A3B3C) : null,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: isDark ? const Color(0xFF3A3B3C) : null,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeController>(
      builder: (context, themeController, child) {
        final isDark = themeController.darkTheme;

        return Scaffold(
          backgroundColor: secondaryColor(isDark),
          appBar: AppBar(
            elevation: 0,
            title: Text(
              isSearchMode ? 'Kết quả tìm kiếm' : 'Bạn bè',
              style: TextStyle(
                color: textColor(isDark),
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            backgroundColor: primaryColor(isDark),
            leading: isSearchMode
                ? IconButton(
              icon: Icon(Icons.arrow_back, color: textColor(isDark)),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  searchResults = _tabController.index == 0
                      ? List.from(friendRequests)
                      : List.from(recommendedFriends);
                  isSearchMode = false;
                  errorMessage = null;
                });
              },
            )
                : null,
            actions: const [],
            bottom: isSearchMode
                ? null
                : PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: primaryColor(isDark),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: accentColor,
                  indicatorWeight: 3,
                  labelColor: accentColor,
                  unselectedLabelColor: subtextColor(isDark),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  tabs: const [
                    Tab(text: 'Lời mời kết bạn'),
                    Tab(text: 'Gợi ý'),
                  ],
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              Container(
                color: primaryColor(isDark),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: secondaryColor(isDark),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: textColor(isDark)),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm bạn bè...',
                      hintStyle: TextStyle(color: subtextColor(isDark)),
                      prefixIcon: Icon(Icons.search, color: subtextColor(isDark)),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.clear, color: subtextColor(isDark)),
                            onPressed: () {
                              _searchController.clear();
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.search, color: accentColor),
                            onPressed: searchFriendByApi,
                            tooltip: 'Tìm kiếm API',
                          ),
                        ],
                      )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: isLoading
                    ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                )
                    : errorMessage != null
                    ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: subtextColor(isDark)),
                        const SizedBox(height: 16),
                        Text(
                          errorMessage!,
                          style: TextStyle(color: subtextColor(isDark), fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        if (isSearchMode) ...[
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                searchResults = _tabController.index == 0
                                    ? List.from(friendRequests)
                                    : List.from(recommendedFriends);
                                isSearchMode = false;
                                errorMessage = null;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Quay lại'),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
                    : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFriendList(isSearchMode ? searchResults : friendRequests, isDark),
                    _buildFriendList(isSearchMode ? searchResults : recommendedFriends, isDark),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFriendList(List<dynamic> list, bool isDark) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSearchMode ? Icons.search_off : Icons.people_outline,
                size: 64,
                color: subtextColor(isDark),
              ),
              const SizedBox(height: 16),
              Text(
                isSearchMode
                    ? 'Không tìm thấy người dùng.'
                    : _tabController.index == 0
                    ? 'Không có lời mời kết bạn.'
                    : 'Không có gợi ý bạn bè.',
                style: TextStyle(color: subtextColor(isDark), fontSize: 16),
                textAlign: TextAlign.center,
              ),
              if (isSearchMode) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      searchResults = _tabController.index == 0
                          ? List.from(friendRequests)
                          : List.from(recommendedFriends);
                      isSearchMode = false;
                      errorMessage = null;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Quay lại'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: accentColor,
      backgroundColor: primaryColor(isDark),
      child: ListView.separated(
        itemCount: list.length,
        separatorBuilder: (context, index) => Divider(
          color: dividerColor(isDark),
          height: 1,
          thickness: 1,
        ),
        itemBuilder: (context, index) {
          final user = list[index];
          final name = user['name'] ?? user['username'] ?? 'Người dùng';
          final avatar = user['avatar'] ?? '';
          final username = user['username'] ?? '';
          final userId = user['user_id']?.toString() ?? '';
          final isFollowing = user['is_following'] ?? false;

          return Container(
            color: primaryColor(isDark),
            child: InkWell(
              onTap: () => showFriendDetail(userId, isDark),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: dividerColor(isDark),
                          backgroundImage: avatar.isNotEmpty
                              ? NetworkImage(avatar)
                              : const AssetImage('assets/images/profile_placeholder.png') as ImageProvider,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: const Color(0xFF31A24C),
                              shape: BoxShape.circle,
                              border: Border.all(color: primaryColor(isDark), width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              color: textColor(isDark),
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '@$username',
                            style: TextStyle(
                              color: subtextColor(isDark),
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: isFollowing ? null : () => followUser(userId, index, isDark),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFollowing ? secondaryColor(isDark) : accentColor,
                        foregroundColor: isFollowing ? subtextColor(isDark) : Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        isFollowing ? 'Bạn bè' : 'Thêm',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: secondaryColor(isDark),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDetailRow(String label, dynamic value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: subtextColor(isDark), fontSize: 14),
          ),
          Text(
            value?.toString() ?? '0',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: textColor(isDark),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}