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

class _SavedTabState extends State<SavedTab> with TickerProviderStateMixin {
  final SavedServiceService _service = SavedServiceService();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    _service.addListener(_onChange);
    _service.loadSavedServices();
  }

  void _onChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _removeItem(int index, Map<String, dynamic> service) {
    final serviceId = service['id'];
    if (serviceId == null) return;

    _listKey.currentState?.removeItem(
      index,
      (context, animation) =>
          _buildAnimatedItem(context, service, animation, isRemoving: true),
      duration: const Duration(milliseconds: 400),
    );
    _service.removeFromSaved(serviceId);
  }

  Widget _buildAnimatedItem(
    BuildContext context,
    Map<String, dynamic> service,
    Animation<double> animation, {
    bool isRemoving = false,
  }) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: isRemoving
            ? SavedServiceCard(service: service, onRemove: () {})
            : SavedServiceCard(
                service: service,
                onRemove: () => _removeItem(0, service),
              ),
      ),
    );
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SavedTabFiltersBottomSheet(
        service: _service,
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
    _service.removeListener(_onChange);
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

    if (_service.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_service.filteredServices.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: SafeArea(
          top: true,
          bottom: false,
          child: Column(
            children: [
              SavedTabSearchBar(
                controller: _service.searchController,
                onFilterPressed: _openFilters,
              ),
              const Expanded(child: SavedTabEmptyState()),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
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
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 12,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: childAspectRatio,
                        crossAxisSpacing: crossSpacing,
                        mainAxisSpacing: mainSpacing,
                      ),
                      itemCount: _service.filteredServices.length,
                      itemBuilder: (context, index) {
                        final service = _service.filteredServices[index];
                        final serviceId = service['id'];

                        if (serviceId == null) {
                          debugPrint('У услуги нет id: $service');
                          return const SizedBox.shrink();
                        }

                        return SavedServiceCard(
                          service: service,
                          onRemove: () {
                            _service.removeFromSaved(serviceId);
                          },
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
