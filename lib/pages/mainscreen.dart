import 'package:flutter/material.dart';

import 'todolist.dart';

class Mainscreen extends StatefulWidget {
  const Mainscreen({super.key});

  @override
  State<Mainscreen> createState() => _MainscreenState();
}

class _MainscreenState extends State<Mainscreen> {
  List<String> todoList = ['123'];

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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Todolist(
                        todolist: todoList,
                        onTodoListChanged: onTodoListChanged,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(padding: EdgeInsets.all(16.0)),
                child: Text('Open todolist'),
              ),
            ],
          ),
        ],
      ),
    );
  }


  void onTodoListChanged(List<String> todoList){
    setState((){
      this.todoList = todoList;
    });
  }
}
