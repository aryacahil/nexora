import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/colors.dart';
import '../../../services/post_service.dart';
import '../../../services/user_service.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> post;
  final bool isOwner;
  final bool autoFocusComment;

  const PostDetailScreen({
    super.key,
    required this.postId,
    required this.post,
    this.isOwner = false,
    this.autoFocusComment = false,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen>
    with SingleTickerProviderStateMixin {
  final PostService           _postService  = PostService();
  final UserService           _userService  = UserService();
  final TextEditingController _commentCtrl  = TextEditingController();
  final FocusNode             _commentFocus = FocusNode();
  final ScrollController      _scrollCtrl   = ScrollController();

  String _myName    = '';
  String _myPhoto   = '';
  bool   _isSending = false;
  bool   _showHeart = false;

  late AnimationController _heartCtrl;
  late Animation<double>   _heartAnim;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _heartCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));
    _heartAnim = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1.3)
            .chain(CurveTween(curve: Curves.elasticOut)), weight: 60),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 0)
            .chain(CurveTween(curve: Curves.easeIn)), weight: 40),
    ]).animate(_heartCtrl);
    if (widget.autoFocusComment) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _commentFocus.requestFocus());
    }
  }

  @override
  void dispose() {
    _heartCtrl.dispose();
    _commentCtrl.dispose();
    _commentFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final p = await _userService.getMyProfile();
    if (mounted) setState(() {
      _myName  = p?['name']        ?? 'Anggota';
      _myPhoto = p?['photoBase64'] ?? '';
    });
  }

  Future<void> _onDoubleTap() async {
    // Cek status like saat ini
    final liked = (await _postService.isLikedStream(widget.postId).first);
    if (!liked) { await _postService.toggleLike(widget.postId); }
    // Selalu tampilkan animasi hati
    setState(() => _showHeart = true);
    _heartCtrl.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _showHeart = false);
  }

  Future<void> _sendComment() async {
    if (_commentCtrl.text.trim().isEmpty) return;
    setState(() => _isSending = true);
    try {
      await _postService.addComment(
        postId          : widget.postId,
        text            : _commentCtrl.text.trim(),
        userName        : _myName,
        userPhotoBase64 : _myPhoto,
      );
      _commentCtrl.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _timeAgo(dynamic ts) {
    if (ts == null) return '';
    final dt   = (ts as Timestamp).toDate();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24)   return '${diff.inHours}j lalu';
    if (diff.inDays < 7)     return '${diff.inDays}h lalu';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Widget _avatar(String photo, {double size = 36}) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)]),
        borderRadius: BorderRadius.circular(size * 0.32)),
      padding: const EdgeInsets.all(1.5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.3),
        child: photo.isNotEmpty
            ? Image.memory(base64Decode(photo), fit: BoxFit.cover)
            : Container(color: Colors.purple.shade100,
                child: Icon(Icons.person, color: Colors.purple, size: size * 0.5)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post        = widget.post;
    final imageBase64 = post['imageBase64']     ?? '';
    final caption     = post['caption']         ?? '';
    final userName    = post['userName']        ?? 'Anggota';
    final userPhoto   = post['userPhotoBase64'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: AppColors.accent, size: 32),
          onPressed: () => Navigator.pop(context)),
        title: Text('Postingan', style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary)),
      ),
      body: Column(children: [

        Expanded(
          child: ListView(
            controller: _scrollCtrl,
            children: [

              // ── Header ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Row(children: [
                  _avatar(userPhoto, size: 44),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userName, style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w900,
                        color: AppColors.textMain)),
                      Text(_timeAgo(post['createdAt']),
                        style: TextStyle(fontSize: 11, color: AppColors.textDim)),
                    ],
                  )),
                ]),
              ),

              // ── Foto (double tap = like) ─────────────────────────────
              if (imageBase64.isNotEmpty)
                GestureDetector(
                  onDoubleTap: _onDoubleTap,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.memory(base64Decode(imageBase64),
                        width: double.infinity, fit: BoxFit.cover),
                      if (_showHeart)
                        AnimatedBuilder(
                          animation: _heartAnim,
                          builder: (_, __) => Transform.scale(
                            scale: _heartAnim.value,
                            child: const Icon(Icons.favorite,
                              color: Colors.white, size: 90,
                              shadows: [Shadow(
                                color: Colors.black38, blurRadius: 12)]),
                          ),
                        ),
                    ],
                  ),
                ),

              // ── Like (realtime) ────────────────────────────────────────
              StreamBuilder(
                stream: _postService.getPostStream(widget.postId),
                builder: (ctx, snap) {
                  final postData  = snap.data?.data() as Map<String, dynamic>?
                      ?? widget.post;
                  final realLikes = postData['likeCount'] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(children: [
                      StreamBuilder<bool>(
                        stream: _postService.isLikedStream(widget.postId),
                        builder: (ctx2, likeSnap) {
                          final liked = likeSnap.data ?? false;
                          return GestureDetector(
                            onTap: () => _postService.toggleLike(widget.postId),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                liked ? Icons.favorite : Icons.favorite_border,
                                key: ValueKey(liked),
                                color: liked ? Colors.red : AppColors.textDim,
                                size: 26),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      Text('$realLikes suka', style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold,
                        color: AppColors.textMain)),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => _commentFocus.requestFocus(),
                        child: Icon(Icons.chat_bubble_outline,
                          color: AppColors.textDim, size: 24)),
                    ]),
                  );
                },
              ),

              // ── Caption ─────────────────────────────────────────────────
              if (caption.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: RichText(text: TextSpan(children: [
                    TextSpan(text: '$userName ',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900,
                        color: AppColors.textMain)),
                    TextSpan(text: caption,
                      style: TextStyle(fontSize: 13,
                        color: AppColors.textMain, height: 1.5)),
                  ])),
                ),

              // ── Header komentar ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Row(children: [
                  Text('KOMENTAR', style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w900,
                    letterSpacing: 2, color: AppColors.textDim)),
                  const SizedBox(width: 8),
                  Expanded(child: Divider(color: AppColors.border)),
                ]),
              ),

              // ── List komentar ────────────────────────────────────────────
              StreamBuilder<QuerySnapshot>(
                stream: _postService.getComments(widget.postId),
                builder: (context, snap) {
                  if (!snap.hasData || snap.data!.docs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: Text(
                        'Belum ada komentar. Jadilah yang pertama! 💬',
                        style: TextStyle(fontSize: 12,
                          color: AppColors.textDim,
                          fontStyle: FontStyle.italic)),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: snap.data!.docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, i) {
                      final c         = snap.data!.docs[i].data()
                          as Map<String, dynamic>;
                      final commentId = snap.data!.docs[i].id;
                      final isMine    = c['uid'] == _postService.uid;

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _avatar(c['userPhotoBase64'] ?? '', size: 32),
                          const SizedBox(width: 10),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.bg,
                                  borderRadius: BorderRadius.circular(12)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c['userName'] ?? '',
                                      style: TextStyle(fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.textMain)),
                                    const SizedBox(height: 2),
                                    Text(c['text'] ?? '',
                                      style: TextStyle(fontSize: 13,
                                        color: AppColors.textMain, height: 1.4)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(children: [
                                Text(_timeAgo(c['createdAt']),
                                  style: TextStyle(fontSize: 10,
                                    color: AppColors.textDim)),
                                if (isMine || widget.isOwner) ...[
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () => _postService.deleteComment(
                                      widget.postId, commentId),
                                    child: Text('Hapus',
                                      style: TextStyle(fontSize: 10,
                                        color: Colors.red.shade400,
                                        fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ]),
                            ],
                          )),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),

        // ── Input komentar ─────────────────────────────────────────────────
        Container(
          padding: EdgeInsets.fromLTRB(16, 10, 16,
            MediaQuery.of(context).viewInsets.bottom + 16),
          decoration: BoxDecoration(
            color: AppColors.bg,
            border: Border(top: BorderSide(color: AppColors.border))),
          child: Row(children: [
            _avatar(_myPhoto, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _commentCtrl,
                focusNode: _commentFocus,
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendComment(),
                decoration: InputDecoration(
                  hintText: 'Tulis komentar...',
                  hintStyle: TextStyle(color: AppColors.textDim, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.card,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _isSending ? null : _sendComment,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
                child: _isSending
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded,
                        color: Colors.white, size: 18),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}