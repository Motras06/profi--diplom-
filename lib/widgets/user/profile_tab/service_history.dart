// lib/widgets/user/profile_tab/service_history.dart
import 'package:flutter/material.dart';

class ServiceHistory extends StatelessWidget {
  ServiceHistory({super.key});

  // Затычки — фейковые заказы
  final List<Map<String, dynamic>> _fakeOrders = [
    {
      'serviceName': 'Ремонт ванной комнаты',
      'specialistName': 'Алексей Иванов',
      'price': 25000,
      'status': 'Выполнен',
      'date': '15 декабря 2024',
      'rating': 5,
    },
    {
      'serviceName': 'Замена электропроводки',
      'specialistName': 'Дмитрий Петров',
      'price': 18000,
      'status': 'Выполнен',
      'date': '5 декабря 2024',
      'rating': 4,
    },
    {
      'serviceName': 'Установка кондиционера',
      'specialistName': 'Сергей Морозов',
      'price': 15000,
      'status': 'В процессе',
      'date': '20 декабря 2024',
      'rating': null,
    },
    {
      'serviceName': 'Покраска стен',
      'specialistName': 'Ольга Кузнецова',
      'price': 12000,
      'status': 'Отменён',
      'date': '10 ноября 2024',
      'rating': null,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История заказов'),
        centerTitle: true,
      ),
      body: _fakeOrders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('Нет заказов', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(
                    'Когда вы закажете услуги — они появятся здесь',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _fakeOrders.length,
              itemBuilder: (context, index) {
                final order = _fakeOrders[index];

                Color statusColor;
                switch (order['status']) {
                  case 'Выполнен':
                    statusColor = Colors.green;
                    break;
                  case 'В процессе':
                    statusColor = Colors.orange;
                    break;
                  case 'Отменён':
                    statusColor = Colors.red;
                    break;
                  default:
                    statusColor = Colors.grey;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              order['serviceName'],
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Chip(
                              label: Text(
                                order['status'],
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                              backgroundColor: statusColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Мастер: ${order['specialistName']}'),
                        const SizedBox(height: 4),
                        Text('Дата: ${order['date']}'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              '${order['price']} ₽',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            if (order['rating'] != null)
                              Row(
                                children: List.generate(5, (i) {
                                  return Icon(
                                    i < order['rating'] ? Icons.star : Icons.star_border,
                                    color: Colors.amber,
                                    size: 20,
                                  );
                                }),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}