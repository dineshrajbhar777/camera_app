import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

void showToastMsg({Color color, @required String msg}) {
  Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: color == null ? Colors.grey : color,
      textColor: Colors.white
  );
}