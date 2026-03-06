import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/colors.dart';

class MemberDetail extends StatelessWidget {
  final Map<String, dynamic> memberData;
  const MemberDetail({super.key, required this.memberData});

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

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Owner': return Colors.orange.shade600;
      case 'Admin': return Colors.purple.shade600;
      case 'Member Senior': return Colors.blue.shade600;
      default: return Colors.grey.shade600;
    }
  }

  MaterialColor _getRoleMaterialColor(String role) {
    switch (role) {
      case 'Owner': return Colors.orange;
      case 'Admin': return Colors.purple;
      case 'Member Senior': return Colors.blue;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = memberData['name'] ?? 'Anggota';
    final bio = memberData['bio'] ?? '';
    final role = memberData['role'] ?? 'Member';
    final hobi = memberData['hobi'] ?? '';
    final asal = memberData['asal'] ?? '';
    final instagram = memberData['instagram'] ?? '';
    final tiktok = memberData['tiktok'] ?? '';
    final photo = memberData['photoBase64'] ?? '';
    final createdAt = memberData['createdAt'];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: AppColors.accent, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Profil Anggota', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Avatar & nama
          Center(
            child: Column(
              children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)]),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [BoxShadow(color: Colors.purple.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  padding: const EdgeInsets.all(3),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(29),
                    child: photo.isNotEmpty
                        ? Image.memory(base64Decode(photo), fit: BoxFit.cover)
                        : Container(
                            color: Colors.purple.shade100,
                            child: const Icon(Icons.person, size: 50, color: Colors.purple),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textMain)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: _getRoleMaterialColor(role).shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getRoleMaterialColor(role).shade200),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2, color: _getRoleColor(role)),
                  ),
                ),
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(bio, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.textDim, height: 1.5)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Info card
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
        ],
      ),
    );
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
}