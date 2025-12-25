// lib/screens/specialist/specialist_home.dart
import 'package:flutter/material.dart';
import 'package:profi/screens/auth/auth_screen.dart';
import 'package:profi/screens/specialist/services_tab.dart';
import 'package:profi/screens/specialist/chat_tab.dart';
import 'package:profi/screens/specialist/profile_tab.dart';
import 'package:profi/screens/specialist/orders_tab.dart';
import '../../services/supabase_service.dart';

class SpecialistHome extends StatefulWidget {
  final String displayName;

  const SpecialistHome({super.key, required this.displayName});

  @override
  State<SpecialistHome> createState() => _SpecialistHomeState();
}

class _SpecialistHomeState extends State<SpecialistHome> {
  int _selectedIndex = 0;

  Future<void> _logout(BuildContext context) async {
    await supabase.auth.signOut();
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  // Список отдельных экранов
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      ServicesTab(displayName: widget.displayName),
      const ChatTab(),
      ProfileTab(displayName: widget.displayName),
      const OrdersTab(),
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
        title: const Text('Найди Мастера'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Выйти',
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Услуги'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Чаты'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Заказы'),
        ],
      ),
    );
  }
}