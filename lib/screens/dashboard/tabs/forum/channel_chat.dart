import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/colors.dart';
import '../../../../services/chat_service.dart';
import '../../../../services/user_service.dart';
import '../../../../services/notification_service.dart';

class ChannelChat extends StatefulWidget {
  final String channelId;
  final String channelName;
  const ChannelChat({super.key, required this.channelId, required this.channelName});

  @override
  State<ChannelChat> createState() => _ChannelChatState();
}

class _ChannelChatState extends State<ChannelChat> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();
  Map<String, dynamic>? _replyTo;
  String _myName = '';

  @override
  void initState() {
    super.initState();
    _loadMyName();
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMyName() async {
    final profile = await _userService.getMyProfile();
    if (mounted) {
      setState(() => _myName = profile?['name'] ?? 'Anggota');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_msgController.text.trim().isEmpty) return;
    final text = _msgController.text.trim();
    final reply = _replyTo;
    setState(() {
      _msgController.clear();
      _replyTo = null;
    });

    // Kirim pesan ke Firestore
    await _chatService.sendMessage(
      channelId: widget.channelId,
      text: text,
      senderName: _myName,
      replyTo: reply,
    );

    // Kirim notifikasi push ke subscriber diskusi
    await NotificationService.instance.sendDiscussionNotification(
      widget.channelName,
      _myName,
      text,
    );

    _scrollToBottom();
  }

  void _showDeleteDialog(String messageId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hapus Pesan', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textMain)),
        content: Text('Yakin ingin menghapus pesan ini?', style: TextStyle(color: AppColors.textDim)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: AppColors.textDim)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _chatService.deleteMessage(widget.channelId, messageId);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: AppColors.accent, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('# ${widget.channelName}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary)),
            Text('Channel Diskusi', style: TextStyle(fontSize: 10, color: AppColors.textDim)),
          ],
        ),
      ),
      body: Column(
        children: [
          // List pesan
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessages(widget.channelId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: Colors.purple.shade100),
                        const SizedBox(height: 12),
                        Text('Belum ada pesan.\nJadi yang pertama ngobrol!', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textDim, fontSize: 13)),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
                _scrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final msg = docs[index].data() as Map<String, dynamic>;
                    final msgId = docs[index].id;
                    final isMe = _chatService.isMyMessage(msg['uid'] ?? '');
                    final replyTo = msg['replyTo'] as Map<String, dynamic>?;

                    return GestureDetector(
                      onLongPress: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: AppColors.card,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          builder: (_) => Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 40, height: 4,
                                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                                ),
                                const SizedBox(height: 24),
                                ListTile(
                                  leading: Icon(Icons.reply, color: AppColors.accent),
                                  title: Text('Balas Pesan', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain)),
                                  onTap: () {
                                    Navigator.pop(context);
                                    setState(() => _replyTo = {
                                      'id': msgId,
                                      'senderName': msg['senderName'],
                                      'text': msg['text'],
                                    });
                                  },
                                ),
                                if (isMe)
                                  ListTile(
                                    leading: const Icon(Icons.delete_outline, color: Colors.red),
                                    title: const Text('Hapus Pesan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _showDeleteDialog(msgId);
                                    },
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isMe) ...[
                              Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)]),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.person, color: Colors.white, size: 18),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  if (!isMe)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4, left: 4),
                                      child: Text(msg['senderName'] ?? '', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accent)),
                                    ),
                                  Container(
                                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isMe ? AppColors.primary : AppColors.card,
                                      border: isMe ? null : Border.all(color: AppColors.border),
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(16),
                                        topRight: const Radius.circular(16),
                                        bottomLeft: Radius.circular(isMe ? 16 : 0),
                                        bottomRight: Radius.circular(isMe ? 0 : 16),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Quote reply
                                        if (replyTo != null) ...[
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: isMe ? Colors.white.withValues(alpha: 0.15) : Colors.purple.shade50,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border(
                                                left: BorderSide(
                                                  color: isMe ? Colors.white54 : AppColors.accent,
                                                  width: 3,
                                                ),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  replyTo['senderName'] ?? '',
                                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isMe ? Colors.white70 : AppColors.accent),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  replyTo['text'] ?? '',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(fontSize: 11, color: isMe ? Colors.white60 : AppColors.textDim),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                        ],
                                        // Teks pesan
                                        Text(
                                          msg['text'] ?? '',
                                          style: TextStyle(color: isMe ? Colors.white : AppColors.textMain, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Timestamp
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                                    child: Text(
                                      _formatTime(msg['createdAt']),
                                      style: TextStyle(fontSize: 9, color: AppColors.textDim),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Reply preview
          if (_replyTo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Icon(Icons.reply, size: 16, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Membalas ${_replyTo!['senderName']}',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accent),
                        ),
                        Text(
                          _replyTo!['text'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: AppColors.textDim),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _replyTo = null),
                    child: Icon(Icons.close, size: 18, color: AppColors.textDim),
                  ),
                ],
              ),
            ),

          // Input pesan
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            decoration: BoxDecoration(
              color: AppColors.bg,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'Tulis pesan...',
                      hintStyle: TextStyle(fontSize: 14, color: AppColors.textDim),
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final dt = (timestamp as Timestamp).toDate();
      final now = DateTime.now();
      if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}