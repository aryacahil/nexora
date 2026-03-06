import 'package:flutter/material.dart';
import '../../../core/colors.dart';
import '../../../services/admin_service.dart';

class AdminUsers extends StatefulWidget {
  final bool isOwner;
  const AdminUsers({super.key, required this.isOwner});

  @override
  State<AdminUsers> createState() => _AdminUsersState();
}

class _AdminUsersState extends State<AdminUsers> {
  String _search = '';
  String _filterRole = 'Semua';

  final List<String> _roleFilters = [
    'Semua', 'Owner', 'Admin', 'Member Senior', 'Member'
  ];

  @override
  Widget build(BuildContext context) {
    final adminService = AdminService();
    final availableRoles = widget.isOwner
        ? ['Member', 'Member Senior', 'Admin', 'Owner']
        : ['Member', 'Member Senior'];

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
          'Kelola User',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.primary),
        ),
      ),
      body: Column(
        children: [
          // ── Search & Filter ──────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            decoration: BoxDecoration(
              color: AppColors.bg,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _search = val),
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau email...',
                    hintStyle:
                        TextStyle(color: AppColors.textDim, fontSize: 13),
                    prefixIcon:
                        Icon(Icons.search, color: AppColors.textDim, size: 20),
                    filled: true,
                    fillColor: AppColors.card,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _roleFilters.map((role) {
                      final isActive = _filterRole == role;
                      return GestureDetector(
                        onTap: () => setState(() => _filterRole = role),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isActive
                                ? _getRoleColor(role)
                                : AppColors.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isActive
                                  ? _getRoleColor(role)
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            role,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color:
                                  isActive ? Colors.white : AppColors.textDim,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // ── List User ────────────────────────────────
          Expanded(
            child: StreamBuilder(
              stream: adminService.getAllUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text('Belum ada user.',
                        style: TextStyle(color: AppColors.textDim)),
                  );
                }

                final users = snapshot.data!.docs.where((doc) {
                  final u = doc.data() as Map<String, dynamic>;
                  final name = (u['name'] ?? '').toString().toLowerCase();
                  final email = (u['email'] ?? '').toString().toLowerCase();
                  final role = u['role'] ?? 'Member';
                  final matchSearch = _search.isEmpty ||
                      name.contains(_search.toLowerCase()) ||
                      email.contains(_search.toLowerCase());
                  final matchRole =
                      _filterRole == 'Semua' || role == _filterRole;
                  return matchSearch && matchRole;
                }).toList();

                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search,
                            size: 48, color: Colors.purple.shade100),
                        const SizedBox(height: 12),
                        Text('Tidak ada user ditemukan.',
                            style: TextStyle(color: AppColors.textDim)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final u = users[index].data() as Map<String, dynamic>;
                    final uid = users[index].id;
                    final name = u['name'] ?? 'Anggota';
                    final email = u['email'] ?? '';
                    final role = u['role'] ?? 'Member';

                    final bool canEditThisUser = widget.isOwner
                        ? true
                        : (role != 'Owner' && role != 'Admin');

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          // Avatar inisial
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF8B5CF6),
                                  Color(0xFFD946EF),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                name.isNotEmpty
                                    ? name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Info + dropdown
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.textMain,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getRoleMaterialColor(role)
                                            .shade50,
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        border: Border.all(
                                          color: _getRoleMaterialColor(role)
                                              .shade200,
                                        ),
                                      ),
                                      child: Text(
                                        role,
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: _getRoleMaterialColor(role)
                                              .shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  email,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textDim),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (canEditThisUser) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 36,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.bg,
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      border:
                                          Border.all(color: AppColors.border),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: availableRoles.contains(role)
                                            ? role
                                            : availableRoles.first,
                                        isExpanded: true,
                                        icon: Icon(Icons.expand_more,
                                            color: AppColors.textDim,
                                            size: 18),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textMain,
                                        ),
                                        items: availableRoles
                                            .map((r) => DropdownMenuItem(
                                                  value: r,
                                                  child: Text(r),
                                                ))
                                            .toList(),
                                        onChanged: (newRole) async {
                                          if (newRole != null) {
                                            try {
                                              await adminService
                                                  .updateUserRole(uid, newRole);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(SnackBar(
                                                  content: Text(
                                                      'Role $name → $newRole'),
                                                  backgroundColor: Colors.green,
                                                ));
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(SnackBar(
                                                  content: Text('$e'),
                                                  backgroundColor: Colors.red,
                                                ));
                                              }
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Role tidak dapat diubah',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textDim,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Hapus (owner only)
                          if (widget.isOwner) ...[
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red, size: 20),
                              onPressed: () => _confirmDelete(
                                  context, adminService, uid, name),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Owner':
        return Colors.orange.shade500;
      case 'Admin':
        return Colors.purple.shade500;
      case 'Member Senior':
        return Colors.blue.shade500;
      default:
        return Colors.grey.shade400;
    }
  }

  MaterialColor _getRoleMaterialColor(String role) {
    switch (role) {
      case 'Owner':
        return Colors.orange;
      case 'Admin':
        return Colors.purple;
      case 'Member Senior':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _confirmDelete(BuildContext context, AdminService adminService,
      String uid, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus User',
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hapus data "$name" dari Firestore?',
                style: TextStyle(color: AppColors.textDim)),
            const SizedBox(height: 8),
            const Text(
              '⚠️ Akun login tidak ikut terhapus, hanya data profil.',
              style: TextStyle(fontSize: 11, color: Colors.orange),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Batal', style: TextStyle(color: AppColors.textDim)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await adminService.deleteUser(uid);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Data user berhasil dihapus.'),
                        backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Gagal: $e'),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Hapus',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}