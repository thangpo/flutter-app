import 'dart:convert';
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';


class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  bool isLoading = false;
  List<dynamic> friendRequests = [];
  List<dynamic> myFriends = [];
  List<dynamic> recommendedFriends = [];
  List<dynamic> searchResults = [];
  String? errorMessage;
  final TextEditingController _searchController = TextEditingController();
  bool isSearchMode = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchFriendRequests();       // tab 0
    fetchMyFriends();            // tab 1 (bạn bè của tôi)
    fetchRecommendedFriends();   // tab 2

    _searchController.addListener(_filterFriendsByUsername);

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        if (_searchController.text.trim().isNotEmpty) {
          _filterFriendsByUsername();
        } else {
          setState(() {}); // update UI segment highlight
        }
      }
    });
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
    } else if (_tabController.index == 1) {
      await fetchMyFriends();
    } else {
      await fetchRecommendedFriends();
    }
  }

  Future<void> fetchMyFriends() async {
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
          errorMessage = getTranslated('social_token_invalid', context) ??
              'Invalid social token, please login again.';
        });
        return;
      }

      final url = '${AppConstants.socialBaseUrl}/api/get-friends?access_token=$accessToken';

      // 1) followers
      final followersRes = await http.post(
        Uri.parse(url),
        body: {
          'server_key': AppConstants.socialServerKey,
          'type': 'followers',
          'user_id': userId,
          'limit': '200',
        },
      );

      // 2) following
      final followingRes = await http.post(
        Uri.parse(url),
        body: {
          'server_key': AppConstants.socialServerKey,
          'type': 'following',
          'user_id': userId,
          'limit': '200',
        },
      );

      if (followersRes.statusCode != 200 || followingRes.statusCode != 200) {
        setState(() {
          errorMessage = (getTranslated('server_error', context) ?? 'Server error') +
              ' (${followersRes.statusCode}/${followingRes.statusCode})';
        });
        return;
      }

      final followersData = jsonDecode(followersRes.body);
      final followingData = jsonDecode(followingRes.body);

      if (followersData['api_status'] != 200 || followingData['api_status'] != 200) {
        setState(() {
          errorMessage = getTranslated('cannot_get_friends', context) ??
              'Cannot load friends list.';
        });
        return;
      }

      final followers = List<Map<String, dynamic>>.from(
        (followersData['data']?['followers'] ?? []) as List,
      );

      final following = List<Map<String, dynamic>>.from(
        (followingData['data']?['following'] ?? []) as List,
      );

      final followerIds = followers
          .map((e) => (e['user_id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet();

      final friends = following.where((u) {
        final id = (u['user_id'] ?? '').toString();
        return id.isNotEmpty && followerIds.contains(id);
      }).toList();

      setState(() {
        myFriends = friends.map((u) {
          u['is_following'] = true; // mutual => đang theo dõi
          return u;
        }).toList();

        if (!isSearchMode && _tabController.index == 1) {
          searchResults = List.from(myFriends);
        }
      });
    } catch (e) {
      setState(() {
        errorMessage = (getTranslated('error', context) ?? 'Error') + ': $e';
      });
    } finally {
      setState(() => isLoading = false);
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
          errorMessage = getTranslated('social_token_invalid', context) ?? 'Invalid social token, please login again.';
        }
      } else {
        errorMessage = (getTranslated('server_error', context) ?? 'Server error') + ' (${response.statusCode})';
      }
    } catch (e) {
      errorMessage = (getTranslated('error', context) ?? 'Error') + ': $e';
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
          errorMessage = getTranslated('social_token_invalid', context) ?? 'Invalid social token, please login again.';
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

    final sourceList = _tabController.index == 0
        ? friendRequests
        : (_tabController.index == 1 ? myFriends : recommendedFriends);

    if (input.isEmpty) {
      setState(() {
        searchResults = List.from(sourceList);
        isSearchMode = false;
        errorMessage = null;
      });
      return;
    }

    setState(() {
      isSearchMode = true;
      searchResults = sourceList.where((f) {
        final username = (f['username'] ?? '').toString().toLowerCase();
        return username.startsWith(input);
      }).toList();

      errorMessage = searchResults.isEmpty
          ? (getTranslated('user_not_found', context) ?? 'User not found.')
          : null;
    });
  }

  void _removeFromMyFriends(String userId) {
    setState(() {
      myFriends.removeWhere((u) => (u['user_id']?.toString() ?? '') == userId);
      searchResults.removeWhere((u) => (u['user_id']?.toString() ?? '') == userId);
    });
  }

  Future<void> searchFriendByApi() async {
    final input = _searchController.text.trim();
    if (input.isEmpty) {
      final isDark = Provider.of<ThemeController>(context, listen: false).darkTheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getTranslated('please_enter_username', context) ?? 'Please enter username.'),
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
            errorMessage = data['errors']?['error_text'] ?? (getTranslated('cannot_get_friends', context) ?? 'Cannot load friends list.');
            isLoading = false;
          });
        }
      } else {
        setState(() {
          searchResults = [];
          errorMessage = (getTranslated('server_error', context) ?? 'Server error') + ' (${response.statusCode})';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        searchResults = [];
        errorMessage = (getTranslated('error', context) ?? 'Error') + ': $e';
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
                user['name'] ?? user['username'] ?? (getTranslated('user', context) ?? 'User'),
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
                      _buildDetailRow(getTranslated('gender', context) ?? 'Gender',
                          user['gender_text'] ?? user['gender'] ?? (getTranslated('unknown', context) ?? 'Unknown'), isDark),
                      _buildDetailRow(getTranslated('email', context) ?? 'Email',
                          user['email'] ?? (getTranslated('none', context) ?? 'None'), isDark),
                    ], isDark),
                    const SizedBox(height: 12),
                    Text(
                      getTranslated('activity_statistics', context) ?? 'Activity statistics',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor(isDark),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoCard([
                      _buildDetailRow(getTranslated('posts', context) ?? 'Posts', details['post_count'], isDark),
                      _buildDetailRow(getTranslated('albums', context) ?? 'Albums', details['album_count'], isDark),
                      _buildDetailRow(getTranslated('followers', context) ?? 'Followers', details['followers_count'], isDark),
                      _buildDetailRow(getTranslated('following', context) ?? 'Following', details['following_count'], isDark),
                      _buildDetailRow(getTranslated('joined_groups', context) ?? 'Joined groups', details['groups_count'], isDark),
                      _buildDetailRow(getTranslated('likes', context) ?? 'Likes', details['likes_count'], isDark),
                      _buildDetailRow(getTranslated('mutual_friends', context) ?? 'Mutual friends', details['mutual_friends_count'], isDark),
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
                  child: Text(getTranslated('close', context) ?? 'Close', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(getTranslated('cannot_get_user_info', context) ?? 'Cannot load user info.'),
              backgroundColor: isDark ? const Color(0xFF3A3B3C) : null,
            ),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text((getTranslated('server_error', context) ?? 'Server error') + ' (${response.statusCode})'),
            backgroundColor: isDark ? const Color(0xFF3A3B3C) : null,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((getTranslated('error', context) ?? 'Error') + ': $e'),
          backgroundColor: isDark ? const Color(0xFF3A3B3C) : null,
        ),
      );
    }
  }

  Future<void> followUser(String userId, int index, bool isDark, {bool isUnfollow = false}) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: primaryColor(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          isUnfollow
              ? (getTranslated('confirm_unfollow', context) ?? 'Confirm unfollow')
              : (getTranslated('confirm_follow', context) ?? 'Confirm follow'),
          style: TextStyle(color: textColor(isDark)),
        ),
        content: Text(
          isUnfollow
              ? (getTranslated('confirm_unfollow_desc', context) ?? 'Are you sure you want to unfollow this user?')
              : (getTranslated('confirm_follow_desc', context) ?? 'Are you sure you want to follow this user?'),
          style: TextStyle(color: subtextColor(isDark)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(getTranslated('cancel', context) ?? 'Cancel',
                style: TextStyle(color: subtextColor(isDark))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              isUnfollow
                  ? (getTranslated('unfollow', context) ?? 'Unfollow')
                  : (getTranslated('follow', context) ?? 'Follow'),
              style: const TextStyle(color: Colors.white),
            ),
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
          'type': 'follow_user', // ✅ WoWonder thường toggle follow/unfollow cùng endpoint
        },
      );

      final data = jsonDecode(response.body);

      if (data['api_status'] == 200) {
        if (isUnfollow) {
          // ✅ bỏ khỏi “Bạn bè của tôi”
          _removeFromMyFriends(userId);
        } else {
          setState(() {
            // update item đang hiển thị
            if (isSearchMode) {
              searchResults[index]['is_following'] = true;
            } else {
              if (_tabController.index == 0) friendRequests[index]['is_following'] = true;
              if (_tabController.index == 2) recommendedFriends[index]['is_following'] = true;
            }
          });
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isUnfollow
                  ? (getTranslated('unfollow_success', context) ?? 'Unfollowed successfully!')
                  : (getTranslated('follow_success', context) ?? 'Followed successfully!'),
            ),
            backgroundColor: isDark ? const Color(0xFF3A3B3C) : null,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              (isUnfollow
                  ? (getTranslated('unfollow_failed', context) ?? 'Unfollow failed')
                  : (getTranslated('follow_failed', context) ?? 'Follow failed')) +
                  ': ${data['error_text'] ?? (getTranslated('unknown_error', context) ?? 'Unknown error')}',
            ),
            backgroundColor: isDark ? const Color(0xFF3A3B3C) : null,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((getTranslated('error', context) ?? 'Error') + ': $e'),
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

        final theme = Theme.of(context);
        final appBarBackground = primaryColor(isDark);
        final appBarForeground = textColor(isDark);
        final unselectedTabColor = subtextColor(isDark);

        return Scaffold(
          backgroundColor: secondaryColor(isDark),

          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(188),
            child: Container(
              decoration: BoxDecoration(
                color: appBarBackground,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ===== TOP ROW =====
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          _RoundIconButton(
                            icon: Icons.arrow_back,
                            onTap: () => Navigator.pop(context),
                            background: isDark
                                ? Colors.white.withOpacity(0.06)
                                : Colors.black.withOpacity(0.04),
                            iconColor: appBarForeground,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            getTranslated('friends', context) ?? 'Friends',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: appBarForeground,
                            ),
                          ),
                          const Spacer(),
                          _RoundIconButton(
                            icon: Icons.refresh,
                            onTap: _refreshData,
                            background: isDark
                                ? Colors.white.withOpacity(0.06)
                                : Colors.black.withOpacity(0.04),
                            iconColor: appBarForeground,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // ===== TAB BAR (PILL) =====
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: secondaryColor(isDark),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: AnimatedBuilder(
                          animation: _tabController.animation!,
                          builder: (context, _) {
                            final anim = _tabController.animation!;
                            final page = anim.value;
                            final distToNearest =
                            (page - page.round()).abs().clamp(0.0, 0.5);
                            final progress = (distToNearest / 0.5).clamp(0.0, 1.0);
                            final radius = lerpDouble(12, 999, progress)!;

                            return TabBar(
                              controller: _tabController,
                              isScrollable: false,
                              dividerColor: Colors.transparent,
                              indicator: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(radius),
                              ),
                              indicatorSize: TabBarIndicatorSize.tab,
                              labelColor: Colors.white,
                              unselectedLabelColor: unselectedTabColor,
                              labelStyle: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              tabs: [
                                Tab(text: getTranslated('friend_requests', context) ?? 'Friend requests'),
                                Tab(text: getTranslated('my_friends', context) ?? 'My friends'),
                                Tab(text: getTranslated('suggestions', context) ?? 'Suggestions'),
                              ],
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ===== SEARCH BAR (IN APPBAR) =====
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: secondaryColor(isDark),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(color: textColor(isDark)),
                          decoration: InputDecoration(
                            hintText: getTranslated('search_friends', context) ?? 'Search friends...',
                            hintStyle: TextStyle(color: subtextColor(isDark)),
                            prefixIcon: Icon(Icons.search, color: subtextColor(isDark)),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.clear, color: subtextColor(isDark)),
                                  onPressed: () => _searchController.clear(),
                                ),
                                IconButton(
                                  icon: Icon(Icons.search, color: accentColor),
                                  onPressed: searchFriendByApi,
                                  tooltip: getTranslated('search_api', context) ?? 'Search API',
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

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),

          // Body chỉ còn TabBarView giống Pages/Groups
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildFriendList(
                (isSearchMode && _tabController.index == 0) ? searchResults : friendRequests,
                isDark,
                allowUnfollow: false,
                emptyKey: 'no_friend_requests',
                tabIndex: 0,
              ),
              _buildFriendList(
                (isSearchMode && _tabController.index == 1) ? searchResults : myFriends,
                isDark,
                allowUnfollow: true,
                emptyKey: 'no_my_friends',
                tabIndex: 1,
              ),
              _buildFriendList(
                (isSearchMode && _tabController.index == 2) ? searchResults : recommendedFriends,
                isDark,
                allowUnfollow: false,
                emptyKey: 'no_suggestions',
                tabIndex: 2,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSegment({
    required String label,
    required int tabIndex,
    required bool isSelected,
    required bool isDark,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _tabController.animateTo(tabIndex),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: isSelected ? accentColor : Colors.transparent,
            borderRadius: BorderRadius.circular(isSelected ? 20 : 12),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : subtextColor(isDark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFriendList(List<dynamic> list, bool isDark, {required bool allowUnfollow, required String emptyKey, required int tabIndex}) {
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
                    ? (getTranslated('user_not_found', context) ?? 'User not found.')
                    : _tabController.index == 0
                    ? (getTranslated('no_friend_requests', context) ?? 'No friend requests.')
                    : (getTranslated('no_suggestions', context) ?? 'No suggestions.'),
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
                  child: Text(getTranslated('back', context) ?? 'Back'),
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
          final name = user['name'] ?? user['username'] ?? (getTranslated('user', context) ?? 'User');
          final avatar = user['avatar'] ?? '';
          final username = user['username'] ?? '';
          final userId = user['user_id']?.toString() ?? '';
          final bool isFollowing = user['is_following'] == true || user['is_following'] == 1;

          final String btnText = allowUnfollow
              ? (getTranslated('unfollow', context) ?? 'Unfollow')
              : (isFollowing
              ? (getTranslated('following', context) ?? 'Following')
              : (tabIndex == 2
              ? (getTranslated('follow', context) ?? 'Follow')
              : (getTranslated('add', context) ?? 'Add')));

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
                      onPressed: allowUnfollow
                          ? () => followUser(userId, index, isDark, isUnfollow: true)
                          : (isFollowing ? null : () => followUser(userId, index, isDark)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: allowUnfollow
                            ? secondaryColor(isDark)
                            : (isFollowing ? secondaryColor(isDark) : accentColor),
                        foregroundColor: allowUnfollow
                            ? (isDark ? Colors.white : Colors.black87)
                            : (isFollowing ? subtextColor(isDark) : Colors.white),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: Text(btnText, style: const TextStyle(fontWeight: FontWeight.w600)),
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

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? background;
  final Color? iconColor;

  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.background,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: background ?? Theme.of(context).cardColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: iconColor),
      ),
    );
  }
}