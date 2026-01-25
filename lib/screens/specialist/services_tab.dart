// lib/screens/specialist/services_tab.dart
import 'package:flutter/material.dart';
import 'package:profi/widgets/specialist/services_tab/empty_services_state.dart';
import 'package:profi/widgets/specialist/services_tab/service_card.dart';
import 'package:profi/widgets/specialist/services_tab/add_edit_service_dialog.dart';
import '../../services/supabase_service.dart';

class ServicesTab extends StatefulWidget {
  final String displayName;

  const ServicesTab({super.key, required this.displayName});

  @override
  State<ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<ServicesTab>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _filteredServices = [];
  bool _isLoading = true;

  late TextEditingController _searchController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    _loadServices();

    _searchController.addListener(() {
      final query = _searchController.text.toLowerCase().trim();
      setState(() {
        _filteredServices = query.isEmpty
            ? List.from(_services)
            : _services.where((s) {
                final name = (s['name'] as String?)?.toLowerCase() ?? '';
                return name.contains(query);
              }).toList();
      });
    });

    // Запуск анимации после первой загрузки
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw 'Не авторизован';

      final servicesResponse = await supabase
          .from('services')
          .select()
          .eq('specialist_id', userId)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> services = List.from(servicesResponse);

      for (var service in services) {
        final photosResponse = await supabase
            .from('service_photos')
            .select('photo_url')
            .eq('service_id', service['id'])
            .order('order', ascending: true)
            .limit(3);

        // Безопасная обработка: фильтруем null и кастуем к List<String>
        service['photos'] = photosResponse
            .map((p) => p['photo_url'] as String?)
            .where((url) => url != null)
            .cast<String>()
            .toList();
      }

      setState(() {
        _services = services;
        _filteredServices = _services;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки услуг: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddEditDialog({Map<String, dynamic>? service}) async {
    await AddEditServiceDialog.show(
      context: context,
      service: service,
      onSaved: () {
        _loadServices();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              service == null ? 'Услуга добавлена' : 'Услуга обновлена',
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    // Адаптивный aspect ratio для карточек
    final childAspectRatio = screenWidth < 360 ? 0.72 : 0.68;

    return Scaffold(
      backgroundColor: colorScheme.background,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: Column(
          children: [
            // Поиск + кнопка добавления (в стиле MainTabSearchBar)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        color: colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withOpacity(0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Поиск моих услуг...',
                          hintStyle: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: colorScheme.primary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FloatingActionButton.small(
                    onPressed: () => _showAddEditDialog(),
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundColor: colorScheme.onPrimaryContainer,
                    elevation: 3,
                    child: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredServices.isEmpty
                  ? const EmptyServicesState()
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: GridView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth < 360 ? 8 : 12,
                          vertical: 12,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: childAspectRatio,
                          crossAxisSpacing: screenWidth < 360 ? 10 : 14,
                          mainAxisSpacing: screenWidth < 360 ? 12 : 16,
                        ),
                        itemCount: _filteredServices.length,
                        itemBuilder: (context, index) {
                          final service = _filteredServices[index];
                          return ServiceCard(
                            service: service,
                            onEdit: () => _showAddEditDialog(service: service),
                            onDelete: () {
                              // Реализуй удаление здесь или передай callback
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Удаление услуги...'),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
