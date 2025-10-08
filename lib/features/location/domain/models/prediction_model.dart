class PredictionListModel {
  List<Suggestions>? suggestions;

  PredictionListModel({this.suggestions});

  PredictionListModel.fromJson(Map<String, dynamic> json) {
    if (json['suggestions'] != null) {
      suggestions = <Suggestions>[];
      json['suggestions'].forEach((v) {
        suggestions!.add(Suggestions.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (suggestions != null) {
      data['suggestions'] = suggestions!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Suggestions {
  PlacePrediction? placePrediction;

  Suggestions({this.placePrediction});

  Suggestions.fromJson(Map<String, dynamic> json) {
    placePrediction = json['placePrediction'] != null
        ? PlacePrediction.fromJson(json['placePrediction'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (placePrediction != null) {
      data['placePrediction'] = placePrediction!.toJson();
    }
    return data;
  }
}

class PlacePrediction {
  String? place;
  String? placeId;
  Text? text;
  StructuredFormat? structuredFormat;
  List<String>? types;

  PlacePrediction(
      {this.place, this.placeId, this.text, this.structuredFormat, this.types});

  PlacePrediction.fromJson(Map<String, dynamic> json) {
    place = json['place'];
    placeId = json['placeId'];
    text = json['text'] != null ? Text.fromJson(json['text']) : null;
    structuredFormat = json['structuredFormat'] != null
        ? StructuredFormat.fromJson(json['structuredFormat'])
        : null;
    types = json['types'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['place'] = place;
    data['placeId'] = placeId;
    if (text != null) {
      data['text'] = text!.toJson();
    }
    if (structuredFormat != null) {
      data['structuredFormat'] = structuredFormat!.toJson();
    }
    data['types'] = types;
    return data;
  }
}

class Text {
  String? text;
  List<Matches>? matches;

  Text({this.text, this.matches});

  Text.fromJson(Map<String, dynamic> json) {
    text = json['text'];
    if (json['matches'] != null) {
      matches = <Matches>[];
      json['matches'].forEach((v) {
        matches!.add(Matches.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['text'] = text;
    if (matches != null) {
      data['matches'] = matches!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Matches {
  int? endOffset;

  Matches({this.endOffset});

  Matches.fromJson(Map<String, dynamic> json) {
    endOffset = json['endOffset'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['endOffset'] = endOffset;
    return data;
  }
}

class StructuredFormat {
  Text? mainText;
  SecondaryText? secondaryText;

  StructuredFormat({this.mainText, this.secondaryText});

  StructuredFormat.fromJson(Map<String, dynamic> json) {
    mainText =
    json['mainText'] != null ? Text.fromJson(json['mainText']) : null;
    secondaryText = json['secondaryText'] != null
        ? SecondaryText.fromJson(json['secondaryText'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (mainText != null) {
      data['mainText'] = mainText!.toJson();
    }
    if (secondaryText != null) {
      data['secondaryText'] = secondaryText!.toJson();
    }
    return data;
  }
}

class SecondaryText {
  String? text;

  SecondaryText({this.text});

  SecondaryText.fromJson(Map<String, dynamic> json) {
    text = json['text'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['text'] = text;
    return data;
  }
}
