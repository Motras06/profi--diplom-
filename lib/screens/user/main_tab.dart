// lib/screens/user/main_tab.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_service.dart';
import '../../screens/other/service_screen.dart';

class MainTab extends StatefulWidget {
  const MainTab({super.key});

  @override
  State<MainTab> createState() => _MainTabState();
}

class _MainTabState extends State<MainTab> {
  List<Map<String, dynamic>> _allServices = [];
  List<Map<String, dynamic>> _filteredServices = [];
  Set<int> _savedServiceIds = {};
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadServices();
    _searchController.addListener(_filterServices);
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);

    try {
      final userId = supabase.auth.currentUser?.id;

      // Загружаем услуги + данные специалиста
      final servicesResponse = await supabase
          .from('services')
          .select('''
            id, name, description, price, created_at,
            profiles!specialist_id(display_name, photo_url, specialty)
          ''')
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> services = List.from(servicesResponse);

      // Загружаем фото услуг
      for (var service in services) {
        final photosResponse = await supabase
            .from('service_photos')
            .select('photo_url')
            .eq('service_id', service['id'])
            .order('order', ascending: true)
            .limit(3);

        service['photos'] = photosResponse.map((p) => p['photo_url'] as String).toList();
      }

      // Загружаем сохранённые услуги
      if (userId != null) {
        final savedResponse = await supabase
            .from('saved_services')
            .select('service_id')
            .eq('user_id', userId);

        _savedServiceIds = savedResponse.map((e) => e['service_id'] as int).toSet();
      }

      setState(() {
        _allServices = services;
        _filteredServices = services;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки услуг: $e')),
        );
        setState(() {
          _allServices = [];
          _filteredServices = [];
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterServices() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredServices = _allServices.where((service) {
        final name = (service['name'] as String?)?.toLowerCase() ?? '';
        final description = (service['description'] as String?)?.toLowerCase() ?? '';
        final specialistName = (service['profiles']?['display_name'] as String?)?.toLowerCase() ?? '';
        return name.contains(query) || description.contains(query) || specialistName.contains(query);
      }).toList();
    });
  }

  Future<void> _toggleSaveService(int serviceId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Войдите в аккаунт, чтобы сохранять услуги')),
      );
      return;
    }

    try {
      if (_savedServiceIds.contains(serviceId)) {
        await supabase
            .from('saved_services')
            .delete()
            .eq('user_id', userId)
            .eq('service_id', serviceId);

        setState(() => _savedServiceIds.remove(serviceId));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Услуга удалена из сохранённых')),
        );
      } else {
        await supabase.from('saved_services').insert({
          'user_id': userId,
          'service_id': serviceId,
        });

        setState(() => _savedServiceIds.add(serviceId));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Услуга сохранена!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения: $e')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Поиск
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Поиск услуг или мастеров',
                hintText: 'Ремонт, электрика, Алексей...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterServices();
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Список услуг
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredServices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            const Text('Услуги не найдены', style: TextStyle(fontSize: 18)),
                            const SizedBox(height: 8),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'В базе пока нет услуг'
                                  : 'Попробуйте изменить запрос',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredServices.length,
                        itemBuilder: (context, index) {
                          final service = _filteredServices[index];
                          final specialist = service['profiles'] ?? {};
                          final isSaved = _savedServiceIds.contains(service['id']);

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

                                  // Кнопка "Сохранить"
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                                          color: Colors.white,
                                        ),
                                        onPressed: () => _toggleSaveService(service['id']),
                                        tooltip: isSaved ? 'Убрать из сохранённых' : 'Сохранить',
                                      ),
                                    ),
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