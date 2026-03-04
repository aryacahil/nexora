import 'package:flutter/material.dart';
import '../../../core/colors.dart';
import '../../../core/mock_data.dart';
import '../../login_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 120),
      children: [
        const Text('Profil Saya.', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: AppColors.primary)),
        const SizedBox(height: 32),
        
        // Avatar
        Center(
          child: Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)]),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            padding: const EdgeInsets.all(4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: Image.network(MockData.userData['pic']!, fit: BoxFit.cover),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Info User
        Center(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(MockData.userData['name']!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  const SizedBox(width: 8),
                  const Icon(Icons.verified, color: Colors.blue, size: 24),
                ],
              ),
              const SizedBox(height: 4),
              Text('${MockData.userData['role']} • ${MockData.userData['displayName']}'.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2, color: AppColors.textDim)),
            ],
          ),
        ),
        const SizedBox(height: 40),

        // Settings Menu
        const Text('PENGATURAN AKUN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.textDim)),
        const SizedBox(height: 16),
        _buildSettingItem(Icons.security, 'Keamanan Member', Colors.purple),
        const SizedBox(height: 12),
        _buildSettingItem(Icons.notifications, 'Notifikasi & Pengingat', Colors.blue),
        const SizedBox(height: 12),
        _buildSettingItem(Icons.lock, 'Privasi & Visibilitas', Colors.green),
        
        const SizedBox(height: 40),
        GestureDetector(
          onTap: () {
            // Logika Logout
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('KELUAR AKUN', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 3)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildSettingItem(IconData icon, String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 20, color: color.shade600)),
          const SizedBox(width: 16),
          Expanded(child: Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDim, letterSpacing: 1))),
          const Icon(Icons.chevron_right, size: 20, color: AppColors.border),
        ],
      ),
    );
  }
}