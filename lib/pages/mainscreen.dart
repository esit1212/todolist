import 'package:flutter/material.dart';

class Mainscreen extends StatelessWidget {
  const Mainscreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Screen', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.brown,
      ),
      body: Column(
        children: [
          Padding(padding: EdgeInsets.only(top: 16.0)),
          Row(
            children: [
              Padding(padding: EdgeInsets.only(left: 16.0)),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/todolist');
                },
                child: Text('Open todolist'),
                style: ElevatedButton.styleFrom(padding: EdgeInsets.all(16.0)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
