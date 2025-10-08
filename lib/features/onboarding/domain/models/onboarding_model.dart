class OnboardingModel {
  final String _imageUrl;
  final String? _title;
  final String? _description;

  String get imageUrl => _imageUrl;
  String? get title => _title;
  String? get description => _description;

  OnboardingModel(this._imageUrl, this._title, this._description);
}
