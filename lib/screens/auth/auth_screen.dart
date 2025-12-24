// lib/screens/auth/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:profi/screens/user/user_home.dart';
import 'login_tab.dart';
import 'register_tab.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _goToGuestHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const UserHome(displayName: 'Гость')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
              child: Text(
                'Найди Мастера',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: colorScheme.primary),
              ),
            ),

            TabBar(
              controller: _tabController,
              labelColor: colorScheme.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: colorScheme.primary,
              tabs: const [Tab(text: 'Вход'), Tab(text: 'Регистрация')],
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  LoginTab(),
                  RegisterTab(),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: OutlinedButton(
                onPressed: _goToGuestHome,
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                child: const Text('Войти без регистрации'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}