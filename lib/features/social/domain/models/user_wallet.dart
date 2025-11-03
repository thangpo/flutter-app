import 'package:intl/intl.dart';

class UserWallet {
  final double balance;
  final String currency;

  UserWallet({required this.balance, this.currency = 'VND'});

  factory UserWallet.fromJson(Map<String, dynamic> json) {
    return UserWallet(
      balance: double.tryParse(json['wallet'].toString()) ?? 0.0,
      currency: 'VND',
    );
  }

  String get formattedBalance {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: balance % 1 == 0 ? 0 : 2,
    );
    return formatter.format(balance);
  }
}