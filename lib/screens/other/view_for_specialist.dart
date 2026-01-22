// lib/screens/specialist/specialist_service_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SpecialistServiceScreen extends StatefulWidget {
  final Map<String, dynamic> service;

  const SpecialistServiceScreen({super.key, required this.service});

  @override
  State<SpecialistServiceScreen> createState() => _SpecialistServiceScreenState();
}

class _SpecialistServiceScreenState extends State<SpecialistServiceScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _photos = [];
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoadingPhotos = true;
  bool _isLoadingReviews = true;
  double _averageRating = 0.0;
  int _reviewCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
    _loadReviews();
  }

  Future<void> _loadPhotos() async {
    setState(() => _isLoadingPhotos = true);

    try {
      final serviceId = widget.service['id'] as int?;
      if (serviceId == null) throw 'Нет ID услуги';

      final response = await supabase
          .from('service_photos')
          .select('photo_url, "order"')
          .eq('service_id', serviceId)
          .order('"order"', ascending: true);

      if (mounted) {
        setState(() {
          _photos = List<Map<String, dynamic>>.from(response);
          _isLoadingPhotos = false;
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки фото: $e');
      if (mounted) {
        setState(() => _isLoadingPhotos = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки фото: $e')),
        );
      }
    }
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoadingReviews = true);

    final serviceId = widget.service['id'] as int?;

    if (serviceId == null) {
      if (mounted) setState(() => _isLoadingReviews = false);
      return;
    }

    try {
      final reviewsRes = await supabase
          .from('reviews')
          .select('''
            id, rating, comment, created_at,
            profiles!user_id (display_name, photo_url)
          ''')
          .eq('service_id', serviceId)
          .order('created_at', ascending: false);

      double avg = 0.0;
      int count = 0;

      if (reviewsRes.isNotEmpty) {
        final ratings = reviewsRes.map((r) => r['rating'] as int? ?? 0).toList();
        count = ratings.length;
        if (count > 0) {
          final sum = ratings.fold<int>(0, (a, b) => a + b);
          avg = sum / count;
        }
      }

      if (mounted) {
        setState(() {
          _reviews = List<Map<String, dynamic>>.from(reviewsRes);
          _averageRating = avg;
          _reviewCount = count;
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки отзывов: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки отзывов: $e')),
        );
      }
      if (mounted) setState(() => _isLoadingReviews = false);
    }
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

            // Точки-индикаторы
            if (photos.length > 1)
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    photos.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).primaryColor.withOpacity(index == 0 ? 1 : 0.4),
                      ),
                    ),
                  ),
                ),
              ),
            if (photos.isNotEmpty) const SizedBox(height: 24),

            // Информация о специалисте (без кликабельности)
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
              ],
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

            // Отзывы и рейтинг (только просмотр)
            const Text('Отзывы', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

            if (_isLoadingReviews)
              const Center(child: CircularProgressIndicator())
            else ...[
              if (_reviewCount > 0)
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
                )
              else
                const Text('Пока нет отзывов', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),

              if (_reviews.isNotEmpty)
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
    super.dispose();
  }
}