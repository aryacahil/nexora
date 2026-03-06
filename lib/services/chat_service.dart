import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get uid => _auth.currentUser?.uid;

  // ── CHANNELS ──────────────────────────────────────────

  // Ambil semua channel
  Stream<QuerySnapshot> getChannels() {
    return _db.collection('channels').orderBy('createdAt').snapshots();
  }

  // Buat channel baru (admin)
  Future<void> createChannel(String name, String description) async {
    await _db.collection('channels').add({
      'name': name,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': uid,
    });
  }

  // Seed channel default kalau belum ada
  Future<void> seedDefaultChannels() async {
    final snapshot = await _db.collection('channels').limit(1).get();
    if (snapshot.docs.isEmpty) {
      final defaults = [
        {'name': 'umum', 'description': 'Obrolan umum Marga Void'},
        {'name': 'mabar', 'description': 'Koordinasi main bareng'},
        {'name': 'pengumuman', 'description': 'Info resmi dari pengurus'},
      ];
      for (final ch in defaults) {
        await _db.collection('channels').add({
          ...ch,
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': uid,
        });
      }
    }
  }

  // ── MESSAGES ──────────────────────────────────────────

  // Stream pesan realtime
  Stream<QuerySnapshot> getMessages(String channelId) {
    return _db
        .collection('channels')
        .doc(channelId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  // Kirim pesan
  Future<void> sendMessage({
    required String channelId,
    required String text,
    required String senderName,
    Map<String, dynamic>? replyTo,
  }) async {
    if (uid == null || text.trim().isEmpty) return;
    await _db
        .collection('channels')
        .doc(channelId)
        .collection('messages')
        .add({
      'uid': uid,
      'senderName': senderName,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'replyTo': replyTo,
    });
  }

  // Hapus pesan (hanya milik sendiri)
  Future<void> deleteMessage(String channelId, String messageId) async {
    await _db
        .collection('channels')
        .doc(channelId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  bool isMyMessage(String messageUid) => messageUid == uid;
}