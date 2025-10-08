class PlaceDetailsModel {
  String? name;
  String? id;
  List<String>? types;
  String? formattedAddress;
  List<AddressComponents>? addressComponents;
  Location? location;
  Viewport? viewport;
  String? googleMapsUri;
  int? utcOffsetMinutes;
  String? adrFormatAddress;
  String? iconMaskBaseUri;
  String? iconBackgroundColor;
  DisplayName? displayName;
  String? shortFormattedAddress;
  List<Photos>? photos;
  bool? pureServiceAreaBusiness;
  GoogleMapsLinks? googleMapsLinks;
  TimeZone? timeZone;

  PlaceDetailsModel(
      {this.name,
        this.id,
        this.types,
        this.formattedAddress,
        this.addressComponents,
        this.location,
        this.viewport,
        this.googleMapsUri,
        this.utcOffsetMinutes,
        this.adrFormatAddress,
        this.iconMaskBaseUri,
        this.iconBackgroundColor,
        this.displayName,
        this.shortFormattedAddress,
        this.photos,
        this.pureServiceAreaBusiness,
        this.googleMapsLinks,
        this.timeZone});

  PlaceDetailsModel.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    id = json['id'];
    types = json['types'].cast<String>();
    formattedAddress = json['formattedAddress'];
    if (json['addressComponents'] != null) {
      addressComponents = <AddressComponents>[];
      json['addressComponents'].forEach((v) {
        addressComponents!.add(AddressComponents.fromJson(v));
      });
    }
    location = json['location'] != null
        ? Location.fromJson(json['location'])
        : null;
    viewport = json['viewport'] != null
        ? Viewport.fromJson(json['viewport'])
        : null;
    googleMapsUri = json['googleMapsUri'];
    utcOffsetMinutes = json['utcOffsetMinutes'];
    adrFormatAddress = json['adrFormatAddress'];
    iconMaskBaseUri = json['iconMaskBaseUri'];
    iconBackgroundColor = json['iconBackgroundColor'];
    displayName = json['displayName'] != null
        ? DisplayName.fromJson(json['displayName'])
        : null;
    shortFormattedAddress = json['shortFormattedAddress'];
    if (json['photos'] != null) {
      photos = <Photos>[];
      json['photos'].forEach((v) {
        photos!.add(Photos.fromJson(v));
      });
    }
    pureServiceAreaBusiness = json['pureServiceAreaBusiness'];
    googleMapsLinks = json['googleMapsLinks'] != null
        ? GoogleMapsLinks.fromJson(json['googleMapsLinks'])
        : null;
    timeZone = json['timeZone'] != null
        ? TimeZone.fromJson(json['timeZone'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['id'] = id;
    data['types'] = types;
    data['formattedAddress'] = formattedAddress;
    if (addressComponents != null) {
      data['addressComponents'] =
          addressComponents!.map((v) => v.toJson()).toList();
    }
    if (location != null) {
      data['location'] = location!.toJson();
    }
    if (viewport != null) {
      data['viewport'] = viewport!.toJson();
    }
    data['googleMapsUri'] = googleMapsUri;
    data['utcOffsetMinutes'] = utcOffsetMinutes;
    data['adrFormatAddress'] = adrFormatAddress;
    data['iconMaskBaseUri'] = iconMaskBaseUri;
    data['iconBackgroundColor'] = iconBackgroundColor;
    if (displayName != null) {
      data['displayName'] = displayName!.toJson();
    }
    data['shortFormattedAddress'] = shortFormattedAddress;
    if (photos != null) {
      data['photos'] = photos!.map((v) => v.toJson()).toList();
    }
    data['pureServiceAreaBusiness'] = pureServiceAreaBusiness;
    if (googleMapsLinks != null) {
      data['googleMapsLinks'] = googleMapsLinks!.toJson();
    }
    if (timeZone != null) {
      data['timeZone'] = timeZone!.toJson();
    }
    return data;
  }
}

class AddressComponents {
  String? longText;
  String? shortText;
  List<String>? types;
  String? languageCode;

  AddressComponents(
      {this.longText, this.shortText, this.types, this.languageCode});

  AddressComponents.fromJson(Map<String, dynamic> json) {
    longText = json['longText'];
    shortText = json['shortText'];
    types = json['types'].cast<String>();
    languageCode = json['languageCode'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['longText'] = longText;
    data['shortText'] = shortText;
    data['types'] = types;
    data['languageCode'] = languageCode;
    return data;
  }
}

class Location {
  double? latitude;
  double? longitude;

  Location({this.latitude, this.longitude});

  Location.fromJson(Map<String, dynamic> json) {
    latitude = json['latitude'];
    longitude = json['longitude'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    return data;
  }
}

class Viewport {
  Location? low;
  Location? high;

  Viewport({this.low, this.high});

  Viewport.fromJson(Map<String, dynamic> json) {
    low = json['low'] != null ? Location.fromJson(json['low']) : null;
    high = json['high'] != null ? Location.fromJson(json['high']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (low != null) {
      data['low'] = low!.toJson();
    }
    if (high != null) {
      data['high'] = high!.toJson();
    }
    return data;
  }
}

class DisplayName {
  String? text;
  String? languageCode;

  DisplayName({this.text, this.languageCode});

  DisplayName.fromJson(Map<String, dynamic> json) {
    text = json['text'];
    languageCode = json['languageCode'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['text'] = text;
    data['languageCode'] = languageCode;
    return data;
  }
}

class Photos {
  String? name;
  int? widthPx;
  int? heightPx;
  List<AuthorAttributions>? authorAttributions;
  String? flagContentUri;
  String? googleMapsUri;

  Photos(
      {this.name,
        this.widthPx,
        this.heightPx,
        this.authorAttributions,
        this.flagContentUri,
        this.googleMapsUri});

  Photos.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    widthPx = json['widthPx'];
    heightPx = json['heightPx'];
    if (json['authorAttributions'] != null) {
      authorAttributions = <AuthorAttributions>[];
      json['authorAttributions'].forEach((v) {
        authorAttributions!.add(AuthorAttributions.fromJson(v));
      });
    }
    flagContentUri = json['flagContentUri'];
    googleMapsUri = json['googleMapsUri'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['widthPx'] = widthPx;
    data['heightPx'] = heightPx;
    if (authorAttributions != null) {
      data['authorAttributions'] =
          authorAttributions!.map((v) => v.toJson()).toList();
    }
    data['flagContentUri'] = flagContentUri;
    data['googleMapsUri'] = googleMapsUri;
    return data;
  }
}

class AuthorAttributions {
  String? displayName;
  String? uri;
  String? photoUri;

  AuthorAttributions({this.displayName, this.uri, this.photoUri});

  AuthorAttributions.fromJson(Map<String, dynamic> json) {
    displayName = json['displayName'];
    uri = json['uri'];
    photoUri = json['photoUri'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['displayName'] = displayName;
    data['uri'] = uri;
    data['photoUri'] = photoUri;
    return data;
  }
}

class GoogleMapsLinks {
  String? directionsUri;
  String? placeUri;
  String? photosUri;

  GoogleMapsLinks({this.directionsUri, this.placeUri, this.photosUri});

  GoogleMapsLinks.fromJson(Map<String, dynamic> json) {
    directionsUri = json['directionsUri'];
    placeUri = json['placeUri'];
    photosUri = json['photosUri'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['directionsUri'] = directionsUri;
    data['placeUri'] = placeUri;
    data['photosUri'] = photosUri;
    return data;
  }
}

class TimeZone {
  String? id;

  TimeZone({this.id});

  TimeZone.fromJson(Map<String, dynamic> json) {
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    return data;
  }
}
