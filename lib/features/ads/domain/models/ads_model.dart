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
  });

  factory AdsModel.fromJson(Map<String, dynamic> json) {
    return AdsModel(
      id: json['id'],
      name: json['name'],
      website: json['url'],
      headline: json['headline'],
      description: json['description'],
      mediaUrl: json['media'],
      bidding: json['bidding'],
      appears: json['appears'],
      gender: json['gender'],
      location: json['location'],
      start: json['start'],
      end: json['end'],
      page: json['page'],
      budget: json['budget'],
      views: json['views'],
      clicks: json['clicks'],
    );
  }
}
