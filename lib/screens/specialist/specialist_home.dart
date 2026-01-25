// lib/screens/specialist/specialist_home.dart
import 'package:flutter/material.dart';
import 'package:profi/screens/specialist/services_tab.dart';
import 'package:profi/screens/specialist/chat_tab.dart';
import 'package:profi/screens/specialist/profile_tab.dart';
import 'package:profi/screens/specialist/orders_tab.dart';

class SpecialistHome extends StatefulWidget {
  final String displayName;

  const SpecialistHome({super.key, required this.displayName});

  @override
  State<SpecialistHome> createState() => _SpecialistHomeState();
}

class _SpecialistHomeState extends State<SpecialistHome> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      ServicesTab(displayName: widget.displayName),
      const ChatTab(),
      const OrdersTab(),
      ProfileTab(displayName: widget.displayName),
    ];
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Цвет панели — с surface tint для глубины
    final navBarColor = ElevationOverlay.applySurfaceTint(
      colorScheme.surface,
      colorScheme.surfaceTint,
      3,
    );

    return Scaffold(
      backgroundColor: colorScheme.background,
      extendBody: true, // чтобы контент шёл под панель

      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: KeyedSubtree(
          key: ValueKey<int>(_selectedIndex),
          child: _pages[_selectedIndex],
        ),
      ),

      // Нижняя панель с большой тенью и закруглением
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                // Главная большая тень
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.24),
                  blurRadius: 32,
                  spreadRadius: 8,
                  offset: const Offset(0, 12),
                ),
                // Вспомогательная тень для объёма
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.12),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              elevation: 0,
              color: navBarColor,
              borderRadius: BorderRadius.circular(32),
              clipBehavior: Clip.antiAlias,
              child: NavigationBar(
                onDestinationSelected: _onItemTapped,
                selectedIndex: _selectedIndex,
                backgroundColor: Colors.transparent,
                indicatorColor: colorScheme.primary.withOpacity(0.22),
                height: 76,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.build_outlined),
                    selectedIcon: Icon(Icons.build_rounded),
                    label: 'Услуги',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.chat_bubble_outline_rounded),
                    selectedIcon: Icon(Icons.chat_bubble_rounded),
                    label: 'Чаты',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.assignment_outlined),
                    selectedIcon: Icon(Icons.assignment_rounded),
                    label: 'Заказы',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline_rounded),
                    selectedIcon: Icon(Icons.person_rounded),
                    label: 'Профиль',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
