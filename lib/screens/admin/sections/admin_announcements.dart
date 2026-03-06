import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/colors.dart';
import '../../../services/admin_service.dart';
import '../../../services/notification_service.dart';

class AdminAnnouncements extends StatelessWidget {
  const AdminAnnouncements({super.key});

  @override
  Widget build(BuildContext context) {
    final adminService = AdminService();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: AppColors.accent, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Kelola Pengumuman', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showFormDialog(context, adminService),
      ),
      body: StreamBuilder(
        stream: adminService.getAnnouncements(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.campaign_outlined, size: 48, color: Colors.purple.shade100),
                  const SizedBox(height: 12),
                  Text(
                    'Belum ada pengumuman.\nTambahkan dengan tombol +',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textDim, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          final announcements = snapshot.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
            itemCount: announcements.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final a = announcements[index].data() as Map<String, dynamic>;
              final id = announcements[index].id;
              final createdAt = a['createdAt'];
              String dateStr = '';
              if (createdAt != null) {
                final dt = (createdAt as Timestamp).toDate();
                dateStr = '${dt.day}/${dt.month}/${dt.year}';
              }

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.campaign, color: Colors.orange.shade600, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a['title'] ?? '',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textMain),
                              ),
                              if (dateStr.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(dateStr, style: TextStyle(fontSize: 10, color: AppColors.textDim)),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.edit_outlined, color: AppColors.accent, size: 20),
                          onPressed: () => _showFormDialog(
                            context, adminService,
                            id: id,
                            title: a['title'],
                            content: a['content'],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () => _confirmDelete(context, adminService, id, a['title'] ?? ''),
                        ),
                      ],
                    ),
                    if ((a['content'] ?? '').isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Divider(color: AppColors.border, height: 1),
                      const SizedBox(height: 12),
                      Text(
                        a['content'] ?? '',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: AppColors.textDim, height: 1.5),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showFormDialog(
    BuildContext context,
    AdminService adminService, {
    String? id,
    String? title,
    String? content,
  }) {
    final titleCtrl = TextEditingController(text: title ?? '');
    final contentCtrl = TextEditingController(text: content ?? '');
    final isEdit = id != null;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isEdit ? 'Edit Pengumuman' : 'Buat Pengumuman',
          style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField(titleCtrl, 'Judul pengumuman'),
              const SizedBox(height: 12),
              _buildDialogField(contentCtrl, 'Isi pengumuman...', maxLines: 5),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: AppColors.textDim)),
          ),
          TextButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              final titleText = titleCtrl.text.trim();
              final contentText = contentCtrl.text.trim();
              Navigator.pop(context);

              if (isEdit) {
                await adminService.updateAnnouncement(id, titleText, contentText);
              } else {
                // Simpan ke Firestore
                await adminService.createAnnouncement(titleText, contentText);

                // Kirim notifikasi
                print('🔔 Memanggil sendAnnouncementNotification...');
                try {
                  await NotificationService.instance.sendAnnouncementNotification(
                    titleText,
                    contentText,
                  );
                  print('✅ sendAnnouncementNotification selesai');
                } catch (e) {
                  print('❌ Error notifikasi: $e');
                }
              }
            },
            child: Text(
              isEdit ? 'Simpan' : 'Buat',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    AdminService adminService,
    String id,
    String title,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Pengumuman', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text(
          'Hapus pengumuman "$title"? Data tidak bisa dikembalikan.',
          style: TextStyle(color: AppColors.textDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: AppColors.textDim)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await adminService.deleteAnnouncement(id);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textDim, fontSize: 13),
        filled: true,
        fillColor: AppColors.bg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.accent, width: 2),
        ),
      ),
    );
  }
}