import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

void showToast({required String msg}) {
  Fluttertoast.cancel(); // ✅ clear existing toast
  Fluttertoast.showToast(
    msg: msg,
    toastLength: Toast.LENGTH_LONG,
    gravity: ToastGravity.BOTTOM,
    fontSize: 13,
    timeInSecForIosWeb: 2,
  );
}

void errorToast({required String? msg, int? timeInSecForIosWeb}) {
  Fluttertoast.cancel(); // ✅ clear existing toast
  Fluttertoast.showToast(
    msg: msg ?? "Something went wrong",
    toastLength: Toast.LENGTH_LONG,
    gravity: ToastGravity.BOTTOM,
    fontSize: 13,
    
    backgroundColor: Colors.red,
    timeInSecForIosWeb: timeInSecForIosWeb ?? 2,
  );
}
