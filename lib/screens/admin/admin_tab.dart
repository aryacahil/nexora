import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../services/admin_service.dart';
import 'sections/admin_users.dart';
import 'sections/admin_rules.dart';
import 'sections/admin_channels.dart';
import 'sections/admin_announcements.dart';
import 'sections/admin_feedbacks.dart';
import 'sections/admin_donations.dart';

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
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (!_canAccess) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 48, color: AppColors.textDim),
            const SizedBox(height: 16),
            Text('Akses Ditolak',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textMain)),
            const SizedBox(height: 8),
            Text('Kamu tidak punya akses admin.',
                style: TextStyle(color: AppColors.textDim)),
          ],
        ),
      );
    }

    final menus = [
      _AdminMenu(
        icon: Icons.people_alt_rounded,
        label: 'Kelola User',
        desc: _isOwner
            ? 'Lihat, edit role, hapus anggota'
            : 'Lihat dan edit role Member',
        color: Colors.purple,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => AdminUsers(isOwner: _isOwner)),
        ),
      ),
      _AdminMenu(
        icon: Icons.menu_book_rounded,
        label: 'Kelola Panduan',
        desc: 'Tambah, edit, hapus panduan & rules',
        color: Colors.blue,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminRules()),
        ),
      ),
      _AdminMenu(
        icon: Icons.tag_rounded,
        label: 'Kelola Channel',
        desc: 'Tambah, edit, hapus channel diskusi',
        color: Colors.green,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminChannels()),
        ),
      ),
      _AdminMenu(
        icon: Icons.campaign_rounded,
        label: 'Pengumuman',
        desc: 'Buat dan kelola pengumuman resmi',
        color: Colors.orange,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminAnnouncements()),
        ),
      ),
      _AdminMenu(
        icon: Icons.inbox_rounded,
        label: 'Saran & Laporan',
        desc: 'Lihat dan kelola saran dari anggota',
        color: Colors.teal,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminFeedbacks()),
        ),
      ),
      _AdminMenu(
        icon: Icons.volunteer_activism_rounded,
        label: 'Kelola Donasi',
        desc: 'Tambah, edit, hapus info donasi',
        color: Colors.pink,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminDonations()),
        ),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 120),
      children: [
        // ── Header ────────────────────────────────────
        Text(
          'Admin Panel.',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _isOwner ? Colors.orange.shade50 : Colors.purple.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isOwner
                  ? Colors.orange.shade200
                  : Colors.purple.shade200,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isOwner ? Icons.star_rounded : Icons.shield_rounded,
                size: 12,
                color: _isOwner
                    ? Colors.orange.shade600
                    : Colors.purple.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                _isOwner
                    ? 'Owner — Akses penuh'
                    : 'Admin — Akses terbatas',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _isOwner
                      ? Colors.orange.shade700
                      : Colors.purple.shade700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // ── Grid Menu ─────────────────────────────────
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.05,
          ),
          itemCount: menus.length,
          itemBuilder: (context, index) {
            final m = menus[index];
            return GestureDetector(
              onTap: m.onTap,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: m.color.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(m.icon,
                          color: m.color.shade600, size: 26),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textMain,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m.desc,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textDim,
                              height: 1.4),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AdminMenu {
  final IconData icon;
  final String label;
  final String desc;
  final MaterialColor color;
  final VoidCallback onTap;

  const _AdminMenu({
    required this.icon,
    required this.label,
    required this.desc,
    required this.color,
    required this.onTap,
  });
}