// lib/widgets/specialist/profile_tab/reviews.dart
import 'package:flutter/material.dart';

class SpecialistReviews extends StatelessWidget {
  const SpecialistReviews({super.key});

  // Фейковые отзывы
  final List<Map<String, dynamic>> _fakeReviews = const [
    {
      'clientName': 'Иван Петров',
      'rating': 5,
      'comment': 'Отличный мастер! Всё сделал быстро и качественно. Рекомендую!',
      'date': '15 декабря 2024',
    },
    {
      'clientName': 'Анна Сидорова',
      'rating': 4,
      'comment': 'Работа хорошая, но пришлось немного подождать. В целом довольна.',
      'date': '10 декабря 2024',
    },
    {
      'clientName': 'Михаил Кузнецов',
      'rating': 5,
      'comment': 'Профессионал! Приехал вовремя, всё объяснил, результат супер.',
      'date': '5 декабря 2024',
    },
    {
      'clientName': 'Елена Васильева',
      'rating': 5,
      'comment': 'Спасибо за ремонт! Теперь ванная как новая 😍',
      'date': '1 декабря 2024',
    },
  ];

  @override
  Widget build(BuildContext context) {
    const double averageRating = 4.8;
    const int totalReviews = 23;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Отзывы'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Средняя оценка
          Container(
            padding: const EdgeInsets.all(24),
            color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  averageRating.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < averageRating.floor() ? Icons.star : (i < averageRating ? Icons.star_half : Icons.star_border),
                          color: Colors.amber,
                          size: 32,
                        );
                      }),
                    ),
                    Text(
                      'На основе $totalReviews отзывов',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Список отзывов
          Expanded(
            child: _fakeReviews.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rate_review_outlined, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text('Пока нет отзывов', style: TextStyle(fontSize: 18)),
                        const SizedBox(height: 8),
                        Text(
                          'Отзывы появятся после выполнения заказов',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _fakeReviews.length,
                    itemBuilder: (context, index) {
                      final review = _fakeReviews[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    review['clientName'],
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: List.generate(5, (i) {
                                      return Icon(
                                        Icons.star,
                                        color: i < review['rating'] ? Colors.amber : Colors.grey[300],
                                        size: 20,
                                      );
                                    }),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(review['comment']),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    review['date'],
                                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Ответ на отзыв (в разработке)')),
                                      );
                                    },
                                    child: const Text('Ответить'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}