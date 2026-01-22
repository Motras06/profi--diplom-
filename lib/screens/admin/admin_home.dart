// lib/screens/admin/admin_home.dart
import 'package:flutter/material.dart';
import 'package:profi/services/supabase_service.dart';
import 'package:profi/screens/admin/tabs/users_tab.dart';
import 'package:profi/screens/admin/tabs/specialists_tab.dart';
import 'package:profi/screens/admin/tabs/services_tab.dart';
import 'package:profi/screens/admin/tabs/orders_tab.dart';
import 'package:profi/screens/admin/tabs/reviews_tab.dart';
import 'package:profi/screens/admin/tabs/blacklist_tab.dart';
import 'package:profi/screens/admin/tabs/chat_monitor_tab.dart';
import 'package:profi/screens/auth/auth_screen.dart';

class AdminHome extends StatefulWidget {
  final String displayName;

  const AdminHome({
    super.key,
    required this.displayName,
  });

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _selectedIndex = 0;

  Future<void> _logout(BuildContext context) async {
    await supabase.auth.signOut();
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  late final List<Widget> _adminTabs;
  late final List<BottomNavigationBarItem> _navItems;

  @override
  void initState() {
    super.initState();

    _adminTabs = [
      const UsersTab(),           // Пользователи (обычные + специалисты)
      const SpecialistsTab(),     // Специалисты + их профили
      const ServicesTab(),        // Услуги / прайс-лист
      const OrdersTab(),          // Заказы / сделки
      const ReviewsTab(),         // Отзывы и рейтинги
      const BlacklistTab(),       // Чёрный список
      const ChatMonitorTab(),     // Модерация чатов (опционально)
    ];

    _navItems = const [
      BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Пользователи'),
      BottomNavigationBarItem(icon: Icon(Icons.engineering), label: 'Мастера'),
      BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Услуги'),
      BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Заказы'),
      BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Отзывы'),
      BottomNavigationBarItem(icon: Icon(Icons.block), label: 'Блокировка'),
      BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'Чаты'),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Админ-панель'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Выйти',
          ),
        ],
      ),

      body: IndexedStack(
        index: _selectedIndex,
        children: _adminTabs,
      ),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Colors.white,
        elevation: 8,
        items: _navItems,
      ),
    );
  }
}