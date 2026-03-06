import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/app_themes.dart';
import 'core/theme_provider.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MargaVoidApp());
}

class MargaVoidApp extends StatefulWidget {
  const MargaVoidApp({super.key});

  @override
  State<MargaVoidApp> createState() => _MargaVoidAppState();
}

class _MargaVoidAppState extends State<MargaVoidApp> {
  final ThemeProvider _themeProvider = ThemeProvider.instance;

  @override
  void initState() {
    super.initState();
    _themeProvider.addListener(_onThemeChange);
  }

  @override
  void dispose() {
    _themeProvider.removeListener(_onThemeChange);
    super.dispose();
  }

  void _onThemeChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Marga Void',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.light,
      darkTheme: AppThemes.dark,
      themeMode: _themeProvider.isDarkMode
          ? ThemeMode.dark
          : ThemeMode.light,
      home: const LoginScreen(),
    );
  }
}