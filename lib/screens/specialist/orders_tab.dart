// lib/screens/specialist/orders_tab.dart
import 'package:flutter/material.dart';

class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment, size: 80, color: Theme.of(context).primaryColor),
            const SizedBox(height: 24),
            const Text(
              'Заказы',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Здесь будет:\n• Список новых заявок на верификацию\n• Одобрение/отклонение заказов\n• Чёрный список клиентов\n• История выполненных заказов',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('3 новых заявки на верификацию'),
            ),
          ],
        ),
      ),
    );
  }
}