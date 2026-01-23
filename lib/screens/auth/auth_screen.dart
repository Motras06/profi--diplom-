// lib/screens/auth/auth_screen.dart
import 'package:flutter/material.dart';
import 'login_tab.dart';
import 'register_tab.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Верхняя часть с заголовком и подзаголовком (Material 3 стиль)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Анимированный fade-in заголовок
                  AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    child: Text(
                      'ProWirkSearch',
                      style: textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    child: Text(
                      'Войдите или зарегистрируйтесь, чтобы найти исполнителя или работу',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // TabBar в стиле Material 3 — primary indicator, rounded
            TabBar(
              controller: _tabController,
              isScrollable: false,
              dividerColor: Colors.transparent,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(
                  color: colorScheme.primary,
                  width: 3.0,
                ),
                insets: const EdgeInsets.symmetric(horizontal: 24),
              ),
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              labelStyle: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: textTheme.titleMedium,
              tabs: const [
                Tab(text: 'Вход'),
                Tab(text: 'Регистрация'),
              ],
            ),

            // TabBarView с анимацией перехода (fade + slight slide)
            Expanded(
  child: TabBarView(
    controller: _tabController,
    children: const [
      LoginTab(),
      RegisterTab(),
    ],
  ),
),

            // Нижняя часть — ссылка на гостевой режим (если нужно вернуть позже)
            // Пока убрана по вашему запросу
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}