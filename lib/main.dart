import 'package:flutter/material.dart';

import 'pages/mainscreen.dart';
import 'pages/todolist.dart';

void main() {
  runApp(
    MaterialApp(
      theme: ThemeData(primaryColor: Colors.brown),
      home: Mainscreen(),
    ),
  );
}
