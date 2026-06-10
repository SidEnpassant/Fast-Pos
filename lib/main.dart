import 'package:flutter/material.dart';
import 'package:inventopos/app/bootstrap.dart';
import 'package:inventopos/app/fast_pos_app.dart';

Future<void> main() async {
  await initializeApp();
  runApp(fastPosRoot());

}
