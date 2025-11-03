import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';

class WithdrawScreen extends StatelessWidget {
  const WithdrawScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(getTranslated('withdraw', context) ?? 'Rút tiền'),
      ),
      body: const Center(child: Text('Màn hình Rút tiền', style: TextStyle(fontSize: 20))),
    );
  }
}