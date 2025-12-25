// lib/screens/other/service_screen.dart
import 'package:flutter/material.dart';

class ServiceScreen extends StatefulWidget {
  final Map<String, dynamic> service;

  const ServiceScreen({super.key, required this.service});

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  int? _selectedRating; // Выбранная оценка пользователем
  final TextEditingController _reviewController = TextEditingController();

  // Фейковые отзывы
  final List<Map<String, dynamic>> _fakeReviews = [
    {
      'userName': 'Иван Петров',
      'rating': 5,
      'comment': 'Отличная работа! Всё сделано быстро и качественно. Рекомендую!',
      'date': '15 декабря',
    },
    {
      'userName': 'Анна Сидорова',
      'rating': 4,
      'comment': 'Мастер пришёл вовремя, работа хорошая, но немного дороже, чем ожидала.',
      'date': '10 декабря',
    },
    {
      'userName': 'Михаил Кузнецов',
      'rating': 5,
      'comment': 'Профессионал своего дела. Всё идеально!',
      'date': '5 декабря',
    },
  ];

  void _openChat() {
    final specialist = widget.service['profiles'] ?? {};
    final name = specialist['display_name'] ?? 'Мастер';
    final initial = (specialist['display_name'] as String?)?.substring(0, 1).toUpperCase() ?? 'М';

    // Здесь в будущем будет реальный чат
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Открытие чата с $name (в разработке)')),
    );
  }

  void _orderService() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Создание заказа (в разработке)')),
    );
  }

  void _submitReview() {
    if (_selectedRating == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, поставьте оценку')),
      );
      return;
    }

    // Затычка — просто показываем снекбар
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Спасибо за отзыв! Оценка: $_selectedRating ⭐')),
    );

    // Закрываем диалог и сбрасываем
    Navigator.of(context).pop();
    setState(() {
      _selectedRating = null;
      _reviewController.clear();
    });
  }

  void _showReviewDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Оставить отзыв'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ваша оценка:'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return IconButton(
                    icon: Icon(
                      Icons.star,
                      color: i < (_selectedRating ?? 0) ? Colors.amber : Colors.grey[400],
                      size: 36,
                    ),
                    onPressed: () {
                      setState(() => _selectedRating = i + 1);
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _reviewController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Напишите ваш отзыв (необязательно)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(onPressed: _submitReview, child: const Text('Отправить')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.service['photos'] as List<String>? ?? [];
    final price = widget.service['price'] as num?;
    final description = widget.service['description'] as String?;
    final specialist = widget.service['profiles'] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.service['name']),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Фото услуги
            if (photos.isNotEmpty)
              SizedBox(
                height: 300,
                child: PageView.builder(
                  itemCount: photos.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          photos[index],
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) =>
                              progress == null ? child : const Center(child: CircularProgressIndicator()),
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(child: Icon(Icons.error, color: Colors.red, size: 50)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (photos.isNotEmpty) const SizedBox(height: 16),

            // Мастер
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: specialist['photo_url'] != null
                      ? NetworkImage(specialist['photo_url'])
                      : null,
                  child: specialist['photo_url'] == null
                      ? Text(
                          (specialist['display_name'] as String?)?.substring(0, 1).toUpperCase() ?? 'М',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        specialist['display_name'] ?? 'Мастер',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      if (specialist['specialty'] != null)
                        Text(
                          specialist['specialty'],
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Название и цена
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.service['name'],
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
                if (price != null)
                  Chip(
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    label: Text(
                      '$price ₽',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  )
                else
                  const Chip(
                    label: Text(
                      'По договорённости',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Описание
            const Text('Описание', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              description?.isNotEmpty == true ? description! : 'Описание отсутствует',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),

            // Кнопки действий
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openChat,
                    icon: const Icon(Icons.chat),
                    label: const Text('Связаться с мастером'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _orderService,
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('Заказать услугу'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Оценка услуги
            const Text('Оцените услугу', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return IconButton(
                  icon: Icon(
                    Icons.star,
                    size: 40,
                    color: i < 4 ? Colors.amber : Colors.grey[400],
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Оценка услуги (в разработке)')),
                    );
                  },
                );
              }),
            ),
            const SizedBox(height: 8),
            Center(child: Text('Средняя оценка: 4.7 (23 отзыва)', style: TextStyle(color: Colors.grey[700]))),
            const SizedBox(height: 32),

            // Отзывы
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Отзывы', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                TextButton(
                  onPressed: _showReviewDialog,
                  child: const Text('Оставить отзыв'),
                ),
              ],
            ),
            const Divider(),
            if (_fakeReviews.isEmpty)
              const Center(child: Text('Пока нет отзывов', style: TextStyle(color: Colors.grey)))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _fakeReviews.length,
                itemBuilder: (context, index) {
                  final review = _fakeReviews[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(review['userName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              const Spacer(),
                              Row(
                                children: List.generate(5, (i) => Icon(Icons.star, size: 16, color: i < review['rating'] ? Colors.amber : Colors.grey[400])),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(review['comment']),
                          const SizedBox(height: 8),
                          Text(review['date'], style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 32),
            if (photos.length > 1)
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    photos.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).primaryColor.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}