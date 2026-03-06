import 'package:flutter/material.dart';
import '../../../../core/colors.dart';
import '../../../../services/chat_service.dart';
import 'channel_chat.dart';

class ChannelList extends StatefulWidget {
  final VoidCallback onBack;
  const ChannelList({super.key, required this.onBack});

  @override
  State<ChannelList> createState() => _ChannelListState();
}

class _ChannelListState extends State<ChannelList> {
  final ChatService _chatService = ChatService();
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    _seed();
  }

  Future<void> _seed() async {
    await _chatService.seedDefaultChannels();
    setState(() => _seeded = true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
          child: GestureDetector(
            onTap: widget.onBack,
            child: const Row(
              children: [
                Icon(Icons.chevron_left, color: AppColors.accent, size: 20),
                Text('KEMBALI', style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Text('Diskusi.', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: AppColors.primary)),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 4, 24, 16),
          child: Text('Pilih channel untuk mulai berdiskusi', style: TextStyle(fontSize: 12, color: AppColors.textDim)),
        ),
        Expanded(
          child: !_seeded
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : StreamBuilder(
                  stream: _chatService.getChannels(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('Belum ada channel.', style: TextStyle(color: AppColors.textDim)));
                    }

                    final channels = snapshot.data!.docs;
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                      itemCount: channels.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final ch = channels[index].data() as Map<String, dynamic>;
                        final channelId = channels[index].id;
                        final name = ch['name'] ?? '';
                        final description = ch['description'] ?? '';

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChannelChat(
                                  channelId: channelId,
                                  channelName: name,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(Icons.tag, color: AppColors.accent, size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('# $name', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textMain)),
                                      const SizedBox(height: 4),
                                      Text(description, style: TextStyle(fontSize: 12, color: AppColors.textDim)),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: AppColors.border, size: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}