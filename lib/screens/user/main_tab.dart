// lib/screens/user/main_tab.dart
import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../screens/other/service_screen.dart';
import '../../screens/other/specialist_profile.dart'; // Новый импорт

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

      final servicesResponse = await supabase
          .from('services')
          .select('''
            id, name, description, price, created_at,
            profiles!specialist_id(id, display_name, photo_url, specialty, about)
          ''')
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> services = List.from(servicesResponse);

      for (var service in services) {
        final photosResponse = await supabase
            .from('service_photos')
            .select('photo_url')
            .eq('service_id', service['id'])
            .order('order', ascending: true)
            .limit(1);

        service['main_photo'] = photosResponse.isNotEmpty ? photosResponse.first['photo_url'] : null;
      }

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
        final specialty = (service['profiles']?['specialty'] as String?)?.toLowerCase() ?? '';
        return name.contains(query) ||
            description.contains(query) ||
            specialistName.contains(query) ||
            specialty.contains(query);
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
        await supabase.from('saved_services').delete().eq('user_id', userId).eq('service_id', serviceId);
        setState(() => _savedServiceIds.remove(serviceId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Услуга удалена из сохранённых')),
        );
      } else {
        await supabase.from('saved_services').insert({'user_id': userId, 'service_id': serviceId});
        setState(() => _savedServiceIds.add(serviceId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Услуга сохранена!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  void _reportService() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Жалоба отправлена (пока заглушка)')),
    );
    // TODO: Реализовать форму жалобы
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                width: 40,
                height: 5,
                child: DecoratedBox(decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.all(Radius.circular(10)))),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text('Фильтры и сортировка', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Сортировка', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _buildFilterChip('По новизне', true),
                  _buildFilterChip('По цене (дешевле)', false),
                  _buildFilterChip('По цене (дороже)', false),
                  _buildFilterChip('По рейтингу', false),
                  const SizedBox(height: 20),
                  const Text('Диапазон цены', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(decoration: InputDecoration(labelText: 'От', border: OutlineInputBorder()))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(decoration: InputDecoration(labelText: 'До', border: OutlineInputBorder()))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Специальность', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Сантехника', 'Электрика', 'Ремонт', 'Уборка', 'Красота'].map((spec) {
                      return FilterChip(label: Text(spec), onSelected: (_) {});
                    }).toList(),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Фильтры применены (заглушка)')));
                    },
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    child: const Text('Применить фильтры'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {},
      ),
    );
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
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Поиск услуг или мастеров',
                      hintText: 'Ремонт, электрика...',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.tune),
                  tooltip: 'Фильтры',
                  onPressed: _openFilters,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredServices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 70, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            const Text('Услуги не найдены', style: TextStyle(fontSize: 17)),
                            const SizedBox(height: 6),
                            Text(
                              _searchController.text.isEmpty ? 'В базе пока нет услуг' : 'Попробуйте изменить запрос',
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 4,  // Уменьшен центральный отступ
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _filteredServices.length,
                        itemBuilder: (context, index) {
                          final service = _filteredServices[index];
                          final specialist = service['profiles'] ?? {};
                          final isSaved = _savedServiceIds.contains(service['id']);
                          final String? photoUrl = service['main_photo'];

                          return Card(
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 3,
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
                                      if (photoUrl != null)
                                        AspectRatio(
                                          aspectRatio: 16 / 9,
                                          child: Image.network(
                                            photoUrl,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator()),
                                            errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[300], child: const Icon(Icons.broken_image)),
                                          ),
                                        )
                                      else
                                        Container(
                                          height: 140,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.image_not_supported, size: 48),
                                        ),

                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Кликабельный блок мастера
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (context) => SpecialistProfileScreen(specialist: specialist),
                                                  ),
                                                );
                                              },
                                              child: Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 12,
                                                    backgroundImage: specialist['photo_url'] != null ? NetworkImage(specialist['photo_url']) : null,
                                                    child: specialist['photo_url'] == null
                                                        ? Text(
                                                            (specialist['display_name'] as String?)?.substring(0, 1).toUpperCase() ?? 'М',
                                                            style: const TextStyle(fontSize: 10),
                                                          )
                                                        : null,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      specialist['display_name'] ?? 'Мастер',
                                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              service['name'],
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              service['price'] != null ? '${service['price']} BYN' : 'По договорённости',
                                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Кнопки: сохранить и пожаловаться
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Container(
                                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                                      child: IconButton(
                                        iconSize: 18,
                                        padding: const EdgeInsets.all(5),
                                        constraints: const BoxConstraints(),
                                        icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: Colors.white, size: 18),
                                        onPressed: () => _toggleSaveService(service['id']),
                                      ),
                                    ),
                                  ),

                                  Positioned(
                                    bottom: 4,
                                    right: 4,
                                    child: Container(
                                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.7), shape: BoxShape.circle),
                                      child: IconButton(
                                        iconSize: 16,
                                        padding: const EdgeInsets.all(5),
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(Icons.flag, color: Colors.white, size: 16),
                                        tooltip: 'Пожаловаться',
                                        onPressed: _reportService,
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