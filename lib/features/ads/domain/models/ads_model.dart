class AdsModel {
  int? id;
  String? name;
  String? website;
  String? headline;
  String? description;
  String? mediaUrl;
  String? bidding;
  String? appears;
  String? gender;
  String? location;
  String? start;
  String? end;
  String? page;
  int? budget;
  int? views;
  int? clicks;
  String? userId;
  String? userName;
  String? userAvatar;

  AdsModel({
    this.id,
    this.name,
    this.website,
    this.headline,
    this.description,
    this.mediaUrl,
    this.bidding,
    this.appears,
    this.gender,
    this.location,
    this.start,
    this.end,
    this.page,
    this.budget,
    this.views,
    this.clicks,
    this.userId,
    this.userName,
    this.userAvatar,
  });

  factory AdsModel.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String && value.trim().isEmpty) return null;
      return int.tryParse(value.toString());
    }

    String? pickWebsite() {
      final dynamic website = json['website'];
      if (website is String && website.isNotEmpty) {
        return website;
      }
      final dynamic url = json['url'];
      if (url is String && url.isNotEmpty) {
        return url;
      }
      return null;
    }

    String? pickMedia() {
      final dynamic media =
          json['ad_media'] ?? json['media'] ?? json['adMedia'] ?? json['ad'];
      if (media == null) return null;
      final mediaStr = media.toString().trim();
      return mediaStr.isEmpty ? null : mediaStr;
    }

    Map<String, dynamic>? userData;
    if (json['user_data'] is Map<String, dynamic>) {
      userData = Map<String, dynamic>.from(json['user_data']);
    }

    return AdsModel(
      id: parseInt(json['id']),
      name: json['name']?.toString(),
      website: pickWebsite(),
      headline: json['headline']?.toString(),
      description: json['description']?.toString(),
      mediaUrl: pickMedia(),
      bidding: json['bidding']?.toString(),
      appears: json['appears']?.toString(),
      gender: json['gender']?.toString(),
      location: json['location']?.toString(),
      start: json['start']?.toString(),
      end: json['end']?.toString(),
      page: json['page']?.toString(),
      budget: parseInt(json['budget']),
      views: parseInt(json['views']),
      clicks: parseInt(json['clicks']),
      userId: (userData?['user_id'] ?? json['user_id'])?.toString(),
      userName: (userData?['name'] ?? userData?['username'] ?? json['username'])
          ?.toString(),
      userAvatar: userData?['avatar']?.toString(),
    );
  }
}
