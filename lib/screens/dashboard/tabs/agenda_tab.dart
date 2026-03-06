import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/colors.dart';

class AgendaTab extends StatelessWidget {
  const AgendaTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 120),
      children: [
        Text('Pengumuman.', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: AppColors.primary)),
        const SizedBox(height: 8),
        Text('Informasi resmi dari pengurus Marga Void', style: TextStyle(fontSize: 12, color: AppColors.textDim)),
        const SizedBox(height: 32),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('announcements')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Icon(Icons.campaign_outlined, size: 48, color: Colors.purple.shade100),
                    const SizedBox(height: 12),
                    Text('Belum ada pengumuman.', style: TextStyle(color: AppColors.textDim)),
                  ],
                ),
              );
            }
            final docs = snapshot.data!.docs;
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final a = docs[index].data() as Map<String, dynamic>;
                final createdAt = a['createdAt'];
                String dateStr = '';
                if (createdAt != null) {
                  final dt = (createdAt as Timestamp).toDate();
                  dateStr = '${dt.day}/${dt.month}/${dt.year}';
                }
                return _buildAnnouncementCard(
                  title: a['title'] ?? '',
                  content: a['content'] ?? '',
                  date: dateStr,
                  createdBy: a['createdBy'] ?? '',
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildAnnouncementCard({
    required String title,
    required String content,
    required String date,
    required String createdBy,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('PENGUMUMAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple.shade700)),
          ),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textMain)),
          const SizedBox(height: 8),
          Text(content, style: TextStyle(fontSize: 13, color: AppColors.textDim, height: 1.5)),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 12, color: AppColors.textDim),
              const SizedBox(width: 4),
              Text(date, style: TextStyle(fontSize: 11, color: AppColors.textDim)),
              const SizedBox(width: 12),
              Icon(Icons.person_outline, size: 12, color: AppColors.textDim),
              const SizedBox(width: 4),
              Text(createdBy, style: TextStyle(fontSize: 11, color: AppColors.textDim)),
            ],
          ),
        ],
      ),
    );
  }
}