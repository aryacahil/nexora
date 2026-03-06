import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../core/theme_provider.dart';

class DarkModeSettingsScreen extends StatefulWidget {
  const DarkModeSettingsScreen({super.key});

  @override
  State<DarkModeSettingsScreen> createState() => _DarkModeSettingsScreenState();
}

class _DarkModeSettingsScreenState extends State<DarkModeSettingsScreen> {
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
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: AppColors.accent, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tampilan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Preview card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Icon(
                  _themeProvider.isDarkMode
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  color: Colors.white,
                  size: 40,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _themeProvider.isDarkMode
                          ? 'Mode Gelap Aktif'
                          : 'Mode Terang Aktif',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _themeProvider.isDarkMode
                          ? 'Tampilan gelap untuk mata'
                          : 'Tampilan terang default',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Toggle tile
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.dark_mode,
                    color: Colors.indigo.shade600,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mode Gelap',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Aktifkan tampilan gelap',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textDim,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _themeProvider.isDarkMode,
                  onChanged: (val) async {
                    await _themeProvider.toggleDarkMode(val);
                  },
                  activeTrackColor: AppColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Info box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.indigo.shade100),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.indigo.shade400, size: 18),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Pengaturan tema tersimpan otomatis dan akan tetap aktif saat kamu login kembali.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}