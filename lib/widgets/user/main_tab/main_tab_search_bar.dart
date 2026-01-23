// lib/widgets/user/main_tab/main_tab_search_bar.dart
import 'package:flutter/material.dart';

class MainTabSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onFilterPressed;

  const MainTabSearchBar({
    super.key,
    required this.controller,
    required this.onFilterPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Поиск услуг или мастеров',
                hintText: 'Ремонт, электрика...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          controller.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Фильтры',
            onPressed: onFilterPressed,
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }
}