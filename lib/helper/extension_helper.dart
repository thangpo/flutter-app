import 'package:flutter/material.dart';



extension ContextInfo on BuildContext {

  //theme context
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;


  //scaffold context
  ScaffoldMessengerState get scaffoldMessengerState => ScaffoldMessenger.of(this);


  //media query context
  Size get size => MediaQuery.of(this).size;
  double get height => size.height;
  double get width => size.width;

}

