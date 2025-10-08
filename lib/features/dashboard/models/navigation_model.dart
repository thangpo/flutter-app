import 'package:flutter/material.dart';

class NavigationModel {
  String name;
  String icon;
  Widget screen;
  bool? showCartIcon;
  NavigationModel({required this.name, required this.icon,  required this.screen, this.showCartIcon = false});
}

