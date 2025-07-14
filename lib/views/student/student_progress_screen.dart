import 'package:flutter/material.dart';

class StudentProgressScreen extends StatelessWidget {
  final String studentName;

  const StudentProgressScreen({super.key, required this.studentName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$studentName\'s Progress')),
      body: Center(
        child: Text('Progress details for $studentName'),
      ),
    );
  }
}
