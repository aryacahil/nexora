import 'package:flutter/material.dart';
import '../../../core/colors.dart';
import '../../../services/admin_service.dart';

class AdminRules extends StatelessWidget {
  const AdminRules({super.key});

  @override
  Widget build(BuildContext context) {
    final adminService = AdminService();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _buildAppBar(context, 'Kelola Panduan'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showFormDialog(context, adminService),
      ),
      body: StreamBuilder(
        stream: adminService.getRules(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmpty('Belum ada panduan.\nTambahkan dengan tombol +');
          }
          final rules = snapshot.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: rules.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final r = rules[index].data() as Map<String, dynamic>;
              final id = rules[index].id;
              return _buildCard(
                title: r['title'] ?? '',
                subtitle: r['content'] ?? '',
                onEdit: () => _showFormDialog(context, adminService, id: id, title: r['title'], content: r['content']),
                onDelete: () => _confirmDelete(context, adminService, id, r['title'] ?? ''),
              );
            },
          );
        },
      ),
    );
  }

  void _showFormDialog(BuildContext context, AdminService adminService, {String? id, String? title, String? content}) {
    final titleCtrl = TextEditingController(text: title ?? '');
    final contentCtrl = TextEditingController(text: content ?? '');
    final isEdit = id != null;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isEdit ? 'Edit Panduan' : 'Tambah Panduan', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogField(titleCtrl, 'Judul'),
            const SizedBox(height: 12),
            _buildDialogField(contentCtrl, 'Isi konten...', maxLines: 4),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Batal', style: TextStyle(color: AppColors.textDim))),
          TextButton(
            onPressed: () async {
              if (titleCtrl.text.isEmpty) return;
              Navigator.pop(context);
              if (isEdit) {
                await adminService.updateRule(id, titleCtrl.text, contentCtrl.text);
              } else {
                await adminService.createRule(titleCtrl.text, contentCtrl.text);
              }
            },
            child: Text(isEdit ? 'Simpan' : 'Tambah', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AdminService adminService, String id, String title) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Panduan', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Hapus "$title"?', style: TextStyle(color: AppColors.textDim)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Batal', style: TextStyle(color: AppColors.textDim))),
          TextButton(
            onPressed: () async { Navigator.pop(context); await adminService.deleteRule(id); },
            child: const Text('Hapus', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

AppBar _buildAppBar(BuildContext context, String title) {
  return AppBar(
    backgroundColor: AppColors.bg,
    elevation: 0,
    leading: IconButton(
      icon: Icon(Icons.chevron_left, color: AppColors.accent, size: 32),
      onPressed: () => Navigator.pop(context),
    ),
    title: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary)),
  );
}

Widget _buildEmpty(String message) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inbox, size: 48, color: Colors.purple.shade100),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center, style: TextStyle(color: AppColors.textDim, fontSize: 13)),
      ],
    ),
  );
}

Widget _buildCard({required String title, required String subtitle, required VoidCallback onEdit, required VoidCallback onDelete}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textMain)),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: AppColors.textDim)),
              ],
            ],
          ),
        ),
        IconButton(icon: Icon(Icons.edit_outlined, color: AppColors.accent, size: 20), onPressed: onEdit),
        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: onDelete),
      ],
    ),
  );
}

Widget _buildDialogField(TextEditingController controller, String hint, {int maxLines = 1}) {
  return TextField(
    controller: controller,
    maxLines: maxLines,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textDim, fontSize: 13),
      filled: true,
      fillColor: AppColors.bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.accent, width: 2)),
    ),
  );
}