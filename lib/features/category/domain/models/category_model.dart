import 'package:flutter_sixvalley_ecommerce/data/model/image_full_url.dart';

class CategoryModel {
  int? _id;
  String? _name;
  String? _slug;
  String? _icon;
  int? _parentId;
  int? _position;
  String? _createdAt;
  String? _updatedAt;
  List<SubCategory>? _subCategories;
  bool? isSelected;
  ImageFullUrl? _imageFullUrl;
  int? _totalProductCount;

  CategoryModel(
      {int? id,
        String? name,
        String? slug,
        String? icon,
        int? parentId,
        int? position,
        String? createdAt,
        String? updatedAt,
        List<SubCategory>? subCategories,
        bool? isSelected,
        ImageFullUrl? imageFullUrl,
        int? totalProductCount
      }) {
    _id = id;
    _name = name;
    _slug = slug;
    _icon = icon;
    _parentId = parentId;
    _position = position;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
    _subCategories = subCategories;
    isSelected = isSelected;
    _imageFullUrl = imageFullUrl;
    _totalProductCount = totalProductCount;
  }

  int? get id => _id;
  String? get name => _name;
  String? get slug => _slug;
  String? get icon => _icon;
  int? get parentId => _parentId;
  int? get position => _position;
  String? get createdAt => _createdAt;
  String? get updatedAt => _updatedAt;
  List<SubCategory>? get subCategories => _subCategories;
  ImageFullUrl? get imageFullUrl => _imageFullUrl;
  int? get totalProductCount => _totalProductCount;

  CategoryModel.fromJson(Map<String, dynamic> json) {
    _id = json['id'];
    _name = json['name'];
    _slug = json['slug'];
    _icon = json['icon'];
    _parentId = json['parent_id'];
    _position = json['position'];
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
    if (json['childes'] != null) {
      _subCategories = [];
      json['childes'].forEach((v) {
        _subCategories!.add(SubCategory.fromJson(v));
      });
    }
    _imageFullUrl = json['icon_full_url'] != null
        ? ImageFullUrl.fromJson(json['icon_full_url'])
        : null;
    isSelected = false;


    _totalProductCount = json['product_count'];
  }
}

class SubCategory {
  int? _id;
  String? _name;
  String? _slug;
  String? _icon;
  int? _parentId;
  int? _position;
  String? _createdAt;
  String? _updatedAt;
  List<SubSubCategory>? _subSubCategories;
  bool? isSelected;
  int? _totalProductCount;

  SubCategory(
      {int? id,
        String? name,
        String? slug,
        String? icon,
        int? parentId,
        int? position,
        String? createdAt,
        String? updatedAt,
        List<SubSubCategory>? subSubCategories,
        bool? isSelected,
        int? totalProductCount
      }) {
    _id = id;
    _name = name;
    _slug = slug;
    _icon = icon;
    _parentId = parentId;
    _position = position;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
    _subSubCategories = subSubCategories;
    isSelected = isSelected;
    _totalProductCount = totalProductCount;
  }

  int? get id => _id;
  String? get name => _name;
  String? get slug => _slug;
  String? get icon => _icon;
  int? get parentId => _parentId;
  int? get position => _position;
  String? get createdAt => _createdAt;
  String? get updatedAt => _updatedAt;
  List<SubSubCategory>? get subSubCategories => _subSubCategories;
  int? get totalProductCount => _totalProductCount;

  SubCategory.fromJson(Map<String, dynamic> json) {
    _id = json['id'];
    _name = json['name'];
    _slug = json['slug'];
    _icon = json['icon'];
    _parentId = json['parent_id'];
    _position = json['position'];
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
    if (json['childes'] != null) {
      _subSubCategories = [];
      json['childes'].forEach((v) {
        _subSubCategories!.add(SubSubCategory.fromJson(v));
      });
    }
    isSelected = false;

    _totalProductCount = json['sub_category_product_count'];
  }

}

class SubSubCategory {
  int? _id;
  String? _name;
  String? _slug;
  String? _icon;
  int? _parentId;
  int? _position;
  String? _createdAt;
  String? _updatedAt;
  int? _totalProductCount;

  SubSubCategory(
      {int? id,
        String? name,
        String? slug,
        String? icon,
        int? parentId,
        int? position,
        String? createdAt,
        String? updatedAt,
        int? totalProductCount
      }) {
    _id = id;
    _name = name;
    _slug = slug;
    _icon = icon;
    _parentId = parentId;
    _position = position;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
    _totalProductCount = totalProductCount;
  }

  int? get id => _id;
  String? get name => _name;
  String? get slug => _slug;
  String? get icon => _icon;
  int? get parentId => _parentId;
  int? get position => _position;
  String? get createdAt => _createdAt;
  String? get updatedAt => _updatedAt;
  int? get totalProductCount => _totalProductCount;

  SubSubCategory.fromJson(Map<String, dynamic> json) {
    _id = json['id'];
    _name = json['name'];
    _slug = json['slug'];
    _icon = json['icon'];
    _parentId = json['parent_id'];
    _position = json['position'];
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];

    _totalProductCount = json['sub_sub_category_product_count'];
  }

}
