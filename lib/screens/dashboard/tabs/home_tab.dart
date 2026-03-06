import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'forum/channel_list.dart';
import 'member_grid.dart';
import 'game/russian_roulette.dart';
import 'game/uno/uno_page.dart';
import '../../../core/colors.dart';
import '../../../services/user_service.dart';
import '../../feedback_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => HomeTabState();
}

class HomeTabState extends State<HomeTab> {
  String subView = 'main';

  void resetToMain() {
    if (subView != 'main') setState(() => subView = 'main');
  }

  @override
  Widget build(BuildContext context) {
    if (subView == 'forum') {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) setState(() => subView = 'main');
        },
        child: ChannelList(onBack: () => setState(() => subView = 'main')),
      );
    }
    if (subView == 'rules' ||
        subView == 'members' ||
        subView == 'game' ||
        subView == 'donasi') {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) setState(() => subView = 'main');
        },
        child: _buildSubView(subView),
      );
    }

    return StreamBuilder(
      stream: UserService().myProfileStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }

        final data =
            snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final name = data['name'] ?? '';
        final photoBase64 = data['photoBase64'] ?? '';

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 120),
          children: [
            // ── Header ──────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SELAMAT DATANG,',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: AppColors.textDim,
                      ),
                    ),
                    Text(
                      name.isEmpty ? '...' : name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(colors: [
                      Color(0xFFA78BFA),
                      Color(0xFF818CF8),
                    ]),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: photoBase64.isNotEmpty
                        ? Image.memory(base64Decode(photoBase64),
                            fit: BoxFit.cover)
                        : Container(
                            color: Colors.purple.shade200,
                            child: const Icon(Icons.person,
                                color: Colors.white, size: 28),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── Banner Pengumuman ────────────────────────
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('announcements')
                  .orderBy('createdAt', descending: true)
                  .limit(1)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const SizedBox.shrink();
                }
                final latest =
                    snap.data!.docs.first.data() as Map<String, dynamic>;
                final bannerTitle = latest['title'] ?? '';
                final bannerContent = latest['content'] ?? '';

                return Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFFC026D3)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.campaign,
                                  color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (bannerTitle.isNotEmpty)
                                    Text(
                                      bannerTitle,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  if (bannerContent.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      bannerContent,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),

            // ── Menu Utama label ─────────────────────────
            Text(
              'MENU UTAMA',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: AppColors.textDim,
              ),
            ),
            const SizedBox(height: 16),

            // ── Baris 1: Panduan, Anggota, Diskusi ───────
            Row(
              children: [
                _buildMenuCard(
                  Icons.menu_book,
                  'Panduan',
                  () => setState(() => subView = 'rules'),
                ),
                const SizedBox(width: 16),
                _buildMenuCard(
                  Icons.people,
                  'Anggota',
                  () => setState(() => subView = 'members'),
                ),
                const SizedBox(width: 16),
                _buildMenuCard(
                  Icons.chat_bubble_outline,
                  'Diskusi',
                  () => setState(() => subView = 'forum'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Baris 2: Saran, Game, Donasi ─────────────
            Row(
              children: [
                _buildMenuCard(
                  Icons.lightbulb_outline,
                  'Saran',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const FeedbackScreen()),
                  ),
                ),
                const SizedBox(width: 16),
                _buildMenuCard(
                  Icons.sports_esports,
                  'Game',
                  () => setState(() => subView = 'game'),
                ),
                const SizedBox(width: 16),
                _buildMenuCard(
                  Icons.volunteer_activism,
                  'Donasi',
                  () => setState(() => subView = 'donasi'),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── Aktivitas Terkini ────────────────────────
            Text(
              'AKTIVITAS TERKINI',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: AppColors.textDim,
              ),
            ),
            const SizedBox(height: 16),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('announcements')
                  .orderBy('createdAt', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.inbox_outlined,
                            color: Colors.purple.shade100, size: 24),
                        const SizedBox(width: 12),
                        Text('Belum ada aktivitas terbaru.',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.textDim)),
                      ],
                    ),
                  );
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

  Expanded _buildMenuCard(
      IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
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
            children: [
              Icon(icon, color: AppColors.accent, size: 28),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: AppColors.textDim,
                ),
              ),
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
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                color: AppColors.accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain)),
                const SizedBox(height: 4),
                Text(desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textDim)),
                if (time.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    time.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: AppColors.textDim,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubView(String viewType) {
    final userService = UserService();

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 120),
      children: [
        GestureDetector(
          onTap: () => setState(() => subView = 'main'),
          child: Row(
            children: [
              Icon(Icons.chevron_left, color: AppColors.accent, size: 20),
              Text('KEMBALI',
                  style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          viewType == 'rules'
              ? 'Panduan.'
              : viewType == 'members'
                  ? 'Anggota.'
                  : viewType == 'game'
                      ? 'Game.'
                      : 'Donasi.',
          style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: AppColors.primary),
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
                return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Belum ada panduan.',
                        style: TextStyle(color: AppColors.textDim)),
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
                  final r =
                      rules[index].data() as Map<String, dynamic>;
                  return _buildRuleTile(
                    context,
                    title: r['title'] ?? '',
                    content: r['content'] ?? '',
                    imageBase64: r['imageBase64'] ?? '',
                    link: r['link'] ?? '',
                  );
                },
              );
            },
          ),
        ] else if (viewType == 'game') ...[
          _buildGameView(),
        ] else if (viewType == 'donasi') ...[
          _buildDonasiView(),
        ] else ...[
          StreamBuilder(
            stream: userService.getAllMembers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text('Belum ada anggota.',
                      style: TextStyle(color: AppColors.textDim)),
                );
              }
              return MemberGrid(members: snapshot.data!.docs);
            },
          ),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // GAME VIEW — tambahkan game baru di sini
  // ═══════════════════════════════════════════════════════════════

  Widget _buildGameView() {
    return Column(
      children: [
        // ── Russian Roulette ──────────────────────────────
        _buildGameCard(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C0000), Color(0xFFDC2626)],
          ),
          glowColor: Colors.red,
          icon: Icons.gps_fixed,
          title: 'RUSSIAN ROULETTE',
          subtitle: 'Uji nyalimu bersama teman-teman!',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const RussianRoulettePage(),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── UNO ───────────────────────────────────────────
        _buildGameCard(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C0000), Color(0xFFE53935)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          glowColor: Colors.red,
          icon: Icons.style,
          title: 'UNO',
          subtitle: '2–6 pemain • Kartu 7-Swap & 0-Rotate • Timer 20 detik',
          badge: 'NEW',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const UnoPage(),
            ),
          ),
        ),
      ],
    );
  }

  /// Card game — tap langsung masuk ke game
  Widget _buildGameCard({
    required LinearGradient gradient,
    required Color glowColor,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: glowColor.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios,
                color: Colors.white.withValues(alpha: 0.5), size: 16),
          ],
        ),
      ),
    );
  }
  Widget _buildDonasiView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('donations')
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.volunteer_activism,
                      size: 56, color: Colors.purple.shade100),
                  const SizedBox(height: 16),
                  Text('Belum ada info donasi.',
                      style: TextStyle(color: AppColors.textDim)),
                ],
              ),
            ),
          );
        }
        final donations = snapshot.data!.docs;
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: donations.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final d = donations[index].data() as Map<String, dynamic>;
            final imageBase64 = d['imageBase64'] ?? '';
            final link = d['link'] ?? '';
            final noRek = d['noRek'] ?? '';
            final bank = d['bank'] ?? '';
            final atasNama = d['atasNama'] ?? '';

            return Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageBase64.isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20)),
                      child: Image.memory(
                        base64Decode(imageBase64),
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.volunteer_activism,
                                  color: Colors.green.shade600, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                d['title'] ?? '',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textMain,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if ((d['description'] ?? '').isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            d['description'] ?? '',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textDim,
                                height: 1.5),
                          ),
                        ],
                        if (noRek.isNotEmpty || bank.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: Colors.green.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'INFO REKENING',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (bank.isNotEmpty)
                                  _buildRekeningRow(
                                      'Bank', bank, Icons.account_balance),
                                if (noRek.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  _buildRekeningRow('No. Rekening', noRek,
                                      Icons.credit_card),
                                ],
                                if (atasNama.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  _buildRekeningRow(
                                      'Atas Nama', atasNama, Icons.person),
                                ],
                              ],
                            ),
                          ),
                        ],
                        if (link.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () async {
                              final uri = Uri.tryParse(link);
                              if (uri != null && await canLaunchUrl(uri)) {
                                await launchUrl(uri,
                                    mode: LaunchMode.externalApplication);
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF059669),
                                    Color(0xFF047857)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.open_in_new,
                                      size: 16, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Donasi Sekarang',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRekeningRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.green.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
              fontSize: 12,
              color: AppColors.textDim,
              fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
                fontSize: 12,
                color: AppColors.textMain,
                fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildRuleTile(
    BuildContext context, {
    required String title,
    required String content,
    required String imageBase64,
    required String link,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          shape: const RoundedRectangleBorder(),
          collapsedShape: const RoundedRectangleBorder(),
          backgroundColor: AppColors.card,
          collapsedBackgroundColor: AppColors.card,
          title: Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain)),
          trailing: Icon(Icons.expand_more, color: AppColors.textDim),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              color: AppColors.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (content.isNotEmpty)
                    Text(content,
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textDim,
                            height: 1.5)),
                  if (imageBase64.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        base64Decode(imageBase64),
                        width: double.infinity,
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                  ],
                  if (link.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () async {
                        final uri = Uri.tryParse(link);
                        if (uri != null && await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color:
                              AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.primary
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.open_in_new,
                                size: 14, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                link,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}