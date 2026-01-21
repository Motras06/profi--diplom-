// lib/screens/other/service_screen.dart
import 'package:flutter/material.dart';
import 'package:profi/screens/other/service_chat_screen.dart';
import 'package:profi/screens/other/order_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'specialist_profile.dart'; // импорт профиля специалиста

class ServiceScreen extends StatefulWidget {
  final Map<String, dynamic> service;

  const ServiceScreen({super.key, required this.service});

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _photos = [];
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoadingPhotos = true;
  bool _isLoadingReviews = true;
  double _averageRating = 0.0;
  int _reviewCount = 0;

  // Для текущего пользователя
  bool _hasUserReview = false;
  int? _userReviewId;
  int? _userRating;
  String? _userComment;

  int? _selectedRating;
  final TextEditingController _reviewController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPhotos();
    _loadReviewsAndUserReview();
  }

  Future<void> _loadPhotos() async {
    setState(() => _isLoadingPhotos = true);

    try {
      final serviceId = widget.service['id'] as int?;
      if (serviceId == null) throw 'Нет ID услуги';

      final response = await supabase
          .from('service_photos')
          .select('photo_url, order')
          .eq('service_id', serviceId)
          .order('order', ascending: true);

      setState(() {
        _photos = List<Map<String, dynamic>>.from(response);
        _isLoadingPhotos = false;
      });
    } catch (e) {
      setState(() => _isLoadingPhotos = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки фото: $e')),
        );
      }
    }
  }

  Future<void> _loadReviewsAndUserReview() async {
    setState(() => _isLoadingReviews = true);

    final userId = supabase.auth.currentUser?.id;
    final serviceId = widget.service['id'] as int?;

    if (serviceId == null) {
      setState(() => _isLoadingReviews = false);
      return;
    }

    try {
      // Все отзывы по услуге
      final reviewsRes = await supabase
          .from('reviews')
          .select('''
            id, rating, comment, created_at,
            profiles!user_id (display_name, photo_url)
          ''')
          .eq('service_id', serviceId)
          .order('created_at', ascending: false);

      // Отзыв текущего пользователя
      Map<String, dynamic>? userReview;
      if (userId != null) {
        final userReviewRes = await supabase
            .from('reviews')
            .select('id, rating, comment')
            .eq('service_id', serviceId)
            .eq('user_id', userId)
            .maybeSingle();

        userReview = userReviewRes;
      }

      if (reviewsRes.isNotEmpty) {
        final ratings = reviewsRes.map((r) => r['rating'] as int).toList();
        final sum = ratings.fold<int>(0, (a, b) => a + b);
        final avg = sum / ratings.length;

        setState(() {
          _reviews = List<Map<String, dynamic>>.from(reviewsRes);
          _averageRating = avg;
          _reviewCount = ratings.length;
        });
      } else {
        setState(() {
          _reviews = [];
          _averageRating = 0.0;
          _reviewCount = 0;
        });
      }

      // Данные отзыва пользователя
      if (userReview != null) {
        setState(() {
          _hasUserReview = true;
          _userReviewId = userReview?['id'] as int?;
          _userRating = userReview?['rating'] as int?;
          _userComment = userReview?['comment'] as String?;
        });
      } else {
        setState(() {
          _hasUserReview = false;
          _userReviewId = null;
          _userRating = null;
          _userComment = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки отзывов: $e')),
        );
      }
    } finally {
      setState(() => _isLoadingReviews = false);
    }
  }

  Future<void> _submitOrUpdateReview() async {
    if (_selectedRating == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Поставьте оценку')),
      );
      return;
    }

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Войдите в аккаунт')),
      );
      return;
    }

    final serviceId = widget.service['id'] as int?;
    if (serviceId == null) return;

    try {
      final comment = _reviewController.text.trim();
      final data = {
        'user_id': userId,
        'specialist_id': widget.service['profiles']?['id'],
        'service_id': serviceId,
        'rating': _selectedRating,
        if (comment.isNotEmpty) 'comment': comment,
      };

      if (_hasUserReview && _userReviewId != null) {
        await supabase.from('reviews').update(data).eq('id', _userReviewId!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Отзыв обновлён')),
        );
      } else {
        await supabase.from('reviews').insert(data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Отзыв добавлен')),
        );
      }

      Navigator.pop(context);
      _reviewController.clear();
      _selectedRating = null;
      await _loadReviewsAndUserReview();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  void _showReviewDialog() {
    // Инициализируем локальное состояние диалога
    int localRating = _hasUserReview ? (_userRating ?? 0) : 0;
    final localController = TextEditingController(text: _hasUserReview ? _userComment ?? '' : '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(_hasUserReview ? 'Редактировать отзыв' : 'Оставить отзыв'),
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
                        color: i < localRating ? Colors.amber : Colors.grey[400],
                        size: 40,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          localRating = i + 1;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: localController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Ваш отзыв (необязательно)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                _selectedRating = localRating;
                _reviewController.text = localController.text;
                await _submitOrUpdateReview();
                localController.dispose();
              },
              child: Text(_hasUserReview ? 'Сохранить изменения' : 'Отправить'),
            ),
          ],
        ),
      ),
    ).then((_) {
      // Сбрасываем состояние после закрытия
      _selectedRating = null;
      _reviewController.clear();
    });
  }

  void _openChat() {
  final specialist = widget.service['profiles'] ?? {};
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ServiceChatScreen(
        specialist: specialist,
        service: widget.service,
      ),
    ),
  );
}

void _orderService() {
  final specialist = widget.service['profiles'] ?? {};
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => OrderScreen(
        service: widget.service,
        specialist: specialist,
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final photos = _photos;
    final price = widget.service['price'] as num?;
    final description = widget.service['description'] as String?;
    final specialist = widget.service['profiles'] ?? {};
    final serviceName = widget.service['name'] as String? ?? 'Услуга';

    return Scaffold(
      appBar: AppBar(
        title: Text(serviceName),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Карусель фото
            if (_isLoadingPhotos)
              const Center(child: CircularProgressIndicator())
            else if (photos.isNotEmpty)
              SizedBox(
                height: 300,
                child: PageView.builder(
                  itemCount: photos.length,
                  itemBuilder: (context, index) {
                    final photo = photos[index]['photo_url'] as String?;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: photo != null
                            ? Image.network(
                                photo,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) =>
                                    progress == null ? child : const Center(child: CircularProgressIndicator()),
                                errorBuilder: (_, __, ___) =>
                                    const Center(child: Icon(Icons.error, color: Colors.red, size: 50)),
                              )
                            : const Center(child: Icon(Icons.image_not_supported)),
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                height: 200,
                color: Colors.grey[200],
                child: const Center(child: Text('Нет фотографий')),
              ),
            if (photos.isNotEmpty) const SizedBox(height: 16),

            // Точки-индикаторы (активная точка меняется при скролле)
            if (photos.length > 1)
              Center(
                child: ValueListenableBuilder<int>(
                  valueListenable: ValueNotifier(0), // можно улучшить с PageController
                  builder: (context, activeIndex, _) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        photos.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).primaryColor.withOpacity(index == activeIndex ? 1 : 0.4),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (photos.isNotEmpty) const SizedBox(height: 24),

            // Специалист (кликабельный)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SpecialistProfileScreen(specialist: specialist),
                  ),
                );
              },
              child: Row(
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
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                        if (specialist['specialty'] != null)
                          Text(
                            specialist['specialty'],
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Название и цена
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    serviceName,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
                if (price != null)
                  Chip(
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    label: Text(
                      '$price BYN',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  )
                else
                  const Chip(
                    label: Text('По договорённости', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  child: OutlinedButton.icon(
                    onPressed: _openChat,
                    icon: const Icon(Icons.chat),
                    label: const Text('Связаться'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _orderService,
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('Заказать'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Отзывы и рейтинг
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Отзывы', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                if (!_hasUserReview)
                  TextButton(
                    onPressed: _showReviewDialog,
                    child: const Text('Оставить отзыв'),
                  )
                else
                  TextButton(
                    onPressed: _showReviewDialog,
                    child: const Text('Редактировать отзыв'),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            if (_isLoadingReviews)
              const Center(child: CircularProgressIndicator())
            else ...[
              Row(
                children: [
                  Row(
                    children: List.generate(5, (i) {
                      final filled = i < _averageRating.round();
                      return Icon(
                        filled ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 24,
                      );
                    }),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_averageRating.toStringAsFixed(1)} ($_reviewCount)',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_reviews.isEmpty)
                const Center(child: Text('Пока нет отзывов', style: TextStyle(color: Colors.grey)))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _reviews.length,
                  itemBuilder: (context, index) {
                    final review = _reviews[index];
                    final user = review['profiles'] ?? {};
                    final rating = review['rating'] as int? ?? 0;
                    final comment = review['comment'] as String? ?? '';
                    final date = (review['created_at'] as String?)?.split('T')[0] ?? '';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  user['display_name'] ?? 'Аноним',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                Row(
                                  children: List.generate(
                                    5,
                                    (i) => Icon(
                                      Icons.star,
                                      size: 16,
                                      color: i < rating ? Colors.amber : Colors.grey[400],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (comment.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(comment),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              date,
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }
}