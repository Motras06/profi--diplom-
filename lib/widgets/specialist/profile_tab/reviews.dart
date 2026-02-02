import 'package:flutter/material.dart';
import '../../../services/supabase_service.dart';

class SpecialistReviews extends StatefulWidget {
  const SpecialistReviews({super.key});

  @override
  State<SpecialistReviews> createState() => _SpecialistReviewsState();
}

class _SpecialistReviewsState extends State<SpecialistReviews> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _reviews = [];
  double _averageRating = 0.0;
  int _totalReviews = 0;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Пользователь не авторизован');
      }

      final response = await supabase
          .from('reviews')
          .select('''
            id,
            rating,
            comment,
            created_at,
            service:services!reviews_service_id_fkey (name),
            user:profiles!reviews_user_id_fkey (display_name)
          ''')
          .eq('specialist_id', currentUser.id)
          .order('created_at', ascending: false);

      final total = response.length;
      final sumRating = response.fold<double>(
        0.0,
        (sum, r) => sum + (r['rating'] as int? ?? 0),
      );

      setState(() {
        _reviews = List<Map<String, dynamic>>.from(response);
        _totalReviews = total;
        _averageRating = total > 0 ? sumRating / total : 0.0;
      });
    } catch (e, stack) {
      debugPrint('Ошибка загрузки отзывов: $e\n$stack');
      if (mounted) {
        String errorMsg = 'Не удалось загрузить отзывы';
        if (e.toString().contains('relation "reviews" does not exist')) {
          errorMsg = 'Таблица reviews не найдена в базе данных';
        } else if (e.toString().contains('JWT expired') ||
            e.toString().contains('auth')) {
          errorMsg =
              'Проблема с авторизацией — попробуйте выйти и войти заново';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays < 1) {
      if (diff.inHours < 1) return 'только что';
      return '${diff.inHours} ${diff.inHours == 1 ? "час" : "часа"} назад';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} ${diff.inDays == 1 ? "день" : "дня"} назад';
    }

    final months = [
      'янв',
      'фев',
      'мар',
      'апр',
      'май',
      'июн',
      'июл',
      'авг',
      'сен',
      'окт',
      'ноя',
      'дек',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildStars(num rating) {
    final floor = rating.floor();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < floor)
          return const Icon(Icons.star, color: Colors.amber, size: 20);
        if (i < rating)
          return const Icon(Icons.star_half, color: Colors.amber, size: 20);
        return const Icon(Icons.star_border, color: Colors.grey, size: 20);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Отзывы'), centerTitle: true),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
            color: colorScheme.primary.withOpacity(0.04),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStars(_averageRating),
                    const SizedBox(height: 6),
                    Text(
                      _totalReviews == 0
                          ? 'Пока нет оценок'
                          : 'На основе $_totalReviews ${_totalReviews == 1 ? "отзыва" : "отзывов"}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 15),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _reviews.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.rate_review_outlined,
                          size: 88,
                          color: Colors.grey[350],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Пока нет отзывов',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Отзывы появятся после завершения заказов',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadReviews,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: _reviews.length,
                      itemBuilder: (context, index) {
                        final review = _reviews[index];
                        final clientName =
                            review['user']?['display_name'] as String? ??
                            'Клиент';
                        final serviceName =
                            review['service']?['name'] as String? ??
                            'Услуга не указана';
                        final rating = review['rating'] as int? ?? 0;
                        final comment = review['comment'] as String? ?? '';
                        final createdAt =
                            DateTime.tryParse(
                              review['created_at'] as String? ?? '',
                            ) ??
                            DateTime.now();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        clientName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    _buildStars(rating),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  serviceName,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 13,
                                  ),
                                ),
                                if (comment.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    comment,
                                    style: const TextStyle(height: 1.4),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Text(
                                  _formatDate(createdAt),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
