import 'package:flutter/material.dart';
import '../../../core/colors.dart';
import '../../../core/mock_data.dart';

class AgendaTab extends StatelessWidget {
  const AgendaTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 120),
      children: [
        const Text('Agenda.', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: AppColors.primary)),
        const SizedBox(height: 32),
        ...MockData.events.map((event) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildEventCard(event['type']!, event['title']!, event['date']!, event['time']!),
        )),
      ],
    );
  }

  Widget _buildEventCard(String type, String title, String date, String time) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(20)),
            child: Text(type.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple.shade700)),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textMain)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: AppColors.textDim),
              const SizedBox(width: 6),
              Text(date, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDim)),
              const SizedBox(width: 16),
              const Icon(Icons.access_time, size: 14, color: AppColors.textDim),
              const SizedBox(width: 6),
              Text(time, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDim)),
            ],
          )
        ],
      ),
    );
  }
}