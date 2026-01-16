import 'package:flutter/material.dart';
import 'package:testverst4/pages/mainscreen.dart';
import 'package:testverst4/pages/todolist.dart';


void main() {
  runApp(MaterialApp(
    theme: ThemeData(primaryColor: Colors.brown),
    initialRoute: '/',
    routes: {
      '/': (context) => const Mainscreen(),
      '/todolist': (context) => const Todolist(),
    },
  ));
}

