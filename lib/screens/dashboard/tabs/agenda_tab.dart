import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/colors.dart';

class AgendaTab extends StatelessWidget {
  const AgendaTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 120),
      children: [
        Text('Pengumuman.',
            style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: AppColors.primary)),
        const SizedBox(height: 8),
        Text('Informasi resmi dari pengurus Marga Void',
            style: TextStyle(fontSize: 12, color: AppColors.textDim)),
        const SizedBox(height: 32),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('announcements')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Icon(Icons.campaign_outlined,
                        size: 48, color: Colors.purple.shade100),
                    const SizedBox(height: 12),
                    Text('Belum ada pengumuman.',
                        style: TextStyle(color: AppColors.textDim)),
                  ],
                ),
              );
            }
            final docs = snapshot.data!.docs;
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final a = docs[index].data() as Map<String, dynamic>;
                final createdAt = a['createdAt'];
                String dateStr = '';
                if (createdAt != null) {
                  final dt = (createdAt as Timestamp).toDate();
                  dateStr = '${dt.day}/${dt.month}/${dt.year}';
                }
                return _buildAnnouncementCard(
                  context: context,
                  title: a['title'] ?? '',
                  content: a['content'] ?? '',
                  date: dateStr,
                  createdBy: a['createdBy'] ?? '',
                  imageBase64: a['imageBase64'] ?? '',
                  link: a['link'] ?? '',
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildAnnouncementCard({
    required BuildContext context,
    required String title,
    required String content,
    required String date,
    required String createdBy,
    required String imageBase64,
    required String link,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Foto di atas ──────────────────────────────
          if (imageBase64.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              child: Image.memory(
                base64Decode(imageBase64),
                width: double.infinity,
                fit: BoxFit.fitWidth,
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('PENGUMUMAN',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700)),
                ),
                const SizedBox(height: 12),

                // Judul
                Text(title,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textMain)),
                const SizedBox(height: 8),

                // Isi
                Text(content,
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textDim,
                        height: 1.5)),

                // ── Tombol Link ───────────────────────────
                if (link.isNotEmpty) ...[
                  const SizedBox(height: 14),
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
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3)),
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
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // ── Tanggal & Nama ────────────────────────
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 12, color: AppColors.textDim),
                    const SizedBox(width: 4),
                    Text(date,
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textDim)),
                    const SizedBox(width: 12),
                    Icon(Icons.person_outline,
                        size: 12, color: AppColors.textDim),
                    const SizedBox(width: 4),
                    Text(createdBy,
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textDim)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}