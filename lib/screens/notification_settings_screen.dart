import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final NotificationService _notifService = NotificationService.instance;
  bool _notifAnnouncements = true;
  bool _notifDiscussion = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _notifService.getNotifSettings();
    setState(() {
      _notifAnnouncements = settings['notif_announcements'] ?? true;
      _notifDiscussion = settings['notif_discussion'] ?? true;
      _isLoading = false;
    });
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
        title: Text('Notifikasi & Pengingat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text('NOTIFIKASI PUSH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.textDim)),
                const SizedBox(height: 16),

                // Notif Pengumuman
                _buildToggleTile(
                  icon: Icons.campaign,
                  iconColor: Colors.purple,
                  title: 'Pengumuman Baru',
                  subtitle: 'Terima notifikasi saat ada pengumuman resmi dari pengurus',
                  value: _notifAnnouncements,
                  onChanged: (val) async {
                    setState(() => _notifAnnouncements = val);
                    if (val) {
                      await _notifService.subscribeAnnouncements();
                    } else {
                      await _notifService.unsubscribeAnnouncements();
                    }
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(val ? 'Notifikasi pengumuman diaktifkan' : 'Notifikasi pengumuman dimatikan'),
                          backgroundColor: val ? Colors.green : Colors.grey,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Notif Diskusi
                _buildToggleTile(
                  icon: Icons.chat_bubble_outline,
                  iconColor: Colors.blue,
                  title: 'Pesan Diskusi Baru',
                  subtitle: 'Terima notifikasi saat ada pesan baru di channel diskusi',
                  value: _notifDiscussion,
                  onChanged: (val) async {
                    setState(() => _notifDiscussion = val);
                    if (val) {
                      await _notifService.subscribeDiscussion();
                    } else {
                      await _notifService.unsubscribeDiscussion();
                    }
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(val ? 'Notifikasi diskusi diaktifkan' : 'Notifikasi diskusi dimatikan'),
                          backgroundColor: val ? Colors.green : Colors.grey,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 40),

                // Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade400, size: 18),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Notifikasi push dikirim langsung ke HP kamu meski aplikasi ditutup. Pastikan izin notifikasi diaktifkan di pengaturan HP.',
                          style: TextStyle(fontSize: 12, color: AppColors.textDim, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required MaterialColor iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
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
              color: iconColor.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor.shade600, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 11, color: AppColors.textDim, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}