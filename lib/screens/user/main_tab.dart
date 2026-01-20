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
    setState(() {});
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MainTabFiltersBottomSheet(
        serviceService: _serviceService,
        onApply: () {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Фильтры применены')),
          );
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
    return Scaffold(
      body: Column(
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
                        padding: const EdgeInsets.all(8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _serviceService.filteredServices.length,
                        itemBuilder: (context, index) {
                          final service = _serviceService.filteredServices[index];
                          return ServiceCard(
                            service: service,
                            isSaved: _serviceService.isServiceSaved(service['id']),
                            onToggleSave: () => _serviceService.toggleSaveService(service['id']),
                            onReport: _serviceService.reportService,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}