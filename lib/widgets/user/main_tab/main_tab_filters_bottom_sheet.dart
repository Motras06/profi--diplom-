import 'package:flutter/material.dart';
import '../../../services/service_service.dart';

class MainTabFiltersBottomSheet extends StatelessWidget {
  final ServiceService serviceService;
  final VoidCallback onApply;

  const MainTabFiltersBottomSheet({
    super.key,
    required this.serviceService,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final minPriceCtrl = TextEditingController(
      text: serviceService.minPrice?.toStringAsFixed(0) ?? '',
    );
    final maxPriceCtrl = TextEditingController(
      text: serviceService.maxPrice?.toStringAsFixed(0) ?? '',
    );

    return StatefulBuilder(
      builder: (context, setModalState) => Container(
        height: MediaQuery.of(context).size.height * 0.82,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // drag handle + заголовок
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                width: 40,
                height: 5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Фильтры и сортировка',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Сортировка', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _buildSortChip('По новизне', serviceService.sortBy == 'newest', setModalState, context),
                  _buildSortChip('По цене (дешевле)', serviceService.sortBy == 'price_asc', setModalState, context),
                  _buildSortChip('По цене (дороже)', serviceService.sortBy == 'price_desc', setModalState, context),
                  _buildSortChip('По рейтингу', serviceService.sortBy == 'rating_desc', setModalState, context),

                  const SizedBox(height: 24),
                  const Text('Диапазон цены (BYN)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minPriceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _inputDeco('От'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: maxPriceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _inputDeco('До'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Text('Специальность', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: serviceService.availableSpecialties.map((spec) {
                      final selected = serviceService.selectedSpecialties.contains(spec);
                      return FilterChip(
                        label: Text(spec),
                        selected: selected,
                        onSelected: (v) {
                          setModalState(() {
                            serviceService.toggleSpecialty(spec, v);
                          });
                        },
                        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                        checkmarkColor: Theme.of(context).primaryColor,
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 32),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              serviceService.resetFilters();
                              minPriceCtrl.clear();
                              maxPriceCtrl.clear();
                            });
                          },
                          child: const Text('Сбросить'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            serviceService.updatePriceRange(
                              double.tryParse(minPriceCtrl.text),
                              double.tryParse(maxPriceCtrl.text),
                            );
                            Navigator.pop(context);
                            onApply();
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Применить', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildSortChip(String label, bool isSelected, StateSetter setModalState, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setModalState(() {
              serviceService.updateSort(
                label == 'По новизне' ? 'newest' :
                label == 'По цене (дешевле)' ? 'price_asc' :
                label == 'По цене (дороже)' ? 'price_desc' : 'rating_desc',
              );
            });
          }
        },
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.15),
        labelStyle: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : null,
          fontWeight: isSelected ? FontWeight.w600 : null,
        ),
      ),
    );
  }
}