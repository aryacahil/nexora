import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'forum/channel_list.dart';
import 'member_grid.dart';
import '../../../core/colors.dart';
import '../../../services/user_service.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => HomeTabState();
}

class HomeTabState extends State<HomeTab> {
  String subView = 'main';

  void resetToMain() {
    if (subView != 'main') {
      setState(() => subView = 'main');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (subView == 'forum') return ChannelList(onBack: () => setState(() => subView = 'main'));
    if (subView == 'rules' || subView == 'members') return _buildSimpleListView(subView);

    return StreamBuilder(
      stream: UserService().myProfileStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final name = data['name'] ?? '';
        final photoBase64 = data['photoBase64'] ?? '';

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 120),
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SELAMAT DATANG,', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppColors.textDim)),
                    Text(
                      name.isEmpty ? '...' : name,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primary),
                    ),
                  ],
                ),
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(colors: [Color(0xFFA78BFA), Color(0xFF818CF8)]),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: photoBase64.isNotEmpty
                        ? Image.memory(base64Decode(photoBase64), fit: BoxFit.cover)
                        : Container(
                            color: Colors.purple.shade200,
                            child: const Icon(Icons.person, color: Colors.white, size: 28),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Banner pengumuman terbaru dari Firestore
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('announcements')
                  .orderBy('createdAt', descending: true)
                  .limit(1)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFFC026D3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [BoxShadow(color: Colors.purple.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat Datang!',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Belum ada pengumuman terbaru.',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                final latest = snap.data!.docs.first.data() as Map<String, dynamic>;
                final bannerTitle = latest['title'] ?? 'Selamat Datang!';
                final bannerContent = latest['content'] ?? 'Belum ada pengumuman terbaru.';

                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFFC026D3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [BoxShadow(color: Colors.purple.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bannerTitle,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bannerContent,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            Text('MENU UTAMA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.textDim)),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildMenuCard(Icons.menu_book, 'Panduan', () => setState(() => subView = 'rules')),
                const SizedBox(width: 16),
                _buildMenuCard(Icons.people, 'Anggota', () => setState(() => subView = 'members')),
                const SizedBox(width: 16),
                _buildMenuCard(Icons.chat_bubble_outline, 'Diskusi', () => setState(() => subView = 'forum')),
              ],
            ),
            const SizedBox(height: 32),

            Text('AKTIVITAS TERKINI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.textDim)),
            const SizedBox(height: 16),

            // Aktivitas dari pengumuman terbaru Firestore
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('announcements')
                  .orderBy('createdAt', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return _buildActivityCard('Selamat Datang', 'Belum ada aktivitas terbaru.', '');
                }
                final docs = snap.data!.docs;
                return Column(
                  children: docs.map((doc) {
                    final a = doc.data() as Map<String, dynamic>;
                    final createdAt = a['createdAt'];
                    String timeStr = 'Baru saja';
                    if (createdAt != null) {
                      final dt = (createdAt as Timestamp).toDate();
                      final diff = DateTime.now().difference(dt);
                      if (diff.inMinutes < 60) {
                        timeStr = '${diff.inMinutes} menit yang lalu';
                      } else if (diff.inHours < 24) {
                        timeStr = '${diff.inHours} jam yang lalu';
                      } else {
                        timeStr = '${diff.inDays} hari yang lalu';
                      }
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildActivityCard(
                        a['title'] ?? '',
                        a['content'] ?? '',
                        timeStr,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Expanded _buildMenuCard(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.accent, size: 28),
              const SizedBox(height: 12),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppColors.textDim)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard(String title, String desc, String time) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 8, height: 8,
            decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                const SizedBox(height: 4),
                Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: AppColors.textDim)),
                if (time.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(time.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppColors.textDim)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleListView(String viewType) {
    final userService = UserService();

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 120),
      children: [
        GestureDetector(
          onTap: () => setState(() => subView = 'main'),
          child: Row(
            children: [
              Icon(Icons.chevron_left, color: AppColors.accent, size: 20),
              Text('KEMBALI', style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          viewType == 'rules' ? 'Panduan.' : 'Anggota.',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: AppColors.primary),
        ),
        const SizedBox(height: 24),

        if (viewType == 'rules') ...[
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('rules')
                .orderBy('order')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Belum ada panduan.', style: TextStyle(color: AppColors.textDim)),
                  ),
                );
              }
              final rules = snapshot.data!.docs;
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rules.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final r = rules[index].data() as Map<String, dynamic>;
                  return _buildRuleTile(r['title'] ?? '', r['content'] ?? '');
                },
              );
            },
          ),
        ] else ...[
          StreamBuilder(
            stream: userService.getAllMembers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text('Belum ada anggota.', style: TextStyle(color: AppColors.textDim)),
                );
              }
              return MemberGrid(members: snapshot.data!.docs);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildRuleTile(String title, String content) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        shape: const RoundedRectangleBorder(),
        collapsedShape: const RoundedRectangleBorder(),
        backgroundColor: AppColors.card,
        collapsedBackgroundColor: AppColors.card,
        title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMain)),
        trailing: Icon(Icons.expand_more, color: AppColors.textDim),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            color: AppColors.card,
            child: Text(content, style: TextStyle(fontSize: 13, color: AppColors.textDim, height: 1.5)),
          ),
        ],
      ),
    );
  }
}