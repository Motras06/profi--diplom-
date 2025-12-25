// lib/screens/auth/user_home.dart
import 'package:flutter/material.dart';
import 'package:profi/screens/auth/auth_screen.dart';
import 'package:profi/screens/user/main_tab.dart';
import 'package:profi/screens/user/saved_tab.dart';
import 'package:profi/screens/user/profile_tab.dart';
import 'package:profi/screens/user/chat_tab.dart';
import '../../services/supabase_service.dart';

class UserHome extends StatefulWidget {
  final String displayName;

  const UserHome({super.key, required this.displayName});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  int _selectedIndex = 0;

  Future<void> _logout(BuildContext context) async {
    await supabase.auth.signOut();
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const MainTab(), // Главная — поиск мастеров
      const SavedTab(), // Сохранённые
      const UserProfileTab(), // Профиль пользователя
      const UserChatTab(), // Чаты
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
          if (widget.displayName != 'Гость')
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Главная'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Сохранённые'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Чаты'),
        ],
      ),
    );
  }
}