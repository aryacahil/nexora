import 'package:flutter/material.dart';
import '../core/colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
          'Tentang Aplikasi',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Logo & nama app
          Center(
            child: Column(
              children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Image.asset('assets/icons/void.png', fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'MARGA VOID',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: AppColors.primary,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Versi 1.0.0',
                  style: TextStyle(fontSize: 12, color: AppColors.textDim),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Info section
          _buildSection(
            icon: Icons.info_outline,
            color: Colors.purple,
            title: 'Tentang Marga Void',
            content: 'Marga Void adalah jaringan eksklusif komunitas gaming yang menghubungkan para gamer untuk berbagi, berdiskusi, dan bermain bersama.',
          ),
          const SizedBox(height: 16),
          _buildSection(
            icon: Icons.shield_outlined,
            color: Colors.blue,
            title: 'Misi Kami',
            content: 'Membangun komunitas gaming yang solid, positif, dan saling mendukung satu sama lain dalam dunia gaming.',
          ),
          const SizedBox(height: 16),
          _buildSection(
            icon: Icons.code,
            color: Colors.green,
            title: 'Teknologi',
            content: 'Dibangun dengan Flutter & Firebase untuk pengalaman yang cepat, aman, dan realtime.',
          ),
          const SizedBox(height: 40),

          // Versi & info teknis
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _buildInfoRow('Versi Aplikasi', '1.0.0'),
                Divider(color: AppColors.border, height: 24),
                _buildInfoRow('Platform', 'Android'),
                Divider(color: AppColors.border, height: 24),
                _buildInfoRow('Developer', 'aryacahil'),
                Divider(color: AppColors.border, height: 24),
                _buildInfoRow('Kontak', 'margavoid@gmail.com'),
              ],
            ),
          ),
          const SizedBox(height: 40),

          Center(
            child: Text(
              '© 2024 Marga Void. All rights reserved.',
              style: TextStyle(fontSize: 11, color: AppColors.textDim),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required MaterialColor color,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color.shade600, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textMain),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: TextStyle(fontSize: 12, color: AppColors.textDim, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: AppColors.textDim),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMain),
        ),
      ],
    );
  }
}