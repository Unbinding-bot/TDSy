// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/app_settings.dart';
import 'providers/tds_provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settings = AppSettings();
  await settings.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProxyProvider<AppSettings, TdsProvider>(
          create: (ctx) => TdsProvider(settings),
          update: (ctx, s, prev) => prev ?? TdsProvider(s),
        ),
      ],
      child: const TdsMonitorApp(),
    ),
  );
}

class TdsMonitorApp extends StatelessWidget {
  const TdsMonitorApp({super.key});

  @override
  Widget build(BuildContext ctx) {
    final settings = ctx.watch<AppSettings>();

    return MaterialApp(
      title: 'TDS Monitor',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: buildTheme(settings.themeChoice, Brightness.light),
      darkTheme: buildTheme(settings.themeChoice, Brightness.dark),
      home: const HomeScreen(),
    );
  }
}
