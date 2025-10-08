import 'package:flutter_sixvalley_ecommerce/helper/date_converter.dart';

class LoyaltyPointModel {
  int? limit;
  int? offset;
  int? totalSize;
  String? filterBy;
  DateTime? startDate;
  DateTime? endDate;
  List<String>? transactionTypes;
  int? totalLoyaltyPoint;
  List<LoyaltyPointList>? loyaltyPointList;


  LoyaltyPointModel.fromJson(Map<String, dynamic> json) {
    limit = int.tryParse('${json['limit']}');
    offset = int.tryParse('${json['offset']}');
    totalSize = int.tryParse('${json['total_size']}');
    filterBy = json['filter_by'];
    startDate = DateConverter.convertDurationDateTimeFromString(json['start_date']);
    endDate = DateConverter.convertDurationDateTimeFromString(json['end_date']);

    if (json['transaction_types'] != null) {
      transactionTypes = List<String>.from(json['transaction_types'].map((id) => id.toString()));
    }

    if(json['total_loyalty_point'] != null) {
      totalLoyaltyPoint = json['total_loyalty_point'].toInt();
    }
    if (json['loyalty_point_list'] != null) {
      loyaltyPointList = <LoyaltyPointList>[];
      json['loyalty_point_list'].forEach((v) {
        loyaltyPointList!.add(LoyaltyPointList.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['limit'] = limit;
    data['offset'] = offset;
    data['total_loyalty_point'] = totalLoyaltyPoint;
    if (loyaltyPointList != null) {
      data['loyalty_point_list'] =
          loyaltyPointList!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class LoyaltyPointList {
  int? _id;
  int? _userId;
  String? _transactionId;
  int? _credit;
  int? _debit;
  double? _balance;
  String? _reference;
  String? _transactionType;
  String? _createdAt;
  String? _updatedAt;

  LoyaltyPointList(
      {int? id,
        int? userId,
        String? transactionId,
        int? credit,
        int? debit,
        double? balance,
        String? reference,
        String? transactionType,
        String? createdAt,
        String? updatedAt}) {
    if (id != null) {
      _id = id;
    }
    if (userId != null) {
      _userId = userId;
    }
    if (transactionId != null) {
      _transactionId = transactionId;
    }
    if (credit != null) {
      _credit = credit;
    }
    if (debit != null) {
      _debit = debit;
    }
    if (balance != null) {
      _balance = balance;
    }
    if (reference != null) {
      _reference = reference;
    }
    if (transactionType != null) {
      _transactionType = transactionType;
    }
    if (createdAt != null) {
      _createdAt = createdAt;
    }
    if (updatedAt != null) {
      _updatedAt = updatedAt;
    }
  }

  int? get id => _id;
  int? get userId => _userId;
  String? get transactionId => _transactionId;
  int? get credit => _credit;
  int? get debit => _debit;
  double? get balance => _balance;
  String? get reference => _reference;
  String? get transactionType => _transactionType;
  String? get createdAt => _createdAt;
  String? get updatedAt => _updatedAt;


  LoyaltyPointList.fromJson(Map<String, dynamic> json) {
    _id = json['id'];
    _userId = json['user_id'];
    _transactionId = json['transaction_id'];
    _credit = json['credit'];
    _debit = json['debit'];
    _balance = json['balance'].toDouble();
    _reference = json['reference'];
    _transactionType = json['transaction_type'];
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = _id;
    data['user_id'] = _userId;
    data['transaction_id'] = _transactionId;
    data['credit'] = _credit;
    data['debit'] = _debit;
    data['balance'] = _balance;
    data['reference'] = _reference;
    data['transaction_type'] = _transactionType;
    data['created_at'] = _createdAt;
    data['updated_at'] = _updatedAt;
    return data;
  }
}
