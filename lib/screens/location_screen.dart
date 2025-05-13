import 'package:flutter/material.dart';

class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('انتخاب لوکیشن'),
      ),
      body: const Center(
        child: Text('صفحه انتخاب لوکیشن (به زودی)'),
      ),
    );
  }
}
