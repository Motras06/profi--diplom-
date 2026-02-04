import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceService extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _allServices = [];
  List<Map<String, dynamic>> _filteredServices = [];
  Set<int> _savedServiceIds = {};
  bool _isLoading = true;

  final TextEditingController searchController = TextEditingController();

  String _sortBy = 'newest';
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
    'Другое',
  ];

  final Set<String> _selectedSpecialties = {};

  String get sortBy => _sortBy;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  List<String> get availableSpecialties => _availableSpecialties;
  Set<String> get selectedSpecialties => _selectedSpecialties;

  List<Map<String, dynamic>> get filteredServices => _filteredServices;
  bool get isLoading => _isLoading;
  Set<int> get savedServiceIds => _savedServiceIds;

  ServiceService() {
    searchController.addListener(_applyFilters);
  }

  Future<void> loadServices() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = supabase.auth.currentUser?.id;

      final response = await supabase
          .from('services')
          .select('''
            id, name, description, price, created_at,
            profiles!specialist_id (id, display_name, photo_url, specialty, about)
          ''')
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> services = List.from(response);

      for (var service in services) {
        final photos = await supabase
            .from('service_photos')
            .select('photo_url')
            .eq('service_id', service['id'])
            .order('order', ascending: true)
            .limit(1);

        service['main_photo'] = photos.isNotEmpty
            ? photos.first['photo_url']
            : null;
      }

      if (userId != null) {
        final saved = await supabase
            .from('saved_services')
            .select('service_id')
            .eq('user_id', userId);
        _savedServiceIds = saved.map((e) => e['service_id'] as int).toSet();
      }

      _allServices = services;
      _filteredServices = List.from(services);
    } catch (e) {
      _allServices = [];
      _filteredServices = [];
    } finally {
      _isLoading = false;
      _applyFilters();
      notifyListeners();
    }
  }

  void _applyFilters() {
    final query = searchController.text.toLowerCase().trim();

    List<Map<String, dynamic>> result = _allServices.where((service) {
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
      case 'rating_desc':
        break;
      case 'newest':
      default:
        result.sort(
          (a, b) => DateTime.parse(
            b['created_at'],
          ).compareTo(DateTime.parse(a['created_at'])),
        );
    }

    _filteredServices = result;
    notifyListeners();
  }

  bool isServiceSaved(int serviceId) => _savedServiceIds.contains(serviceId);

  Future<void> toggleSaveService(int serviceId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      if (_savedServiceIds.contains(serviceId)) {
        await supabase
            .from('saved_services')
            .delete()
            .eq('user_id', userId)
            .eq('service_id', serviceId);
        _savedServiceIds.remove(serviceId);
      } else {
        await supabase.from('saved_services').insert({
          'user_id': userId,
          'service_id': serviceId,
        });
        _savedServiceIds.add(serviceId);
      }
      notifyListeners();
    } catch (e) {}
  }

  String? _specialistFilterId;

  void setSpecialistFilter(String? specialistId) {
    _specialistFilterId = specialistId;
    // Можно сразу вызвать _applyFilters(), если данные уже загружены
    _applyFilters();
    notifyListeners();
  }

  // Самое важное — изменить loadServices, чтобы фильтровать на сервере
  Future<void> loadServices2() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = supabase.auth.currentUser?.id;

      // Самый простой запрос — без фильтров и присваиваний
      final response = await supabase
          .from('services')
          .select('''
          id, name, description, price, created_at,
          profiles!specialist_id (id, display_name, photo_url, specialty, about)
        ''')
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> services = List.from(response);

      // Загрузка главной фотографии
      for (var service in services) {
        final photos = await supabase
            .from('service_photos')
            .select('photo_url')
            .eq('service_id', service['id'])
            .order('order', ascending: true)
            .limit(1);

        service['main_photo'] = photos.isNotEmpty
            ? photos.first['photo_url']
            : null;
      }

      // Сохранённые услуги
      if (userId != null) {
        final saved = await supabase
            .from('saved_services')
            .select('service_id')
            .eq('user_id', userId);

        _savedServiceIds = saved.map((e) => e['service_id'] as int).toSet();
      }

      _allServices = services;
      _filteredServices = List.from(services);

      // Применяем все фильтры, включая специалиста
      _applyFiltersWithSpecialist();
    } catch (e, stack) {
      _allServices = [];
      _filteredServices = [];
      debugPrint('Ошибка загрузки услуг: $e\n$stack');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyFiltersWithSpecialist() {
    final query = searchController.text.toLowerCase().trim();

    List<Map<String, dynamic>> result = _allServices.where((service) {
      // Твоя обычная фильтрация (поиск, цена, специальность)
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

      // Самое главное — фильтр по конкретному специалисту
      final profile = service['profiles'] as Map<String, dynamic>?;
      final serviceSpecialistId = profile?['id']?.toString();
      final matchesSpecialist = serviceSpecialistId == _specialistFilterId;

      return matchesSearch &&
          matchesSpecialty &&
          matchesPrice &&
          matchesSpecialist;
    }).toList();

    // Сортировка (как у тебя)
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
      case 'newest':
      default:
        result.sort(
          (a, b) => DateTime.parse(
            b['created_at'],
          ).compareTo(DateTime.parse(a['created_at'])),
        );
    }

    _filteredServices = result;
    notifyListeners();
  }

  void reportService() {}

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
    _sortBy = 'newest';
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
