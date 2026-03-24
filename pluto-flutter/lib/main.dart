import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/cache_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(
    ProviderScope(
      overrides: [
        cacheServiceProvider.overrideWithValue(CacheService(prefs)),
      ],
      child: const PlutoApp(),
    ),
  );
}

class PlutoApp extends ConsumerWidget {
  const PlutoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Pluto',
      debugShowCheckedModeBanner: false,
      theme: PlutoTheme.light(),
      darkTheme: PlutoTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
