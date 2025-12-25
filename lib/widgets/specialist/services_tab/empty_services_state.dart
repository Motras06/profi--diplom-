// lib/widgets/services_tab/empty_services_state.dart
import 'package:flutter/material.dart';

class EmptyServicesState extends StatelessWidget {
  const EmptyServicesState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.build_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('Нет услуг', style: TextStyle(fontSize: 18)),
          SizedBox(height: 8),
          Text('Нажмите + чтобы добавить первую', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}