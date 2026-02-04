import 'package:flutter/material.dart';

import '../../services/service_service.dart';
import '../../widgets/user/main_tab/main_tab_search_bar.dart';
import '../../widgets/user/main_tab/main_tab_filters_bottom_sheet.dart';
import '../../widgets/user/main_tab/main_tab_empty_state.dart';
import '../../widgets/user/main_tab/service_card.dart';

class SpecialistServicesScreen extends StatefulWidget {
  final String specialistId;
  final String specialistName;

  const SpecialistServicesScreen({
    super.key,
    required this.specialistId,
    required this.specialistName,
  });

  @override
  State<SpecialistServicesScreen> createState() =>
      _SpecialistServicesScreenState();
}

class _SpecialistServicesScreenState extends State<SpecialistServicesScreen>
    with TickerProviderStateMixin {
  late final ServiceService _service;

  @override
  void initState() {
    super.initState();

    _service = ServiceService();
    _service.addListener(_onServicesChanged);

    // Важно: сразу устанавливаем фильтр по специалисту
    _service.setSpecialistFilter(widget.specialistId);

    // Затем загружаем услуги — теперь они уже будут отфильтрованы
    _service.loadServices2();
  }

  void _onServicesChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MainTabFiltersBottomSheet(
        serviceService: _service,
        onApply: () {
          if (mounted) {
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Фильтры применены')),
            );
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _service.removeListener(_onServicesChanged);
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final childAspectRatio = screenWidth < 360 ? 0.72 : 0.68;
    final horizontalPadding = screenWidth < 360 ? 8.0 : 12.0;
    final crossSpacing = screenWidth < 360 ? 10.0 : 14.0;
    final mainSpacing = screenWidth < 360 ? 12.0 : 16.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Услуги ${widget.specialistName}'),
        centerTitle: true,
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            MainTabSearchBar(
              controller: _service.searchController,
              onFilterPressed: _openFilters,
            ),
            Expanded(
              child: _service.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _service.filteredServices.isEmpty
                      ? const MainTabEmptyState()
                      : GridView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: 12,
                          ),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: childAspectRatio,
                            crossAxisSpacing: crossSpacing,
                            mainAxisSpacing: mainSpacing,
                          ),
                          itemCount: _service.filteredServices.length,
                          itemBuilder: (context, index) {
                            final service = _service.filteredServices[index];
                            final serviceIdStr = service['id']?.toString();

                            if (serviceIdStr == null) {
                              debugPrint('У услуги нет id: $service');
                              return const SizedBox.shrink();
                            }

                            final serviceId = int.tryParse(serviceIdStr);
                            if (serviceId == null) {
                              return const SizedBox.shrink();
                            }

                            return ServiceCard(
                              service: service,
                              isSaved: _service.isServiceSaved(serviceId),
                              onToggleSave: () =>
                                  _service.toggleSaveService(serviceId),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}