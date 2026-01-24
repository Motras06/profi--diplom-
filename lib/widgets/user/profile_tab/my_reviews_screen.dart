// lib/screens/other/my_reviews_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../screens/other/service_screen.dart'; // импорт экрана услуги

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _myReviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyReviews();
  }

  Future<void> _loadMyReviews() async {
    setState(() => _isLoading = true);

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Необходимо войти в аккаунт')),
        );
      }
      return;
    }

    try {
      final response = await supabase
          .from('reviews')
          .select('''
            id, rating, comment, created_at, user_id,
            services (id, name),
            profiles!specialist_id (id, display_name, photo_url)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      setState(() {
        _myReviews = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
      }
    }
  }

  Future<void> _deleteReview(int reviewId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить отзыв'),
        content: const Text('Вы уверены? Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await supabase.from('reviews').delete().eq('id', reviewId);
      setState(() {
        _myReviews.removeWhere((r) => r['id'] == reviewId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Отзыв удалён')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка удаления: $e')),
      );
    }
  }

  void _editReview(Map<String, dynamic> review) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditReviewScreen(review: review),
      ),
    ).then((updated) {
      if (updated == true) {
        _loadMyReviews(); // обновляем список
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = supabase.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои отзывы'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myReviews.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rate_review_outlined, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 24),
                      const Text(
                        'Вы ещё не оставили отзывов',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Оцените выполненную услугу и поделитесь впечатлениями',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                      const SizedBox(height: 40),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Вернуться назад'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMyReviews,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _myReviews.length,
                    itemBuilder: (context, index) {
                      final review = _myReviews[index];
                      final service = review['services'] ?? {};
                      final specialist = review['profiles'] ?? {};
                      final rating = review['rating'] as int? ?? 0;
                      final comment = review['comment'] as String? ?? '';
                      final date = (review['created_at'] as String?)?.split('T')[0] ?? '';
                      final isMyReview = review['user_id'] == currentUserId;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ServiceScreen(service: service),
                            ),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage: specialist['photo_url'] != null
                                          ? NetworkImage(specialist['photo_url'])
                                          : null,
                                      child: specialist['photo_url'] == null
                                          ? Text(
                                              (specialist['display_name'] as String?)?.substring(0, 1).toUpperCase() ?? '?',
                                              style: const TextStyle(fontSize: 16),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            service['name'] ?? 'Услуга',
                                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            specialist['display_name'] ?? 'Мастер',
                                            style: TextStyle(color: Colors.grey[700], fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isMyReview)
                                      PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            _editReview(review);
                                          } else if (value == 'delete') {
                                            _deleteReview(review['id']);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
                                          const PopupMenuItem(value: 'delete', child: Text('Удалить', style: TextStyle(color: Colors.red))),
                                        ],
                                        icon: const Icon(Icons.more_vert),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: List.generate(
                                    5,
                                    (i) => Icon(
                                      Icons.star,
                                      size: 20,
                                      color: i < rating ? Colors.amber : Colors.grey[300],
                                    ),
                                  ),
                                ),
                                if (comment.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(comment, style: const TextStyle(fontSize: 15)),
                                ],
                                const SizedBox(height: 12),
                                Text(
                                  'Оставлен: $date',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                                if (isMyReview)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      'Ваш отзыв',
                                      style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

// Отдельный экран для редактирования отзыва (можно вынести в отдельный файл позже)
class EditReviewScreen extends StatefulWidget {
  final Map<String, dynamic> review;

  const EditReviewScreen({super.key, required this.review});

  @override
  State<EditReviewScreen> createState() => _EditReviewScreenState();
}

class _EditReviewScreenState extends State<EditReviewScreen> {
  late int _rating;
  late TextEditingController _commentController;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _rating = widget.review['rating'] as int? ?? 0;
    _commentController = TextEditingController(text: widget.review['comment'] as String? ?? '');
  }

  Future<void> _save() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Поставьте оценку')),
      );
      return;
    }

    try {
      await supabase.from('reviews').update({
        'rating': _rating,
        'comment': _commentController.text.trim().isNotEmpty ? _commentController.text.trim() : null,
      }).eq('id', widget.review['id']);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Отзыв обновлён')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактировать отзыв'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Оценка:'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return IconButton(
                  icon: Icon(
                    Icons.star,
                    color: i < _rating ? Colors.amber : Colors.grey[400],
                    size: 40,
                  ),
                  onPressed: () => setState(() => _rating = i + 1),
                );
              }),
            ),
            const SizedBox(height: 24),
            const Text('Комментарий:'),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Что вам понравилось / не понравилось...',
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Сохранить изменения'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}