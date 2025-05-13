import 'package:flutter/material.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نشان‌شده‌ها'),
      ),
      body: const Center(
        child: Text('صفحه نشان‌شده‌ها (به زودی)'),
      ),
    );
  }
}
