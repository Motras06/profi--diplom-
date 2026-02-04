// lib/main.dart
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:profi/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'theme/app_theme.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/user/user_home.dart';
import 'screens/specialist/specialist_home.dart';
import 'screens/admin/admin_home.dart'; // ← добавьте этот импорт

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
        child: const MainApp(),
      ),
    ),
  );
}

final supabase = Supabase.instance.client;

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  Future<Widget> _getStartingScreen() async {
    final currentUser = supabase.auth.currentUser;

    if (currentUser == null) {
      return const AuthScreen();
    }

    try {
      final response = await supabase
          .from('profiles')
          .select('role, display_name')
          .eq('id', currentUser.id)
          .single();

      final String role = (response['role'] as String?) ?? 'user';
      final String displayName = (response['display_name'] as String?) ?? 'Пользователь';

      switch (role) {
        case 'admin':
          return AdminHome(displayName: displayName);
        case 'specialist':
          return SpecialistHome(displayName: displayName);
        default:
          return UserHome(displayName: displayName);
      }
    } catch (e) {
      // Если профиль не найден или ошибка → кидаем на авторизацию
      // Можно добавить print(e) или Sentry/Log для отладки
      return const AuthScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'ProWirkSearch',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,

      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,

      home: FutureBuilder<Widget>(
        future: _getStartingScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            return snapshot.data!;
          }

          // Ошибка или null → авторизация
          return const AuthScreen();
        },
      ),
    );
  }
}