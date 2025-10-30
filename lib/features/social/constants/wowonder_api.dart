/// ✅ WoWonder API endpoints
/// Tất cả endpoint đều nối sau `AppConstants.socialBaseUrl`
class WowonderAPI {
  // 🔹 Chat nhóm
  static const String groupChat = '/api/group_chat';

  // 🔹 Chat cá nhân (nếu dùng sau này)
  static const String chat = '/api/chat';

  // 🔹 Livestream (nếu cần tích hợp sau)
  static const String live = '/api/live';

  // 🔹 Đăng bài (tích hợp social post)
  static const String createPost = '/api/posts/create';

  // 🔹 Danh sách bạn bè
  static const String getFriends = '/api/get_friends';

  // 🔹 AI image generation (WoWonder AI module)
  static const String aiImage = '/api/ai_image';

  // 🔹 Cấu hình / thông tin user
  static const String me = '/api/me';
}
