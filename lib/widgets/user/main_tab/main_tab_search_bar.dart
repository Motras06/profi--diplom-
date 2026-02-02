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
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(32);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: radius,
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Поиск услуг или мастеров',
                  prefixIcon: const Icon(Icons.search),

                  border: OutlineInputBorder(
                    borderRadius: radius,
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: radius,
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: radius,
                    borderSide: BorderSide.none,
                  ),

                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),

                  suffixIcon: controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: controller.clear,
                        )
                      : null,
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.tune),
              tooltip: 'Фильтры',
              onPressed: onFilterPressed,
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.surfaceVariant,
                padding: const EdgeInsets.all(14),
                shape: RoundedRectangleBorder(borderRadius: radius),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
