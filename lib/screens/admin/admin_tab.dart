import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../services/admin_service.dart';
import 'sections/admin_users.dart';
import 'sections/admin_rules.dart';
import 'sections/admin_channels.dart';
import 'sections/admin_announcements.dart';

class AdminTab extends StatefulWidget {
  const AdminTab({super.key});

  @override
  State<AdminTab> createState() => _AdminTabState();
}

class _AdminTabState extends State<AdminTab> {
  final AdminService _adminService = AdminService();
  bool _canAccess = false;
  bool _isOwner = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    await _adminService.loadRole();
    if (mounted) {
      setState(() {
        _canAccess = _adminService.isAdminOrOwner;
        _isOwner = _adminService.isOwnerCached;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (!_canAccess) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 48, color: AppColors.textDim),
            const SizedBox(height: 16),
            Text('Akses Ditolak', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textMain)),
            const SizedBox(height: 8),
            Text('Kamu tidak punya akses admin.', style: TextStyle(color: AppColors.textDim)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 120),
      children: [
        Text('Admin Panel.', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: AppColors.primary)),
        const SizedBox(height: 4),
        Text(
          _isOwner ? 'Owner — Akses penuh' : 'Admin — Akses terbatas',
          style: TextStyle(fontSize: 12, color: AppColors.textDim),
        ),
        const SizedBox(height: 32),

        _buildMenuCard(
          context,
          icon: Icons.people,
          label: 'Kelola User',
          desc: _isOwner ? 'Lihat, edit role, hapus anggota' : 'Lihat dan edit role Member',
          color: Colors.purple,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminUsers(isOwner: _isOwner))),
        ),
        const SizedBox(height: 16),
        _buildMenuCard(
          context,
          icon: Icons.menu_book,
          label: 'Kelola Panduan',
          desc: 'Tambah, edit, hapus panduan & rules',
          color: Colors.blue,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminRules())),
        ),
        const SizedBox(height: 16),
        _buildMenuCard(
          context,
          icon: Icons.tag,
          label: 'Kelola Channel',
          desc: 'Tambah, edit, hapus channel diskusi',
          color: Colors.green,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminChannels())),
        ),
        const SizedBox(height: 16),
        _buildMenuCard(
          context,
          icon: Icons.campaign,
          label: 'Kelola Pengumuman',
          desc: 'Buat dan kelola pengumuman resmi',
          color: Colors.orange,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAnnouncements())),
        ),
      ],
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String desc,
    required MaterialColor color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color.shade600, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textMain)),
                  const SizedBox(height: 4),
                  Text(desc, style: TextStyle(fontSize: 12, color: AppColors.textDim)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.border),
          ],
        ),
      ),
    );
  }
}