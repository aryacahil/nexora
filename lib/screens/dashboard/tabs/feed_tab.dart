import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/colors.dart';
import '../../../services/post_service.dart';
import '../../../services/user_service.dart';
import '../../../services/notification_service.dart';
import '../../profile/post_detail_screen.dart';

class FeedTab extends StatefulWidget {
  const FeedTab({super.key});

  @override
  State<FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<FeedTab> {
  final PostService  _postService  = PostService();
  final UserService  _userService  = UserService();
  final ScrollController _scrollCtrl = ScrollController();

  String _myName    = '';
  String _myPhoto   = '';
  String _myUid     = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final p = await _userService.getMyProfile();
    if (mounted) {
      setState(() {
        _myName  = p?['name']        ?? 'Anggota';
        _myPhoto = p?['photoBase64'] ?? '';
        _myUid   = _postService.uid  ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return _buildEmptyState();
          }

          return CustomScrollView(
            controller: _scrollCtrl,
            slivers: [
              // ── App Bar ─────────────────────────────────────────────
              SliverAppBar(
                backgroundColor: AppColors.bg,
                floating: true,
                snap: true,
                elevation: 0,
                title: Row(
                  children: [
                    Text(
                      'Feeds.',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${docs.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Feed List ────────────────────────────────────────────
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post =
                        docs[index].data() as Map<String, dynamic>;
                    final postId = docs[index].id;
                    return _FeedCard(
                      postId    : postId,
                      post      : post,
                      myUid     : _myUid,
                      myName    : _myName,
                      myPhoto   : _myPhoto,
                      postService: _postService,
                    );
                  },
                  childCount: docs.length,
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 120),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: AppColors.bg,
          floating: true,
          snap: true,
          elevation: 0,
          title: Text(
            'Feeds.',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: AppColors.primary,
            ),
          ),
        ),
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.photo_library_outlined,
                    size: 44,
                    color: AppColors.primary.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Belum ada postingan.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Jadilah yang pertama berbagi foto!',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textDim,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feed Card Widget
// ─────────────────────────────────────────────────────────────────────────────

class _FeedCard extends StatefulWidget {
  final String              postId;
  final Map<String, dynamic> post;
  final String              myUid;
  final String              myName;
  final String              myPhoto;
  final PostService         postService;

  const _FeedCard({
    required this.postId,
    required this.post,
    required this.myUid,
    required this.myName,
    required this.myPhoto,
    required this.postService,
  });

  @override
  State<_FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<_FeedCard>
    with SingleTickerProviderStateMixin {
  bool _showHeart = false;
  late AnimationController _heartCtrl;
  late Animation<double>   _heartAnim;

  @override
  void initState() {
    super.initState();
    _heartCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _heartAnim = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1.4)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.4, end: 0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
    ]).animate(_heartCtrl);
  }

  @override
  void dispose() {
    _heartCtrl.dispose();
    super.dispose();
  }

  Future<void> _onDoubleTap() async {
    final postOwnerUid = widget.post['uid'] as String? ?? '';
    final postCaption  = widget.post['caption'] as String? ?? '';
    final wasLiked =
        await widget.postService.isLikedStream(widget.postId).first;

    if (!wasLiked) {
      await widget.postService.toggleLike(widget.postId);
      if (postOwnerUid.isNotEmpty) {
        NotificationService.instance.sendLikeNotification(
          postOwnerUid: postOwnerUid,
          likerName:    widget.myName,
          postCaption:  postCaption,
        );
      }
    }

    setState(() => _showHeart = true);
    _heartCtrl.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _showHeart = false);
  }

  Future<void> _toggleLike() async {
    final postOwnerUid = widget.post['uid'] as String? ?? '';
    final postCaption  = widget.post['caption'] as String? ?? '';
    final wasLiked =
        await widget.postService.isLikedStream(widget.postId).first;

    await widget.postService.toggleLike(widget.postId);

    if (!wasLiked && postOwnerUid.isNotEmpty) {
      NotificationService.instance.sendLikeNotification(
        postOwnerUid: postOwnerUid,
        likerName:    widget.myName,
        postCaption:  postCaption,
      );
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

  Widget _avatar(String photo, String name, {double size = 38}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)],
        ),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      padding: const EdgeInsets.all(2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: photo.isNotEmpty
            ? Image.memory(base64Decode(photo), fit: BoxFit.cover)
            : Container(
                color: Colors.purple.shade100,
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: Colors.purple.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: size * 0.38,
                    ),
                  ),
                ),
              ),
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
    final isOwner     = post['uid'] == widget.myUid;

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 10),
            child: Row(
              children: [
                _avatar(userPhoto, userName),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textMain,
                        ),
                      ),
                      Text(
                        _timeAgo(post['createdAt']),
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textDim,
                        ),
                      ),
                    ],
                  ),
                ),
                // Menu (hapus) jika milik sendiri
                if (isOwner)
                  IconButton(
                    icon: Icon(Icons.more_horiz,
                        color: AppColors.textDim, size: 22),
                    onPressed: () => _showOptionsSheet(context),
                  ),
              ],
            ),
          ),

          // ── Foto ─────────────────────────────────────────────────────
          if (imageBase64.isNotEmpty)
            GestureDetector(
              onDoubleTap: _onDoubleTap,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PostDetailScreen(
                    postId : widget.postId,
                    post   : widget.post,
                    isOwner: isOwner,
                  ),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.memory(
                    base64Decode(imageBase64),
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  // Animasi hati double-tap
                  if (_showHeart)
                    AnimatedBuilder(
                      animation: _heartAnim,
                      builder: (_, __) => Transform.scale(
                        scale: _heartAnim.value,
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 100,
                          shadows: [
                            Shadow(color: Colors.black38, blurRadius: 16)
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // ── Actions (like, komentar, share) ──────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                // Like button
                StreamBuilder<bool>(
                  stream: widget.postService
                      .isLikedStream(widget.postId),
                  builder: (ctx, likeSnap) {
                    final liked = likeSnap.data ?? false;
                    return GestureDetector(
                      onTap: _toggleLike,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, anim) =>
                            ScaleTransition(scale: anim, child: child),
                        child: Icon(
                          liked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          key: ValueKey(liked),
                          color: liked ? Colors.red : AppColors.textDim,
                          size: 26,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 4),

                // Like count (realtime)
                StreamBuilder<DocumentSnapshot>(
                  stream: widget.postService
                      .getPostStream(widget.postId),
                  builder: (ctx, snap) {
                    final d = snap.data?.data()
                        as Map<String, dynamic>?;
                    final likes =
                        d?['likeCount'] ?? post['likeCount'] ?? 0;
                    return Text(
                      '$likes',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    );
                  },
                ),

                const SizedBox(width: 16),

                // Komentar button
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PostDetailScreen(
                        postId           : widget.postId,
                        post             : widget.post,
                        isOwner          : isOwner,
                        autoFocusComment : true,
                      ),
                    ),
                  ),
                  child: Icon(Icons.chat_bubble_outline_rounded,
                      color: AppColors.textDim, size: 24),
                ),
                const SizedBox(width: 4),

                // Comment count (realtime)
                StreamBuilder<DocumentSnapshot>(
                  stream: widget.postService
                      .getPostStream(widget.postId),
                  builder: (ctx, snap) {
                    final d = snap.data?.data()
                        as Map<String, dynamic>?;
                    final comments =
                        d?['commentCount'] ?? post['commentCount'] ?? 0;
                    return Text(
                      '$comments',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    );
                  },
                ),

                const Spacer(),

                // Tap untuk buka detail
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PostDetailScreen(
                        postId : widget.postId,
                        post   : widget.post,
                        isOwner: isOwner,
                      ),
                    ),
                  ),
                  child: Icon(Icons.open_in_new_rounded,
                      color: AppColors.textDim, size: 20),
                ),
              ],
            ),
          ),

          // ── Caption ──────────────────────────────────────────────────
          if (caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
              child: RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text: '$userName ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textMain,
                    ),
                  ),
                  TextSpan(
                    text: caption,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMain,
                      height: 1.4,
                    ),
                  ),
                ]),
              ),
            )
          else
            const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _showOptionsSheet(BuildContext context) {
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
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                'Hapus Postingan',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.close, color: AppColors.textDim),
              title: Text(
                'Batal',
                style: TextStyle(color: AppColors.textDim),
              ),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Postingan',
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text(
          'Postingan ini akan dihapus permanen.',
          style: TextStyle(color: AppColors.textDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal',
                style: TextStyle(color: AppColors.textDim)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await widget.postService.deletePost(widget.postId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Postingan dihapus.'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
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