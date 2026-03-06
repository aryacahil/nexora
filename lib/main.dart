import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/app_themes.dart';
import 'core/theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'services/notification_service.dart';

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
  bool _isLoggedIn = false;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _themeProvider.addListener(_onThemeChange);
    _init();
  }

  Future<void> _init() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await ThemeProvider.instance.loadTheme();
      await NotificationService.instance.init();
      if (mounted) setState(() { _isLoggedIn = true; _isReady = true; });
    } else {
      if (mounted) setState(() { _isLoggedIn = false; _isReady = true; });
    }
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
      themeMode: _themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: !_isReady
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
              ),
            )
          : _isLoggedIn
              ? const DashboardScreen()
              : const LoginScreen(),
    );
  }
}