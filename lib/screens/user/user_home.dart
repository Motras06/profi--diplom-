// lib/screens/auth/user_home.dart
import 'package:flutter/material.dart';
import 'package:profi/screens/user/main_tab.dart';
import 'package:profi/screens/user/saved_tab.dart';
import 'package:profi/screens/user/profile_tab.dart';
import 'package:profi/screens/user/chat_tab.dart';

class UserHome extends StatefulWidget {
  final String displayName;

  const UserHome({super.key, required this.displayName});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const MainTab(),
      const SavedTab(),
      const UserChatTab(),
      const UserProfileTab(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Цвет панели — чуть приподнятый, с surface tint
    final navBarColor = ElevationOverlay.applySurfaceTint(
      colorScheme.surface,
      colorScheme.surfaceTint,
      3,
    );

    return Scaffold(
      backgroundColor: colorScheme.background,
      extendBody: true,

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

      // Нижняя панель с такой же большой тенью, как у карточек
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                // Основная большая тень — как у карточек
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
              elevation: 0, // встроенная elevation не нужна — тень уже ручная
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
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.home_outlined),
                    selectedIcon: const Icon(Icons.home_rounded),
                    label: 'Главная',
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.bookmark_outline_rounded),
                    selectedIcon: const Icon(Icons.bookmark_rounded),
                    label: 'Сохранённые',
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    selectedIcon: const Icon(Icons.chat_bubble_rounded),
                    label: 'Чаты',
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.person_outline_rounded),
                    selectedIcon: const Icon(Icons.person_rounded),
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
