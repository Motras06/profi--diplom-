// lib/screens/user/saved_tab.dart
import 'package:flutter/material.dart';
import '../../services/saved_service_service.dart';
import '../../widgets/user/saved_tab/saved_tab_search_bar.dart';
import '../../widgets/user/saved_tab/saved_tab_filters_bottom_sheet.dart';
import '../../widgets/user/saved_tab/saved_tab_empty_state.dart';
import '../../widgets/user/saved_tab/saved_service_card.dart';

class SavedTab extends StatefulWidget {
  const SavedTab({super.key});

  @override
  State<SavedTab> createState() => _SavedTabState();
}

class _SavedTabState extends State<SavedTab> {
  final SavedServiceService _service = SavedServiceService();

  @override
  void initState() {
    super.initState();
    _service.addListener(_onChange);
    _service.loadSavedServices();
  }

  void _onChange() => setState(() {});

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SavedTabFiltersBottomSheet(
        service: _service,
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
    _service.removeListener(_onChange);
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SavedTabSearchBar(
            controller: _service.searchController,
            onFilterPressed: _openFilters,
          ),

          Expanded(
            child: _service.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _service.filteredServices.isEmpty
                    ? const SavedTabEmptyState()
                    : GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _service.filteredServices.length,
                        itemBuilder: (context, index) {
                          final service = _service.filteredServices[index];
                          return SavedServiceCard(
                            service: service,
                            onRemove: () => _service.removeFromSaved(service['id']),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}