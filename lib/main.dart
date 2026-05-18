import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/routing/app_router.dart';
import 'features/games/data/services/hive_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Initialize offline Hive DB and SharedPreferences
  await HiveService.instance.init();
  final prefs = await SharedPreferences.getInstance();
  ThemeNotifier.init(prefs);

  runApp(const ProviderScope(child: GameHubApp()));
}

class GameHubApp extends ConsumerWidget {
  const GameHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeModeSetting = ref.watch(themeProvider);

    ThemeData getThemeData(AppThemeMode mode) {
      switch (mode) {
        case AppThemeMode.light:
          return AppTheme.lightTheme;
        case AppThemeMode.dark:
          return AppTheme.darkTheme;
        case AppThemeMode.cyberpunkNeon:
          return AppTheme.cyberpunkNeonTheme;
        case AppThemeMode.system:
          final brightness = View.of(context).platformDispatcher.platformBrightness;
          return brightness == Brightness.dark
              ? AppTheme.darkTheme
              : AppTheme.lightTheme;
      }
    }

    return MaterialApp.router(
      title: AppConstants.appName,
      theme: getThemeData(themeModeSetting),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
