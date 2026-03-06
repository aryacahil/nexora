import 'package:flutter/material.dart';
import '../../../core/colors.dart';
import '../../../services/admin_service.dart';

class AdminUsers extends StatelessWidget {
  final bool isOwner;
  const AdminUsers({super.key, required this.isOwner});

  @override
  Widget build(BuildContext context) {
    final adminService = AdminService();

    // Role yang bisa dipilih berdasarkan level
    final roles = isOwner
        ? ['Member', 'Member Senior', 'Admin', 'Owner']
        : ['Member', 'Member Senior']; // Admin hanya bisa set role bawah

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: AppColors.accent, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Kelola User', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary)),
      ),
      body: StreamBuilder(
        stream: adminService.getAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('Belum ada user.', style: TextStyle(color: AppColors.textDim)),
            );
          }

          final users = snapshot.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final u = users[index].data() as Map<String, dynamic>;
              final uid = users[index].id;
              final name = u['name'] ?? 'Anggota';
              final email = u['email'] ?? '';
              final role = u['role'] ?? 'Member';

              // Tentukan apakah role user ini bisa diubah
              final bool canEditThisUser = isOwner
                  ? true // Owner bisa edit semua
                  : (role != 'Owner' && role != 'Admin'); // Admin tidak bisa edit Owner/Admin lain

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
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)]),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.person, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textMain)),
                              Text(email, style: TextStyle(fontSize: 11, color: AppColors.textDim)),
                            ],
                          ),
                        ),
                        // Badge role
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getRoleColor(role).shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _getRoleColor(role).shade200),
                          ),
                          child: Text(
                            role,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getRoleColor(role).shade700),
                          ),
                        ),
                        if (isOwner) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () => _confirmDelete(context, adminService, uid, name),
                          ),
                        ],
                      ],
                    ),
                    if (canEditThisUser) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: roles.contains(role) ? role : roles.first,
                            isExpanded: true,
                            icon: Icon(Icons.expand_more, color: AppColors.textDim),
                            items: roles.map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(r, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            )).toList(),
                            onChanged: (newRole) async {
                              if (newRole != null) {
                                try {
                                  await adminService.updateUserRole(uid, newRole);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Role $name diubah ke $newRole'), backgroundColor: Colors.green),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('$e'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      Text(
                        'Role tidak dapat diubah',
                        style: TextStyle(fontSize: 11, color: AppColors.textDim, fontStyle: FontStyle.italic),
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

  MaterialColor _getRoleColor(String role) {
    switch (role) {
      case 'Owner': return Colors.orange;
      case 'Admin': return Colors.purple;
      case 'Member Senior': return Colors.blue;
      default: return Colors.grey;
    }
  }

  void _confirmDelete(BuildContext context, AdminService adminService, String uid, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus User', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hapus data "$name" dari Firestore?', style: TextStyle(color: AppColors.textDim)),
            const SizedBox(height: 8),
            const Text('⚠️ Akun login tidak ikut terhapus, hanya data profil.', style: TextStyle(fontSize: 11, color: Colors.orange)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: AppColors.textDim)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await adminService.deleteUser(uid);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data user berhasil dihapus.'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}