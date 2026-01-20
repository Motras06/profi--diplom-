// lib/widgets/user/saved_tab/saved_tab_filters_bottom_sheet.dart
import 'package:flutter/material.dart';
import '../../../services/saved_service_service.dart';

class SavedTabFiltersBottomSheet extends StatelessWidget {
  final SavedServiceService service;
  final VoidCallback onApply;

  const SavedTabFiltersBottomSheet({
    super.key,
    required this.service,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final minPriceCtrl = TextEditingController(
      text: service.minPrice?.toStringAsFixed(0) ?? '',
    );
    final maxPriceCtrl = TextEditingController(
      text: service.maxPrice?.toStringAsFixed(0) ?? '',
    );

    // Локальная функция внутри build — context доступен
    Widget buildSortChip(String label, bool isSelected, StateSetter setModalState) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setModalState(() {
                service.updateSort(
                  label == 'По дате сохранения' ? 'saved_desc' :
                  label == 'По цене (дешевле)' ? 'price_asc' :
                  label == 'По цене (дороже)' ? 'price_desc' : 'name_asc',
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

    return StatefulBuilder(
      builder: (context, setModalState) => Container(
        height: MediaQuery.of(context).size.height * 0.82,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                width: 40,
                height: 5,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.all(Radius.circular(10))),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text('Фильтры и сортировка', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 1),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Сортировка', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  buildSortChip('По дате сохранения', service.sortBy == 'saved_desc', setModalState),
                  buildSortChip('По цене (дешевле)', service.sortBy == 'price_asc', setModalState),
                  buildSortChip('По цене (дороже)', service.sortBy == 'price_desc', setModalState),
                  buildSortChip('По имени услуги', service.sortBy == 'name_asc', setModalState),

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
                    children: service.availableSpecialties.map((spec) {
                      final selected = service.selectedSpecialties.contains(spec);
                      return FilterChip(
                        label: Text(spec),
                        selected: selected,
                        onSelected: (v) {
                          setModalState(() {
                            service.toggleSpecialty(spec, v);
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
                              service.resetFilters();
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
                            service.updatePriceRange(
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
}