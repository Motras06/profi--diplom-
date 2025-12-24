import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'theme/app_theme.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/user/user_home.dart';
import 'screens/specialist/specialist_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Загрузка .env
  await dotenv.load(fileName: ".env");

  // Инициализация Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const MainApp(),
    ),
  );
}

final supabase = Supabase.instance.client;

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  // Получаем домашний экран в зависимости от роли
  Future<Widget> _getStartingScreen() async {
    final currentUser = supabase.auth.currentUser;

    if (currentUser == null) {
      return const AuthScreen();
    }

    try {
      final profile = await supabase
          .from('profiles')
          .select('role, display_name')
          .eq('id', currentUser.id)
          .single();

      final role = profile['role'] as String;
      final name = profile['display_name'] as String? ?? 'Пользователь';

      if (role == 'specialist') {
        return SpecialistHome(displayName: name);
      } else {
        return UserHome(displayName: name);
      }
    } catch (e) {
      // Если профиля нет или ошибка — на авторизацию
      return const AuthScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Найди Мастера',
      debugShowCheckedModeBanner: false,

      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,

      theme: AppTheme.lightTheme,

      home: FutureBuilder<Widget>(
        future: _getStartingScreen(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return snapshot.data!;
          } else if (snapshot.hasError) {
            return const AuthScreen(); // На всякий случай
          }

          // Пока грузим профиль — сплеш/лоадер
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 24),
                  Text('Загрузка...', style: TextStyle(fontSize: 18)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}