import 'package:flutter/material.dart';
import 'package:profi/screens/other/all_specialist_services_view.dart';
import 'package:profi/screens/other/document_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../screens/other/service_chat_screen.dart';

class SpecialistProfileScreen extends StatefulWidget {
  final Map<String, dynamic> specialist;

  const SpecialistProfileScreen({super.key, required this.specialist});

  @override
  State<SpecialistProfileScreen> createState() =>
      _SpecialistProfileScreenState();
}

class _SpecialistProfileScreenState extends State<SpecialistProfileScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _pinnedDocuments = [];
  bool _isLoadingDocs = true;
  bool _isLoadingReviews = true;
  double _averageRating = 0.0;
  int _totalReviews = 0;

  @override
  void initState() {
    super.initState();
    _loadPinnedDocuments();
    _loadReviewsStats();
  }

  Future<void> _loadPinnedDocuments() async {
    try {
      final docs = await supabase
          .from('documents')
          .select('id, name, file_url, description, created_at')
          .eq('specialist_id', widget.specialist['id'])
          .order('created_at', ascending: false)
          .limit(3);

      if (mounted) {
        setState(() {
          _pinnedDocuments = List<Map<String, dynamic>>.from(docs);
          _isLoadingDocs = false;
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки документов: $e');
      if (mounted) setState(() => _isLoadingDocs = false);
    }
  }

  void _openAllServices() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SpecialistServicesScreen(
          specialistId: widget.specialist['id'],
          specialistName: widget.specialist['display_name'] ?? 'Специалист',
        ),
      ),
    );
  }

  Future<void> _loadReviewsStats() async {
    try {
      final reviews = await supabase
          .from('reviews')
          .select('rating')
          .eq('specialist_id', widget.specialist['id']);

      final total = reviews.length;
      final sum = reviews.fold<double>(
        0.0,
        (s, r) => s + (r['rating'] as int? ?? 0),
      );

      if (mounted) {
        setState(() {
          _averageRating = total > 0 ? sum / total : 0.0;
          _totalReviews = total;
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки статистики отзывов: $e');
      if (mounted) setState(() => _isLoadingReviews = false);
    }
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ServiceChatScreen(specialist: widget.specialist, service: null),
      ),
    );
  }

  void _openAllDocuments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SpecialistDocumentsScreen(
          specialistId: widget.specialist['id'],
          specialistName: widget.specialist['display_name'] ?? 'Специалист',
        ),
      ),
    );
  }

  Widget _buildStars(double rating) {
    final full = rating.floor();
    final half = rating - full >= 0.5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < full) {
          return const Icon(Icons.star_rounded, color: Colors.amber, size: 20);
        }
        if (i == full && half) {
          return const Icon(
            Icons.star_half_rounded,
            color: Colors.amber,
            size: 20,
          );
        }
        return const Icon(
          Icons.star_border_rounded,
          color: Colors.grey,
          size: 20,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final name = widget.specialist['display_name'] ?? 'Мастер';
    final photoUrl = widget.specialist['photo_url'] as String?;
    final specialty = widget.specialist['specialty'] as String?;
    final about = widget.specialist['about'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Hero(
                    tag: 'avatar-${widget.specialist['id']}',
                    child: CircleAvatar(
                      radius: 64,
                      backgroundColor: colorScheme.primaryContainer,
                      foregroundImage: photoUrl != null
                          ? NetworkImage(photoUrl)
                          : null,
                      child: photoUrl == null
                          ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'М',
                              style: TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    name,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (specialty != null && specialty.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      specialty,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStars(_averageRating),
                      const SizedBox(width: 12),
                      Text(
                        _totalReviews > 0
                            ? '${_averageRating.toStringAsFixed(1)} ($_totalReviews)'
                            : 'Нет оценок',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: FilledButton.icon(
                onPressed: _openChat,
                icon: const Icon(Icons.message_rounded),
                label: const Text('Написать сообщение'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),

          if (about != null && about.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'О себе',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          about,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Секция документов — теперь только кнопка
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Документы',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _pinnedDocuments.isEmpty && !_isLoadingDocs
                        ? null
                        : _openAllDocuments,
                    icon: const Icon(Icons.folder_outlined),
                    label: Text(
                      _isLoadingDocs
                          ? 'Загрузка...'
                          : 'Закреплённые файлы (${_pinnedDocuments.length})',
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  Text(
                    'Услуги',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _openAllServices,
                    icon: const Icon(Icons.work_outline_rounded),
                    label: const Text('Все услуги специалиста'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}
