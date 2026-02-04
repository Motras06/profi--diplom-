import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SavedServiceService extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _savedServices = [];
  List<Map<String, dynamic>> _filteredServices = [];
  bool _isLoading = true;

  final TextEditingController searchController = TextEditingController();

  String _sortBy = 'saved_desc';
  double? _minPrice;
  double? _maxPrice;

  final List<String> _availableSpecialties = [
    'Сантехника',
    'Электрика',
    'Ремонт квартир',
    'Отделка и штукатурка',
    'Уборка / Клининг',
    'Красота / Парикмахер',
    'Маникюр / Педикюр',
    'Массаж',
    'Авторемонт',
    'Автомойка / детейлинг',
    'IT / Программирование',
    'Дизайн интерьера',
    'Фото / Видео',
    'Репетиторство',
    'Перевозки / Грузчики',
    'Сад / Огород',
    'Ветеринар',
    'Психология / Коучинг',
    'Другое'
  ];

  final Set<String> _selectedSpecialties = {};

  List<Map<String, dynamic>> get filteredServices => _filteredServices;
  bool get isLoading => _isLoading;
  String get sortBy => _sortBy;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  List<String> get availableSpecialties => _availableSpecialties;
  Set<String> get selectedSpecialties => _selectedSpecialties;

  SavedServiceService() {
    searchController.addListener(_applyFilters);
  }

  Future<void> loadSavedServices() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        _savedServices = [];
        _filteredServices = [];
        return;
      }

      final response = await supabase
          .from('saved_services')
          .select('''
            service_id,
            saved_at,
            services (
              id, name, description, price,
              profiles!specialist_id (id, display_name, photo_url, specialty)
            )
          ''')
          .eq('user_id', userId)
          .order('saved_at', ascending: false);

      final List<Map<String, dynamic>> services = [];

      for (var item in response) {
        final service = item['services'] as Map<String, dynamic>;
        service['id'] = item['service_id'];
        service['saved_at'] = item['saved_at'];

        final photos = await supabase
            .from('service_photos')
            .select('photo_url')
            .eq('service_id', service['id'])
            .order('order', ascending: true)
            .limit(1);

        service['main_photo'] = photos.isNotEmpty
            ? photos.first['photo_url']
            : null;

        services.add(service);
      }

      _savedServices = services;
      _filteredServices = List.from(services);
    } catch (e) {
      _savedServices = [];
      _filteredServices = [];
    } finally {
      _isLoading = false;
      _applyFilters();
      notifyListeners();
    }
  }

  void _applyFilters() {
    final query = searchController.text.toLowerCase().trim();

    List<Map<String, dynamic>> result = _savedServices.where((service) {
      final name = (service['name'] as String?)?.toLowerCase() ?? '';
      final desc = (service['description'] as String?)?.toLowerCase() ?? '';
      final master =
          (service['profiles']?['display_name'] as String?)?.toLowerCase() ??
          '';
      final specialty =
          (service['profiles']?['specialty'] as String?)?.toLowerCase() ?? '';

      final matchesSearch =
          name.contains(query) ||
          desc.contains(query) ||
          master.contains(query) ||
          specialty.contains(query);

      final matchesSpecialty =
          _selectedSpecialties.isEmpty ||
          _selectedSpecialties.contains(service['profiles']?['specialty']);

      final price = service['price'] as num?;
      final matchesPrice =
          (price == null) ||
          (_minPrice == null || price >= _minPrice!) &&
              (_maxPrice == null || price <= _maxPrice!);

      return matchesSearch && matchesSpecialty && matchesPrice;
    }).toList();

    switch (_sortBy) {
      case 'price_asc':
        result.sort(
          (a, b) =>
              (a['price'] as num? ?? 0).compareTo(b['price'] as num? ?? 0),
        );
        break;
      case 'price_desc':
        result.sort(
          (a, b) =>
              (b['price'] as num? ?? 0).compareTo(a['price'] as num? ?? 0),
        );
        break;
      case 'name_asc':
        result.sort(
          (a, b) => (a['name'] as String? ?? '').compareTo(
            b['name'] as String? ?? '',
          ),
        );
        break;
      case 'saved_desc':
      default:
        result.sort(
          (a, b) => DateTime.parse(
            b['saved_at'] as String,
          ).compareTo(DateTime.parse(a['saved_at'] as String)),
        );
    }

    _filteredServices = result;
    notifyListeners();
  }

  Future<void> removeFromSaved(int serviceId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await supabase
          .from('saved_services')
          .delete()
          .eq('user_id', userId)
          .eq('service_id', serviceId);

      _savedServices.removeWhere((s) => s['id'] == serviceId);
      _filteredServices.removeWhere((s) => s['id'] == serviceId);
      notifyListeners();
    } catch (e) {}
  }

  void updateSort(String sort) {
    _sortBy = sort;
    _applyFilters();
  }

  void updatePriceRange(double? min, double? max) {
    _minPrice = min;
    _maxPrice = max;
    _applyFilters();
  }

  void toggleSpecialty(String specialty, bool selected) {
    if (selected) {
      _selectedSpecialties.add(specialty);
    } else {
      _selectedSpecialties.remove(specialty);
    }
    _applyFilters();
  }

  void resetFilters() {
    _sortBy = 'saved_desc';
    _minPrice = null;
    _maxPrice = null;
    _selectedSpecialties.clear();
    searchController.clear();
    _applyFilters();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
