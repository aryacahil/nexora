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
          icon:
              Icon(Icons.chevron_left, color: AppColors.accent, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Saran & Masukan',
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
                child:
                    CircularProgressIndicator(color: AppColors.primary));
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
                    'Belum ada saran masuk.',
                    style: TextStyle(
                        color: AppColors.textDim, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Saran dari anggota akan muncul di sini.',
                    style: TextStyle(
                        color: AppColors.textDim, fontSize: 12),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;
          final unreadCount = docs
              .where(
                  (d) => (d.data() as Map)['isRead'] == false)
              .length;

          return Column(
            children: [
              // ── Summary bar ──────────────────────────
              if (unreadCount > 0)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: Colors.purple.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.mark_email_unread,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '$unreadCount saran belum dibaca',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Ketuk untuk tandai dibaca',
                        style: TextStyle(
                            fontSize: 10, color: AppColors.textDim),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: ListView.separated(
                  padding:
                      const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final f =
                        docs[index].data() as Map<String, dynamic>;
                    final id = docs[index].id;
                    final isRead = f['isRead'] ?? false;
                    final isAnonymous = f['isAnonymous'] ?? false;
                    final senderName =
                        f['senderName'] ?? 'Anonim';
                    final message = f['message'] ?? '';
                    final createdAt = f['createdAt'];

                    String dateStr = '';
                    if (createdAt != null) {
                      final dt =
                          (createdAt as Timestamp).toDate();
                      final diff = DateTime.now().difference(dt);
                      if (diff.inMinutes < 60) {
                        dateStr = '${diff.inMinutes} menit lalu';
                      } else if (diff.inHours < 24) {
                        dateStr = '${diff.inHours} jam lalu';
                      } else {
                        dateStr = '${diff.inDays} hari lalu';
                      }
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
                          color: isRead
                              ? AppColors.card
                              : Colors.purple.shade50,
                          borderRadius:
                              BorderRadius.circular(18),
                          border: Border.all(
                            color: isRead
                                ? AppColors.border
                                : Colors.purple.shade300,
                            width: isRead ? 1 : 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            // ── Header kartu ────────
                            Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    gradient: isAnonymous
                                        ? const LinearGradient(
                                            colors: [
                                              Color(0xFF6B7280),
                                              Color(0xFF9CA3AF),
                                            ],
                                          )
                                        : const LinearGradient(
                                            colors: [
                                              Color(0xFF8B5CF6),
                                              Color(0xFFD946EF),
                                            ],
                                          ),
                                    borderRadius:
                                        BorderRadius.circular(13),
                                  ),
                                  child: Icon(
                                    isAnonymous
                                        ? Icons.visibility_off
                                        : Icons.person,
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
                                              fontWeight:
                                                  FontWeight.w900,
                                              color:
                                                  AppColors.textMain,
                                            ),
                                          ),
                                          if (!isRead) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors
                                                    .primary,
                                                borderRadius:
                                                    BorderRadius
                                                        .circular(20),
                                              ),
                                              child: const Text(
                                                'BARU',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 8,
                                                  fontWeight:
                                                      FontWeight.bold,
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
                                  icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 20),
                                  onPressed: () => _confirmDelete(
                                      context,
                                      feedbackService,
                                      id),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),
                            Divider(
                                color: AppColors.border, height: 1),
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

                            if (!isRead) ...[
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: () =>
                                      feedbackService.markAsRead(id),
                                  child: Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.done,
                                            size: 14,
                                            color: AppColors.primary),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Tandai sudah dibaca',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.primary,
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

  void _confirmDelete(BuildContext context, FeedbackService service,
      String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Saran',
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Hapus saran ini? Tidak bisa dikembalikan.',
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
                    color: Colors.red,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}