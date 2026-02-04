import 'package:flutter/material.dart';
import 'package:prowirksearch/services/supabase_service.dart';
import 'package:prowirksearch/screens/admin/tabs/users_tab.dart';
import 'package:prowirksearch/screens/admin/tabs/services_tab.dart';
import 'package:prowirksearch/screens/admin/tabs/chat_monitor_tab.dart';
import 'package:prowirksearch/screens/admin/tabs/complaints_tab.dart';
import 'package:prowirksearch/screens/auth/auth_screen.dart';

class AdminHome extends StatefulWidget {
  final String displayName;

  const AdminHome({super.key, required this.displayName});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  Future<void> _logout(BuildContext context) async {
    await supabase.auth.signOut();
    if (context.mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const AuthScreen()));
    }
  }

  @override
  void initState() {
    super.initState();

    _pages = const [
      UsersTab(),
      ServicesTab(),
      ChatMonitorTab(),
      ComplaintsTab(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final navBarColor = ElevationOverlay.applySurfaceTint(
      colorScheme.surface,
      colorScheme.surfaceTint,
      3,
    );

    return Scaffold(
      backgroundColor: colorScheme.background,
      extendBody: true,

      appBar: AppBar(
        title: Text(
          'Админ-панель',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: colorScheme.outlineVariant.withOpacity(0.6),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Выйти',
            onPressed: () => _logout(context),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 340),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: KeyedSubtree(
          key: ValueKey<int>(_selectedIndex),
          child: _pages[_selectedIndex],
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.28),
                  blurRadius: 36,
                  spreadRadius: 10,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.14),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
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
                indicatorColor: colorScheme.primary.withOpacity(0.20),
                height: 78,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.people_outline_rounded),
                    selectedIcon: Icon(Icons.people_rounded),
                    label: 'Пользователи',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.work_outline_rounded),
                    selectedIcon: Icon(Icons.work_rounded),
                    label: 'Услуги',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.chat_bubble_outline_rounded),
                    selectedIcon: Icon(Icons.chat_bubble_rounded),
                    label: 'Чаты',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.flag_outlined),
                    selectedIcon: Icon(Icons.flag),
                    label: 'Жалобы',
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
