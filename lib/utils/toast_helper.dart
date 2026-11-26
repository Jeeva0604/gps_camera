import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Centralized Toast Helper using fluttertoast instead of SnackBar
class ToastHelper {
  /// Base toast display method
  static void show(
    String message, {
    Toast toastLength = Toast.LENGTH_SHORT,
    ToastGravity gravity = ToastGravity.BOTTOM,
    Color backgroundColor = const Color(0xE81E242C),
    Color textColor = Colors.white,
    double fontSize = 13.5,
  }) {
    if (message.isEmpty) return;
    Fluttertoast.cancel();
    Fluttertoast.showToast(
      msg: message,
    );
  }
}
