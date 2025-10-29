import 'social_user.dart';

class SocialGroup {
  final String id;
  final String name;
  final String? title;
  final String? about;
  final String? description;
  final String? category;
  final String? subCategory;
  final String? privacy;
  final String? joinPrivacy;
  final String? avatarUrl;
  final String? coverUrl;
  final int memberCount;
  final int pendingCount;
  final bool isJoined;
  final bool isAdmin;
  final bool isOwner;
  final bool requiresApproval;
  final int joinRequestStatus;
  final SocialUser? owner;
  final Map<String, dynamic> customFields;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? status;
  final String? url;

  const SocialGroup({
    required this.id,
    required this.name,
    this.title,
    this.about,
    this.description,
    this.category,
    this.subCategory,
    this.privacy,
    this.joinPrivacy,
    this.avatarUrl,
    this.coverUrl,
    this.memberCount = 0,
    this.pendingCount = 0,
    this.isJoined = false,
    this.isAdmin = false,
    this.isOwner = false,
    this.requiresApproval = false,
    this.joinRequestStatus = 0,
    this.owner,
    this.customFields = const <String, dynamic>{},
    this.createdAt,
    this.updatedAt,
    this.status,
    this.url,
  });

  SocialGroup copyWith({
    String? id,
    String? name,
    String? title,
    String? about,
    String? description,
    String? category,
    String? subCategory,
    String? privacy,
    String? joinPrivacy,
    String? avatarUrl,
    String? coverUrl,
    int? memberCount,
    int? pendingCount,
    bool? isJoined,
    bool? isAdmin,
    bool? isOwner,
    bool? requiresApproval,
    int? joinRequestStatus,
    SocialUser? owner,
    Map<String, dynamic>? customFields,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
    String? url,
  }) {
    return SocialGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      about: about ?? this.about,
      description: description ?? this.description,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      privacy: privacy ?? this.privacy,
      joinPrivacy: joinPrivacy ?? this.joinPrivacy,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      memberCount: memberCount ?? this.memberCount,
      pendingCount: pendingCount ?? this.pendingCount,
      isJoined: isJoined ?? this.isJoined,
      isAdmin: isAdmin ?? this.isAdmin,
      isOwner: isOwner ?? this.isOwner,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      joinRequestStatus: joinRequestStatus ?? this.joinRequestStatus,
      owner: owner ?? this.owner,
      customFields: customFields ?? this.customFields,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      url: url ?? this.url,
    );
  }
}
