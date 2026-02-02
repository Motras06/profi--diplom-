import 'package:flutter/material.dart';
import '../../services/service_service.dart';
import '../../widgets/user/main_tab/main_tab_search_bar.dart';
import '../../widgets/user/main_tab/main_tab_filters_bottom_sheet.dart';
import '../../widgets/user/main_tab/main_tab_empty_state.dart';
import '../../widgets/user/main_tab/service_card.dart';

class MainTab extends StatefulWidget {
  const MainTab({super.key});

  @override
  State<MainTab> createState() => _MainTabState();
}

class _MainTabState extends State<MainTab> {
  final ServiceService _serviceService = ServiceService();

  @override
  void initState() {
    super.initState();
    _serviceService.addListener(_onFiltersChanged);
    _serviceService.loadServices();
  }

  void _onFiltersChanged() {
    if (mounted) setState(() {});
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MainTabFiltersBottomSheet(
        serviceService: _serviceService,
        onApply: () {
          if (mounted) {
            setState(() {});
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Фильтры применены')));
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _serviceService.removeListener(_onFiltersChanged);
    _serviceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final childAspectRatio = screenWidth < 360 ? 0.72 : 0.68;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,

      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            MainTabSearchBar(
              controller: _serviceService.searchController,
              onFilterPressed: _openFilters,
            ),

            Expanded(
              child: _serviceService.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _serviceService.filteredServices.isEmpty
                  ? const MainTabEmptyState()
                  : GridView.builder(
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
                      itemCount: _serviceService.filteredServices.length,
                      itemBuilder: (context, index) {
                        final service = _serviceService.filteredServices[index];
                        final serviceId = service['id']?.toString();

                        if (serviceId == null) {
                          debugPrint('У услуги нет id: $service');
                          return const SizedBox.shrink();
                        }

                        return ServiceCard(
                          service: service,
                          isSaved: _serviceService.isServiceSaved(
                            service['id'],
                          ),
                          onToggleSave: () =>
                              _serviceService.toggleSaveService(service['id']),
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
