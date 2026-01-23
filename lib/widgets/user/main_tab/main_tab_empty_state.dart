// lib/widgets/user/main_tab/main_tab_empty_state.dart
import 'package:flutter/material.dart';

class MainTabEmptyState extends StatefulWidget {
  const MainTabEmptyState({super.key});

  @override
  State<MainTabEmptyState> createState() => _MainTabEmptyStateState();
}

class _MainTabEmptyStateState extends State<MainTabEmptyState> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // Запускаем анимацию с небольшой задержкой
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Иконка с лёгким масштабированием и цветом primary
                ScaleTransition(
                  scale: Tween<double>(begin: 0.7, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _controller,
                      curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
                    ),
                  ),
                  child: Icon(
                    Icons.search_off_rounded,
                    size: 88,
                    color: colorScheme.primary.withOpacity(0.7),
                  ),
                ),

                const SizedBox(height: 32),

                // Заголовок — headlineMedium из M3
                Text(
                  'Услуги не найдены',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Подзаголовок — bodyLarge с onSurfaceVariant
                Text(
                  'Попробуйте изменить поисковый запрос или убрать некоторые фильтры',
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Кнопка "Сбросить фильтры" — optional, но очень полезна в M3 empty states
                OutlinedButton.icon(
                  onPressed: () {
                    // Здесь можно вызвать сброс фильтров через ServiceService
                    // _serviceService.resetFilters();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Фильтры сброшены'),
                        backgroundColor: colorScheme.primary,
                      ),
                    );
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text('Сбросить фильтры'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    side: BorderSide(color: colorScheme.primary, width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}