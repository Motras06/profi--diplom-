// lib/screens/user/saved_tab.dart
import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../screens/other/service_screen.dart';

class SavedTab extends StatefulWidget {
  const SavedTab({super.key});

  @override
  State<SavedTab> createState() => _SavedTabState();
}

class _SavedTabState extends State<SavedTab> {
  List<Map<String, dynamic>> _savedServices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedServices();
  }

  Future<void> _loadSavedServices() async {
    setState(() => _isLoading = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _savedServices = [];
          _isLoading = false;
        });
        return;
      }

      // Загружаем сохранённые услуги + данные
      final response = await supabase
          .from('saved_services')
          .select('''
            services (
              id, name, description, price,
              profiles!specialist_id (display_name, photo_url, specialty)
            )
          ''')
          .eq('user_id', userId)
          .order('saved_at', ascending: false);

      final List<Map<String, dynamic>> services = [];

      for (var item in response) {
        final service = item['services'] as Map<String, dynamic>;

        // Загружаем фото
        final photosResponse = await supabase
            .from('service_photos')
            .select('photo_url')
            .eq('service_id', service['id'])
            .order('order', ascending: true)
            .limit(3);

        service['photos'] = photosResponse.map((p) => p['photo_url'] as String).toList();

        services.add(service);
      }

      setState(() {
        _savedServices = services;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки сохранённых: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFromSaved(int serviceId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await supabase
          .from('saved_services')
          .delete()
          .eq('user_id', userId)
          .eq('service_id', serviceId);

      setState(() {
        _savedServices.removeWhere((s) => s['id'] == serviceId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Услуга удалена из сохранённых')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedServices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_outline, size: 80, color: Colors.grey[600]),
                      const SizedBox(height: 24),
                      const Text(
                        'Сохранённые услуги',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Вы ещё ничего не сохранили',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Нажмите на закладку в карточке услуги, чтобы добавить её сюда',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: _savedServices.length,
                  itemBuilder: (context, index) {
                    final service = _savedServices[index];
                    final specialist = service['profiles'] ?? {};

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ServiceScreen(service: service),
                            ),
                          );
                        },
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Фото услуги
                                if ((service['photos'] as List?)?.isNotEmpty == true)
                                  AspectRatio(
                                    aspectRatio: 16 / 9,
                                    child: PageView.builder(
                                      itemCount: (service['photos'] as List).length,
                                      itemBuilder: (context, photoIndex) {
                                        return Image.network(
                                          service['photos'][photoIndex],
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child, progress) =>
                                              progress == null ? child : const Center(child: CircularProgressIndicator()),
                                          errorBuilder: (context, error, stackTrace) =>
                                              const Center(child: Icon(Icons.error, color: Colors.red)),
                                        );
                                      },
                                    ),
                                  ),

                                // Информация
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Специалист
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundImage: specialist['photo_url'] != null
                                                ? NetworkImage(specialist['photo_url'])
                                                : null,
                                            child: specialist['photo_url'] == null
                                                ? Text(
                                                    (specialist['display_name'] as String?)?.substring(0, 1).toUpperCase() ?? 'М',
                                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  specialist['display_name'] ?? 'Мастер',
                                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                                ),
                                                if (specialist['specialty'] != null)
                                                  Text(
                                                    specialist['specialty'],
                                                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),

                                      // Название услуги
                                      Text(
                                        service['name'],
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8),

                                      // Описание
                                      if (service['description'] != null)
                                        Text(
                                          service['description'],
                                          style: const TextStyle(color: Colors.grey),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      const SizedBox(height: 12),

                                      // Цена
                                      Text(
                                        service['price'] != null
                                            ? '${service['price']} ₽'
                                            : 'По договорённости',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // Кнопка "Убрать из сохранённых"
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.bookmark, color: Colors.white),
                                  onPressed: () => _removeFromSaved(service['id']),
                                  tooltip: 'Убрать из сохранённых',
                                ),
                              ),
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