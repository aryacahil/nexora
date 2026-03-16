import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/colors.dart';
import '../../../services/post_service.dart';
import '../../profile/post_detail_screen.dart';

class MemberDetail extends StatefulWidget {
  final Map<String, dynamic> memberData;
  const MemberDetail({super.key, required this.memberData});

  @override
  State<MemberDetail> createState() => _MemberDetailState();
}

class _MemberDetailState extends State<MemberDetail>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final PostService _postService = PostService();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
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

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Owner':         return Colors.orange.shade600;
      case 'Admin':         return Colors.purple.shade600;
      case 'Member Senior': return Colors.blue.shade600;
      default:              return Colors.grey.shade600;
    }
  }

  MaterialColor _getRoleMaterialColor(String role) {
    switch (role) {
      case 'Owner':         return Colors.orange;
      case 'Admin':         return Colors.purple;
      case 'Member Senior': return Colors.blue;
      default:              return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name      = widget.memberData['name']        ?? 'Anggota';
    final bio       = widget.memberData['bio']         ?? '';
    final role      = widget.memberData['role']        ?? 'Member';
    final hobi      = widget.memberData['hobi']        ?? '';
    final asal      = widget.memberData['asal']        ?? '';
    final instagram = widget.memberData['instagram']   ?? '';
    final tiktok    = widget.memberData['tiktok']      ?? '';
    final photo     = widget.memberData['photoBase64'] ?? '';
    final createdAt = widget.memberData['createdAt'];
    final memberUid = widget.memberData['uid']         ?? '';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            backgroundColor: AppColors.bg,
            elevation: 0,
            pinned: true,
            leading: IconButton(
              icon: Icon(Icons.chevron_left, color: AppColors.accent, size: 32),
              onPressed: () => Navigator.pop(context)),
            title: Text('Profil Anggota', style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w900,
              color: AppColors.primary)),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Avatar + Stats ────────────────────────────────────
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
                          child: photo.isNotEmpty
                              ? Image.memory(base64Decode(photo),
                                  fit: BoxFit.cover)
                              : Container(color: Colors.purple.shade100,
                                  child: const Icon(Icons.person,
                                    size: 44, color: Colors.purple)),
                        ),
                      ),
                      const SizedBox(width: 24),

                      // Stats: postingan + total like
                      Expanded(
                        child: memberUid.isEmpty
                            ? const SizedBox.shrink()
                            : StreamBuilder<QuerySnapshot>(
                                stream: _postService.getUserPosts(memberUid),
                                builder: (ctx, snap) {
                                  final docs       = snap.data?.docs ?? [];
                                  final count      = docs.length;
                                  final totalLikes = docs.fold<int>(0, (sum, d) {
                                    final data = d.data() as Map<String, dynamic>;
                                    return sum + ((data['likeCount'] ?? 0) as int);
                                  });
                                  return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
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

                  // ── Nama & Role ───────────────────────────────────────
                  Text(name, style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w900,
                    color: AppColors.textMain)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getRoleMaterialColor(role).shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getRoleMaterialColor(role).shade200)),
                    child: Text(role.toUpperCase(),
                      style: TextStyle(fontSize: 9,
                        fontWeight: FontWeight.bold, letterSpacing: 2,
                        color: _getRoleColor(role))),
                  ),
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(bio, style: TextStyle(
                      fontSize: 13, color: AppColors.textDim, height: 1.4)),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ── Tab Bar sticky ────────────────────────────────────────────
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

            // ── Tab 0: Info ─────────────────────────────────────────────
            ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border)),
                  child: Column(children: [
                    if (hobi.isNotEmpty) ...[
                      _buildInfoRow(Icons.sports_esports, 'Hobi',
                        hobi, Colors.purple),
                      Divider(color: AppColors.border, height: 24),
                    ],
                    if (asal.isNotEmpty) ...[
                      _buildInfoRow(Icons.location_on_outlined, 'Asal',
                        asal, Colors.blue),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SOSIAL MEDIA', style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w900,
                          letterSpacing: 2, color: AppColors.textDim)),
                        const SizedBox(height: 16),
                        if (instagram.isNotEmpty) ...[
                          _buildSosmedRow(
                            icon: Icons.camera_alt_outlined,
                            color: Colors.pink,
                            platform: 'Instagram',
                            username: '@$instagram'),
                          if (tiktok.isNotEmpty)
                            Divider(color: AppColors.border, height: 20),
                        ],
                        if (tiktok.isNotEmpty)
                          _buildSosmedRow(
                            icon: Icons.music_note,
                            color: Colors.black87,
                            platform: 'TikTok',
                            username: '@$tiktok'),
                      ],
                    ),
                  ),
                ],
              ],
            ),

            // ── Tab 1: Postingan Grid ────────────────────────────────────
            memberUid.isEmpty
                ? Center(child: Text('UID tidak ditemukan.',
                    style: TextStyle(color: AppColors.textDim)))
                : _buildPostsGrid(memberUid),
          ],
        ),
      ),
    );
  }

  // ── Grid postingan ─────────────────────────────────────────────────────────

  Widget _buildPostsGrid(String memberUid) {
    return StreamBuilder<QuerySnapshot>(
      stream: _postService.getUserPosts(memberUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(
            color: AppColors.primary));
        }

        // Sort terbaru dulu (client-side, tidak butuh index)
        final docs = (snapshot.data?.docs ?? [])
          ..sort((a, b) {
            final aTime = (a.data() as Map)['createdAt'];
            final bTime = (b.data() as Map)['createdAt'];
            if (aTime == null || bTime == null) return 0;
            return (bTime as dynamic).compareTo(aTime as dynamic);
          });

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_library_outlined,
                  size: 56,
                  color: AppColors.primary.withValues(alpha: 0.25)),
                const SizedBox(height: 16),
                Text('Belum ada postingan.',
                  style: TextStyle(fontSize: 14, color: AppColors.textDim)),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(3, 3, 3, 40),
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
                  isOwner: false, // bukan pemilik, tidak bisa hapus
                ))),
              child: Stack(fit: StackFit.expand, children: [
                // Thumbnail
                img.isNotEmpty
                    ? Image.memory(base64Decode(img), fit: BoxFit.cover)
                    : Container(color: AppColors.border,
                        child: Icon(Icons.image,
                          color: AppColors.textDim, size: 24)),

                // Like count overlay — realtime
                Positioned(
                  bottom: 4, left: 6,
                  child: StreamBuilder(
                    stream: _postService.getPostStream(postId),
                    builder: (ctx, snap) {
                      final d     = snap.data?.data() as Map<String, dynamic>?;
                      final likes = d?['likeCount'] ?? post['likeCount'] ?? 0;
                      return Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.favorite,
                          color: Colors.white, size: 11,
                          shadows: [Shadow(
                            color: Colors.black45, blurRadius: 4)]),
                        const SizedBox(width: 3),
                        Text('$likes', style: const TextStyle(
                          color: Colors.white, fontSize: 10,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(
                            color: Colors.black45, blurRadius: 4)])),
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
        Text(platform, style: TextStyle(fontSize: 10,
          color: AppColors.textDim, fontWeight: FontWeight.bold,
          letterSpacing: 1)),
        Text(username, style: TextStyle(fontSize: 13,
          color: AppColors.textMain, fontWeight: FontWeight.w600)),
      ]),
    ]);
  }
}

// ── Sticky TabBar Delegate ─────────────────────────────────────────────────────

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color  bgColor;

  const _StickyTabBarDelegate(this.tabBar, this.bgColor);

  @override double get minExtent => tabBar.preferredSize.height + 1;
  @override double get maxExtent => tabBar.preferredSize.height + 1;

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