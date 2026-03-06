import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/colors.dart';
import '../../../services/feedback_service.dart';

class AdminFeedbacks extends StatelessWidget {
  const AdminFeedbacks({super.key});

  @override
  Widget build(BuildContext context) {
    final feedbackService = FeedbackService();

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
          'Saran & Laporan',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.primary),
        ),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: feedbackService.getUnreadFeedbacks(),
            builder: (context, snap) {
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => feedbackService.markAllAsRead(docs),
                child: Text(
                  'Tandai semua',
                  style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: feedbackService.getAllFeedbacks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 56, color: Colors.purple.shade100),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada saran atau laporan masuk.',
                    style: TextStyle(color: AppColors.textDim, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;
          final unreadCount = docs
              .where((d) => (d.data() as Map)['isRead'] == false)
              .length;

          return Column(
            children: [
              if (unreadCount > 0)
                Container(
  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  decoration: BoxDecoration(
    color: AppColors.primary.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
  ),
                  child: Row(
                    children: [
                      Icon(Icons.mark_email_unread,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '$unreadCount belum dibaca',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Ketuk kartu untuk tandai dibaca',
                        style: TextStyle(
                            fontSize: 10, color: AppColors.textDim),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final f = docs[index].data() as Map<String, dynamic>;
                    final id = docs[index].id;
                    final isRead = f['isRead'] ?? false;
                    final isAnonymous = f['isAnonymous'] ?? false;
                    final senderName = f['senderName'] ?? 'Anonim';
                    final message = f['message'] ?? '';
                    final type = f['type'] ?? 'saran';
                    final imageBase64 = f['imageBase64'] ?? '';
                    final createdAt = f['createdAt'];
                    final isLaporan = type == 'laporan';

                    String dateStr = '';
                    if (createdAt != null) {
                      final dt = (createdAt as Timestamp).toDate();
                      final diff = DateTime.now().difference(dt);
                      if (diff.inMinutes < 60) {
                        dateStr = '${diff.inMinutes} menit lalu';
                      } else if (diff.inHours < 24) {
                        dateStr = '${diff.inHours} jam lalu';
                      } else {
                        dateStr = '${diff.inDays} hari lalu';
                      }
                    }

                    // Warna kartu berdasarkan status + tipe
                    Color cardColor;
                    Color borderColor;
                    double borderWidth;

                    if (!isRead) {
  cardColor = isLaporan
      ? Colors.red.withValues(alpha: 0.15)
      : AppColors.primary.withValues(alpha: 0.12);
  borderColor = isLaporan
      ? Colors.red.shade400
      : Colors.purple.shade400;
  borderWidth = 1.5;
} else {
  cardColor = AppColors.card;
  borderColor = AppColors.border;
  borderWidth = 1;
}

                    return GestureDetector(
                      onTap: () async {
                        if (!isRead) {
                          await feedbackService.markAsRead(id);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: borderColor,
                            width: borderWidth,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Header kartu ────────
                            Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    gradient: isAnonymous
                                        ? const LinearGradient(colors: [
                                            Color(0xFF6B7280),
                                            Color(0xFF9CA3AF),
                                          ])
                                        : isLaporan
                                            ? const LinearGradient(colors: [
                                                Color(0xFFDC2626),
                                                Color(0xFFEF4444),
                                              ])
                                            : const LinearGradient(colors: [
                                                Color(0xFF8B5CF6),
                                                Color(0xFFD946EF),
                                              ]),
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: Icon(
                                    isAnonymous
                                        ? Icons.visibility_off
                                        : isLaporan
                                            ? Icons.report
                                            : Icons.lightbulb,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            senderName,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.textMain,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          // Badge tipe
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isLaporan
                                                  ? Colors.red.shade100
                                                  : Colors.purple.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              isLaporan
                                                  ? 'LAPORAN'
                                                  : 'SARAN',
                                              style: TextStyle(
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                                color: isLaporan
                                                    ? Colors.red.shade700
                                                    : Colors.purple.shade700,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                          if (!isRead) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isLaporan
                                                    ? Colors.red.shade600
                                                    : AppColors.primary,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: const Text(
                                                'BARU',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      Text(
                                        dateStr,
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.textDim),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red, size: 20),
                                  onPressed: () => _confirmDelete(
                                      context, feedbackService, id),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),
                            Divider(color: AppColors.border, height: 1),
                            const SizedBox(height: 12),

                            // ── Isi pesan ────────────
                            Text(
                              message,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textMain,
                                height: 1.6,
                              ),
                            ),

                            // ── Foto bukti ────────────
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

                            if (!isRead) ...[
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: () =>
                                      feedbackService.markAsRead(id),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: (isLaporan
                                              ? Colors.red
                                              : AppColors.primary)
                                          .withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.done,
                                            size: 14,
                                            color: isLaporan
                                                ? Colors.red.shade600
                                                : AppColors.primary),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Tandai sudah dibaca',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isLaporan
                                                ? Colors.red.shade600
                                                : AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, FeedbackService service, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus',
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Hapus ini? Tidak bisa dikembalikan.',
            style: TextStyle(color: AppColors.textDim)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal',
                style: TextStyle(color: AppColors.textDim)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await service.deleteFeedback(id);
            },
            child: const Text('Hapus',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}