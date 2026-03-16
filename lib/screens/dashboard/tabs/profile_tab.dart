import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../../core/colors.dart';
import '../../../core/theme_provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';
import '../../../services/post_service.dart';
import '../../login_screen.dart';
import '../../edit_profile_screen.dart';
import '../../notification_settings_screen.dart';
import '../../dark_mode_settings_screen.dart';
import '../../about_screen.dart';
import '../../profile/post_detail_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab>
    with SingleTickerProviderStateMixin {
  final ThemeProvider _themeProvider = ThemeProvider.instance;
  final PostService   _postService   = PostService();

  // Tab controller: 0 = Info, 1 = Postingan
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _themeProvider.addListener(_onThemeChange);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _themeProvider.removeListener(_onThemeChange);
    super.dispose();
  }

  void _onThemeChange() {
    if (mounted) setState(() {});
  }

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

  // ── Upload foto baru ───────────────────────────────────────────────────────

  Future<void> _showCreatePostSheet(
      String userName, String userPhotoBase64) async {
    final captionCtrl = TextEditingController();
    File? pickedFile;
    String? previewBase64;
    bool isUploading = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (ctx, scrollCtrl) => Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28))),
            child: ListView(
              controller: scrollCtrl,
              padding: EdgeInsets.fromLTRB(
                24, 16, 24,
                MediaQuery.of(ctx).viewInsets.bottom + 32),
              children: [

              // Handle bar
              Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
              )),
              const SizedBox(height: 16),

              // Judul
              Text('Postingan Baru', style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w900,
                color: AppColors.primary)),
              const SizedBox(height: 20),

              // Foto picker — tinggi selalu fixed 200, tidak bisa melar
              GestureDetector(
                onTap: () async {
                  final picked = await ImagePicker().pickImage(
                    source: ImageSource.gallery, imageQuality: 85);
                  if (picked == null) return;

                  final compressed =
                      await FlutterImageCompress.compressWithFile(
                    picked.path, quality: 60, minWidth: 800, minHeight: 800);
                  if (compressed == null) return;

                  if (compressed.length > 900000) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                        content: Text('Foto terlalu besar, pilih yang lebih kecil.'),
                        backgroundColor: Colors.red));
                    }
                    return;
                  }
                  setSheet(() {
                    pickedFile    = File(picked.path);
                    previewBase64 = base64Encode(compressed);
                  });
                },
                child: SizedBox(
                  width: double.infinity,
                  height: 200, // ← fixed height, tidak bisa melar
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(children: [
                      // Background / foto
                      previewBase64 != null
                          ? Image.memory(
                              base64Decode(previewBase64!),
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover) // ← cover, tidak stretch
                          : Container(
                              width: double.infinity,
                              height: 200,
                              decoration: BoxDecoration(
                                color: AppColors.bg,
                                border: Border.all(color: AppColors.border)),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle),
                                    child: Icon(Icons.add_photo_alternate_outlined,
                                      color: AppColors.primary, size: 32)),
                                  const SizedBox(height: 10),
                                  Text('Ketuk untuk pilih foto',
                                    style: TextStyle(fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textMain)),
                                  const SizedBox(height: 4),
                                  Text('Dari galeri',
                                    style: TextStyle(fontSize: 11,
                                      color: AppColors.textDim)),
                                ],
                              ),
                            ),
                      // Border overlay
                      if (previewBase64 != null)
                        Positioned.fill(child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              width: 2),
                            borderRadius: BorderRadius.circular(20)),
                        )),
                      // Edit icon
                      if (previewBase64 != null)
                        Positioned(top: 10, right: 10,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              shape: BoxShape.circle),
                            child: const Icon(Icons.edit,
                              color: Colors.white, size: 14),
                          )),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Caption
              TextField(
                controller: captionCtrl,
                maxLines: 3,
                maxLength: 300,
                decoration: InputDecoration(
                  hintText: 'Tulis caption...',
                  hintStyle: TextStyle(color: AppColors.textDim, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.bg,
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.accent, width: 2)),
                ),
              ),
              const SizedBox(height: 16),

              // Tombol bagikan
              GestureDetector(
                onTap: isUploading || pickedFile == null
                    ? null
                    : () async {
                        setSheet(() => isUploading = true);
                        try {
                          await _postService.createPost(
                            imageFile       : pickedFile!,
                            caption         : captionCtrl.text.trim(),
                            userName        : userName,
                            userPhotoBase64 : userPhotoBase64,
                          );
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Postingan berhasil dibagikan! ✨'),
                                backgroundColor: Colors.green));
                            // Pindah ke tab postingan
                            _tabCtrl.animateTo(1);
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                              content: Text('Gagal: $e'),
                              backgroundColor: Colors.red));
                          }
                        } finally {
                          if (ctx.mounted) setSheet(() => isUploading = false);
                        }
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    gradient: pickedFile != null && !isUploading
                        ? const LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)])
                        : null,
                    color: pickedFile == null || isUploading
                        ? AppColors.border : null,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: isUploading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded,
                              color: pickedFile != null
                                  ? Colors.white : AppColors.textDim,
                              size: 16),
                            const SizedBox(width: 8),
                            Text('BAGIKAN',
                              style: TextStyle(
                                color: pickedFile != null
                                    ? Colors.white : AppColors.textDim,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2)),
                          ],
                        ),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Confirm delete ─────────────────────────────────────────────────────────

  void _confirmDelete(String postId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Postingan',
          style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Postingan ini akan dihapus permanen.',
          style: TextStyle(color: AppColors.textDim)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal',
              style: TextStyle(color: AppColors.textDim))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _postService.deletePost(postId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Postingan dihapus.'),
                    backgroundColor: Colors.green));
              }
            },
            child: const Text('Hapus',
              style: TextStyle(
                color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final userService = UserService();

    return StreamBuilder(
      stream: userService.myProfileStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary));
        }

        final data        = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final name        = data['name']        ?? 'Anggota Void';
        final bio         = data['bio']         ?? '';
        final role        = data['role']        ?? 'Member';
        final hobi        = data['hobi']        ?? '';
        final asal        = data['asal']        ?? '';
        final instagram   = data['instagram']   ?? '';
        final tiktok      = data['tiktok']      ?? '';
        final photoBase64 = data['photoBase64'] ?? '';
        final email       = FirebaseAuth.instance.currentUser?.email ?? '';
        final createdAt   = data['createdAt'];
        final myUid       = _postService.uid ?? '';

        return NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text('Profil Saya.',
                      style: TextStyle(fontSize: 32,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: AppColors.primary)),
                    const SizedBox(height: 28),

                    // ── Avatar + Stats ───────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar
                        Container(
                          width: 90, height: 90,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)]),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [BoxShadow(
                              color: Colors.purple.withValues(alpha: 0.2),
                              blurRadius: 16, offset: const Offset(0, 8))],
                          ),
                          padding: const EdgeInsets.all(2.5),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: photoBase64.isNotEmpty
                                ? Image.memory(base64Decode(photoBase64),
                                    fit: BoxFit.cover)
                                : Container(color: Colors.purple.shade100,
                                    child: const Icon(Icons.person,
                                      size: 44, color: Colors.purple)),
                          ),
                        ),
                        const SizedBox(width: 24),

                        // Stats: jumlah post + total like
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: _postService.getUserPosts(myUid),
                            builder: (ctx, snap) {
                              final docs  = snap.data?.docs ?? [];
                              final count = docs.length;
                              // Jumlahkan semua likeCount dari semua post
                              final totalLikes = docs.fold<int>(0, (sum, d) {
                                final data = d.data() as Map<String, dynamic>;
                                return sum + ((data['likeCount'] ?? 0) as int);
                              });
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _statItem('$count', 'Postingan'),
                                  Container(width: 1, height: 28,
                                    color: AppColors.border),
                                  _statItem('$totalLikes', 'Disukai'),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Nama & role ──────────────────────────────────────
                    Text(name, style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w900,
                      color: AppColors.textMain)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: _getRoleColor(role).shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _getRoleColor(role).shade200)),
                      child: Text(role.toUpperCase(),
                        style: TextStyle(fontSize: 9,
                          fontWeight: FontWeight.bold, letterSpacing: 2,
                          color: _getRoleColor(role).shade700)),
                    ),
                    if (bio.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(bio, style: TextStyle(fontSize: 13,
                        color: AppColors.textDim, height: 1.4)),
                    ],
                    const SizedBox(height: 4),
                    Text(email, style: TextStyle(
                      fontSize: 11, color: AppColors.textDim)),
                    const SizedBox(height: 16),

                    // ── Tombol Edit Profil + Tambah Post ─────────────────
                    Row(children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) =>
                              EditProfileScreen(profileData: data))),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border)),
                            alignment: Alignment.center,
                            child: Text('Edit Profil',
                              style: TextStyle(fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMain)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showCreatePostSheet(
                            name, photoBase64),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)]),
                              borderRadius: BorderRadius.circular(12)),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add,
                                  color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                const Text('Tambah Foto',
                                  style: TextStyle(fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // ── Tab Bar ──────────────────────────────────────────────────
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(
                TabBar(
                  controller: _tabCtrl,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 2,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textDim,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 12),
                  tabs: const [
                    Tab(icon: Icon(Icons.person_outline, size: 20),
                      text: 'Info'),
                    Tab(icon: Icon(Icons.grid_on, size: 20),
                      text: 'Postingan'),
                  ],
                ),
                AppColors.bg,
              ),
            ),
          ],

          // ── Tab Body ─────────────────────────────────────────────────────
          body: TabBarView(
            controller: _tabCtrl,
            children: [

              // ── Tab 0: Info ──────────────────────────────────────────
              _buildInfoTab(
                data: data,
                hobi: hobi, asal: asal,
                instagram: instagram, tiktok: tiktok,
                createdAt: createdAt,
              ),

              // ── Tab 1: Postingan (Grid) ───────────────────────────────
              _buildPostsGrid(myUid, name, photoBase64),
            ],
          ),
        );
      },
    );
  }

  // ── Tab Info ───────────────────────────────────────────────────────────────

  Widget _buildInfoTab({
    required Map<String, dynamic> data,
    required String hobi,
    required String asal,
    required String instagram,
    required String tiktok,
    required dynamic createdAt,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
      children: [

        // Info Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border)),
          child: Column(children: [
            if (hobi.isNotEmpty) ...[
              _buildInfoRow(Icons.sports_esports, 'Hobi', hobi, Colors.purple),
              Divider(color: AppColors.border, height: 24),
            ],
            if (asal.isNotEmpty) ...[
              _buildInfoRow(Icons.location_on_outlined, 'Asal', asal, Colors.blue),
              Divider(color: AppColors.border, height: 24),
            ],
            _buildInfoRow(Icons.calendar_today_outlined, 'Tergabung',
              _formatDate(createdAt), Colors.green),
          ]),
        ),

        // Sosmed
        if (instagram.isNotEmpty || tiktok.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('SOSIAL MEDIA', style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w900,
                letterSpacing: 2, color: AppColors.textDim)),
              const SizedBox(height: 16),
              if (instagram.isNotEmpty) ...[
                _buildSosmedRow(icon: Icons.camera_alt_outlined,
                  color: Colors.pink, platform: 'Instagram',
                  username: '@$instagram'),
                if (tiktok.isNotEmpty) Divider(color: AppColors.border, height: 20),
              ],
              if (tiktok.isNotEmpty)
                _buildSosmedRow(icon: Icons.music_note,
                  color: Colors.black87, platform: 'TikTok',
                  username: '@$tiktok'),
            ]),
          ),
        ],
        const SizedBox(height: 24),

        // Pengaturan
        Text('PENGATURAN AKUN', style: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w900,
          letterSpacing: 2, color: AppColors.textDim)),
        const SizedBox(height: 16),

        GestureDetector(
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const NotificationSettingsScreen())),
          child: _buildSettingItem(
            Icons.notifications, 'Notifikasi & Pengingat', Colors.blue)),
        const SizedBox(height: 12),

        GestureDetector(
          onTap: () async {
            await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const DarkModeSettingsScreen()));
            if (mounted) setState(() {});
          },
          child: _buildSettingItem(
            _themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            'Tampilan', Colors.indigo)),
        const SizedBox(height: 12),

        GestureDetector(
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AboutScreen())),
          child: _buildSettingItem(
            Icons.info_outline, 'Tentang Aplikasi', Colors.purple)),
        const SizedBox(height: 40),

        // Logout
        GestureDetector(
          onTap: () async {
            await AuthService().logout();
            if (context.mounted) {
              Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const LoginScreen()));
            }
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('KELUAR AKUN', style: TextStyle(
                color: Colors.red, fontSize: 12,
                fontWeight: FontWeight.w900, letterSpacing: 3)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tab Postingan (Grid) ───────────────────────────────────────────────────

  Widget _buildPostsGrid(
      String myUid, String userName, String userPhotoBase64) {
    return StreamBuilder<QuerySnapshot>(
      stream: _postService.getUserPosts(myUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary));
        }

        // Sort client-side terbaru dulu (tidak butuh Firestore index)
        final docs = (snapshot.data?.docs ?? [])
          ..sort((a, b) {
            final aTime = (a.data() as Map)['createdAt'];
            final bTime = (b.data() as Map)['createdAt'];
            if (aTime == null || bTime == null) return 0;
            return (bTime as dynamic).compareTo(aTime as dynamic);
          });

        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.07),
                      shape: BoxShape.circle),
                    child: Icon(Icons.photo_library_outlined,
                      size: 48, color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  const SizedBox(height: 16),
                  Text('Belum ada postingan.',
                    style: TextStyle(fontSize: 15,
                      fontWeight: FontWeight.w900, color: AppColors.textMain)),
                  const SizedBox(height: 6),
                  Text('Bagikan foto pertamamu!',
                    style: TextStyle(fontSize: 12, color: AppColors.textDim)),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => _showCreatePostSheet(userName, userPhotoBase64),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)]),
                        borderRadius: BorderRadius.circular(12)),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.add, color: Colors.white, size: 14),
                        SizedBox(width: 6),
                        Text('Tambah Foto', style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold,
                          fontSize: 12)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(3, 3, 3, 100),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 3,
            mainAxisSpacing: 3,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final post   = docs[index].data() as Map<String, dynamic>;
            final postId = docs[index].id;
            final img    = post['imageBase64'] ?? '';

            return GestureDetector(
              onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => PostDetailScreen(
                  postId: postId,
                  post: post,
                  isOwner: true,
                ))),
              onLongPress: () => _confirmDelete(postId),
              child: Stack(fit: StackFit.expand, children: [
                // Thumbnail
                img.isNotEmpty
                    ? Image.memory(base64Decode(img), fit: BoxFit.cover)
                    : Container(color: AppColors.border,
                        child: Icon(Icons.image,
                          color: AppColors.textDim, size: 24)),

                // Like count overlay — realtime
                Positioned(bottom: 4, left: 6,
                  child: StreamBuilder(
                    stream: _postService.getPostStream(postId),
                    builder: (ctx, snap) {
                      final d = snap.data?.data() as Map<String, dynamic>?;
                      final likes = d?['likeCount'] ?? post['likeCount'] ?? 0;
                      return Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.favorite,
                          color: Colors.white, size: 11,
                          shadows: [Shadow(color: Colors.black45, blurRadius: 4)]),
                        const SizedBox(width: 3),
                        Text('$likes',
                          style: const TextStyle(
                            color: Colors.white, fontSize: 10,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.black45, blurRadius: 4)])),
                      ]);
                    },
                  ),
                ),
              ]),
            );
          },
        );
      },
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _statItem(String value, String label) {
    return Column(children: [
      Text(value, style: TextStyle(
        fontSize: 20, fontWeight: FontWeight.w900,
        color: AppColors.textMain)),
      Text(label, style: TextStyle(fontSize: 11, color: AppColors.textDim)),
    ]);
  }

  MaterialColor _getRoleColor(String role) {
    switch (role) {
      case 'Owner':         return Colors.orange;
      case 'Admin':         return Colors.purple;
      case 'Member Senior': return Colors.blue;
      default:              return Colors.grey;
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      MaterialColor color) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.shade50, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 16, color: color.shade600)),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 10, color: AppColors.textDim,
          fontWeight: FontWeight.bold, letterSpacing: 1)),
        Text(value, style: TextStyle(fontSize: 13, color: AppColors.textMain,
          fontWeight: FontWeight.w600)),
      ]),
    ]);
  }

  Widget _buildSosmedRow({
    required IconData icon,
    required Color color,
    required String platform,
    required String username,
  }) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: color)),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(platform, style: TextStyle(fontSize: 10, color: AppColors.textDim,
          fontWeight: FontWeight.bold, letterSpacing: 1)),
        Text(username, style: TextStyle(fontSize: 13,
          color: AppColors.textMain, fontWeight: FontWeight.w600)),
      ]),
    ]);
  }

  Widget _buildSettingItem(IconData icon, String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.shade50, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 20, color: color.shade600)),
        const SizedBox(width: 16),
        Expanded(child: Text(label.toUpperCase(),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
            color: AppColors.textDim, letterSpacing: 1))),
        Icon(Icons.chevron_right, size: 20, color: AppColors.border),
      ]),
    );
  }
}

// ── Sticky TabBar Delegate ─────────────────────────────────────────────────────

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color  bgColor;

  const _StickyTabBarDelegate(this.tabBar, this.bgColor);

  @override
  double get minExtent => tabBar.preferredSize.height + 1;
  @override
  double get maxExtent => tabBar.preferredSize.height + 1;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: bgColor,
      child: Column(children: [
        Divider(height: 1, color: AppColors.border),
        tabBar,
      ]),
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate old) =>
      old.tabBar != tabBar || old.bgColor != bgColor;
}