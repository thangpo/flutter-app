import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_event_user.dart';

class SocialEvent {
  final String? id;
  final String? name;
  final String? location;
  final String? description;
  final String? startDate;
  final String? startTime;
  final String? endDate;
  final String? endTime;
  final String? posterId;
  final String? cover;
  final SocialEventUser? user;
  bool isOwner;
  bool isGoing;
  bool isInterested;
  bool isInvited;
  bool isPast;
  final String? userId;
  final String? startEditDate;
  final String? startDateJs;
  final String? endEditDate;
  final String? url;

  SocialEvent({
    this.id,
    this.name,
    this.location,
    this.description,
    this.startDate,
    this.startTime,
    this.endDate,
    this.endTime,
    this.posterId,
    this.cover,
    this.user,
    this.isOwner = false,
    required this.isGoing,
    required this.isInterested,
    required this.isInvited,
    required this.isPast,
    this.userId,
    this.startEditDate,
    this.startDateJs,
    this.endEditDate,
    this.url,
  });

  factory SocialEvent.fromJson(Map<String, dynamic> json) {
    return SocialEvent(
      id: json['id']?.toString(),
      name: json['name'],
      location: json['location'],
      description: json['description'],
      startDate: json['start_date'],
      startTime: json['start_time'],
      endDate: json['end_date'],
      endTime: json['end_time'],
      posterId: json['poster_id']?.toString(),
      cover: json['cover'],
      user: json['user_data'] != null
          ? SocialEventUser.fromJson(json['user_data'])
          : null,
      isOwner: json['is_owner'] == true || json['is_owner'] == 1,
      isGoing: json['is_going'] == 1,
      isInterested: json['is_interested'] == 1,
      isInvited: json['is_invited'] == 1,
      isPast: json['is_past'] == 1,
      userId: json['user_id']?.toString(),
      startEditDate: json['start_edit_date'],
      startDateJs: json['start_date_js'],
      endEditDate: json['end_edit_date'],
      url: json['url'],
    );
  }
}

