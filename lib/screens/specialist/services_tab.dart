// lib/screens/specialist/services_tab.dart
import 'package:flutter/material.dart';
import 'package:profi/widgets/specialist/services_tab/empty_services_state.dart';
import 'package:profi/widgets/specialist/services_tab/service_card.dart';

import '../../widgets/specialist/services_tab/add_edit_service_dialog.dart';
import '/../services/supabase_service.dart';


class ServicesTab extends StatefulWidget {
  const ServicesTab({super.key, required String displayName});

  @override
  State<ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<ServicesTab> {
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _filteredServices = [];
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

        service['photos'] = photosResponse.map((p) => p['photo_url'] as String).toList();
      }

      setState(() {
        _services = services;
        _filteredServices = _services;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки услуг: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterServices() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredServices = _services.where((service) {
        final name = (service['name'] as String?)?.toLowerCase() ?? '';
        return name.contains(query);
      }).toList();
    });
  }

  Future<void> _showAddEditDialog({Map<String, dynamic>? service}) async {
    await AddEditServiceDialog.show(
      context: context,
      service: service,
      onSaved: () => _loadServices(),
    );
  }

  Future<void> _deleteService(int serviceId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить услугу?'),
        content: const Text('Это действие нельзя отменить'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await supabase.from('services').delete().eq('id', serviceId);
        _loadServices();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Услуга удалена')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка удаления: $e')));
      }
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
      appBar: AppBar(
        title: const Text('Мои услуги'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEditDialog(),
            tooltip: 'Добавить услугу',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Поиск услуг',
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
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredServices.isEmpty
                    ? const EmptyServicesState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredServices.length,
                        itemBuilder: (context, index) {
                          final service = _filteredServices[index];
                          return ServiceCard(
                            service: service,
                            onEdit: () => _showAddEditDialog(service: service),
                            onDelete: () => _deleteService(service['id']),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}