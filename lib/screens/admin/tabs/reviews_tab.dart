// lib/screens/admin/tabs/reviews_tab.dart
import 'package:flutter/material.dart';
import 'package:profi/services/supabase_service.dart';

class ReviewsTab extends StatefulWidget {
  const ReviewsTab({super.key});

  @override
  State<ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<ReviewsTab> {
  List<Map<String, dynamic>> _reviews = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _loading = true);
    try {
      final data = await supabase
          .from('reviews')
          .select('''
            id, rating, comment, created_at,
            profiles!user_id (display_name),
            profiles!specialist_id (display_name)
          ''')
          .order('created_at', ascending: false)
          .limit(100);

      setState(() {
        _reviews = List.from(data);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _deleteReview(int id) async {
    try {
      await supabase.from('reviews').delete().eq('id', id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Отзыв удалён')),
        );
        _loadReviews();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_reviews.isEmpty) return const Center(child: Text('Отзывов пока нет'));

    return RefreshIndicator(
      onRefresh: _loadReviews,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _reviews.length,
        itemBuilder: (context, i) {
          final r = _reviews[i];
          final stars = List.generate(r['rating'], (_) => const Icon(Icons.star, color: Colors.amber, size: 18));

          return Card(
            child: ListTile(
              leading: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${r['rating']}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Row(children: stars),
                ],
              ),
              title: Text(r['profiles!specialist_id']?['display_name'] ?? 'Мастер'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('От: ${r['profiles!user_id']?['display_name'] ?? '?'}'),
                  if (r['comment'] != null && r['comment'].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        r['comment'],
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Удалить отзыв?'),
                    content: const Text('Действие нельзя отменить.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _deleteReview(r['id']);
                        },
                        child: const Text('Удалить', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}