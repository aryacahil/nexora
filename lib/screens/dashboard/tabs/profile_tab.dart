import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/colors.dart';
import '../../../core/theme_provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';
import '../../login_screen.dart';
import '../../edit_profile_screen.dart';
import '../../notification_settings_screen.dart';
import '../../dark_mode_settings_screen.dart';
import '../../about_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
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

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '-';
    try {
      final dt = (timestamp as Timestamp).toDate();
      const months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      return '${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userService = UserService();

    return StreamBuilder(
      stream: userService.myProfileStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final name = data['name'] ?? 'Anggota Void';
        final bio = data['bio'] ?? '';
        final role = data['role'] ?? 'Member';
        final hobi = data['hobi'] ?? '';
        final asal = data['asal'] ?? '';
        final instagram = data['instagram'] ?? '';
        final tiktok = data['tiktok'] ?? '';
        final photoBase64 = data['photoBase64'] ?? '';
        final email = FirebaseAuth.instance.currentUser?.email ?? '';
        final createdAt = data['createdAt'];

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 120),
          children: [
            Text(
              'Profil Saya.',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: AppColors.primary),
            ),
            const SizedBox(height: 32),

            // Avatar
            Center(
              child: Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)]),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [BoxShadow(color: Colors.purple.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                padding: const EdgeInsets.all(3),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(37),
                  child: photoBase64.isNotEmpty
                      ? Image.memory(base64Decode(photoBase64), fit: BoxFit.cover)
                      : Container(
                          color: Colors.purple.shade100,
                          child: const Icon(Icons.person, size: 60, color: Colors.purple),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Nama & Role
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textMain)),
                      const SizedBox(width: 8),
                      const Icon(Icons.verified, color: Colors.blue, size: 24),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getRoleColor(role).shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _getRoleColor(role).shade200),
                    ),
                    child: Text(
                      role.toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2, color: _getRoleColor(role).shade700),
                    ),
                  ),
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(bio, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.textDim)),
                  ],
                  const SizedBox(height: 4),
                  Text(email, style: TextStyle(fontSize: 11, color: AppColors.textDim)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  if (hobi.isNotEmpty) ...[
                    _buildInfoRow(Icons.sports_esports, 'Hobi', hobi, Colors.purple),
                    Divider(color: AppColors.border, height: 24),
                  ],
                  if (asal.isNotEmpty) ...[
                    _buildInfoRow(Icons.location_on_outlined, 'Asal', asal, Colors.blue),
                    Divider(color: AppColors.border, height: 24),
                  ],
                  _buildInfoRow(Icons.calendar_today_outlined, 'Tergabung', _formatDate(createdAt), Colors.green),
                ],
              ),
            ),

            // Sosmed
            if (instagram.isNotEmpty || tiktok.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SOSIAL MEDIA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.textDim)),
                    const SizedBox(height: 16),
                    if (instagram.isNotEmpty) ...[
                      _buildSosmedRow(
                        icon: Icons.camera_alt_outlined,
                        color: Colors.pink,
                        platform: 'Instagram',
                        username: '@$instagram',
                      ),
                      if (tiktok.isNotEmpty) Divider(color: AppColors.border, height: 20),
                    ],
                    if (tiktok.isNotEmpty)
                      _buildSosmedRow(
                        icon: Icons.music_note,
                        color: Colors.black87,
                        platform: 'TikTok',
                        username: '@$tiktok',
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Tombol Edit Profil
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditProfileScreen(profileData: data)),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.accent),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  'EDIT PROFIL',
                  style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 40),

            Text('PENGATURAN AKUN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.textDim)),
            const SizedBox(height: 16),

            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsScreen())),
              child: _buildSettingItem(Icons.notifications, 'Notifikasi & Pengingat', Colors.blue),
            ),
            const SizedBox(height: 12),

            GestureDetector(
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const DarkModeSettingsScreen()));
                if (mounted) setState(() {});
              },
              child: _buildSettingItem(
                _themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                'Tampilan',
                Colors.indigo,
              ),
            ),
            const SizedBox(height: 12),

            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
              child: _buildSettingItem(Icons.info_outline, 'Tentang Aplikasi', Colors.purple),
            ),
            const SizedBox(height: 40),

            // Logout
            GestureDetector(
              onTap: () async {
                await AuthService().logout();
                if (context.mounted) {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                }
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text('KELUAR AKUN', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 3)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  MaterialColor _getRoleColor(String role) {
    switch (role) {
      case 'Owner': return Colors.orange;
      case 'Admin': return Colors.purple;
      case 'Member Senior': return Colors.blue;
      default: return Colors.grey;
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value, MaterialColor color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 16, color: color.shade600),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: AppColors.textDim, fontWeight: FontWeight.bold, letterSpacing: 1)),
            Text(value, style: TextStyle(fontSize: 13, color: AppColors.textMain, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _buildSosmedRow({
    required IconData icon,
    required Color color,
    required String platform,
    required String username,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(platform, style: TextStyle(fontSize: 10, color: AppColors.textDim, fontWeight: FontWeight.bold, letterSpacing: 1)),
            Text(username, style: TextStyle(fontSize: 13, color: AppColors.textMain, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingItem(IconData icon, String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 20, color: color.shade600),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDim, letterSpacing: 1),
            ),
          ),
          Icon(Icons.chevron_right, size: 20, color: AppColors.border),
        ],
      ),
    );
  }
}