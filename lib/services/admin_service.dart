import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const List<String> ownerEmails = [
    'campgreget2@gmail.com',
  ];

  String get currentEmail => _auth.currentUser?.email ?? '';
  String? get currentUid => _auth.currentUser?.uid;

  bool get isOwnerEmail => ownerEmails.contains(currentEmail);

  Future<String> getMyRole() async {
    if (currentUid == null) return 'Member';
    try {
      if (isOwnerEmail) {
        await _ensureOwnerRole();
        return 'Owner';
      }
      final doc = await _db.collection('users').doc(currentUid).get();
      final data = doc.data() ?? {};
      return data['role'] ?? 'Member';
    } catch (e) {
      return 'Member';
    }
  }

  Future<void> _ensureOwnerRole() async {
    if (currentUid == null) return;
    try {
      await _db.collection('users').doc(currentUid).update({'role': 'Owner'});
    } catch (e) {
      // ignore
    }
  }

  Future<bool> get canAccessAdmin async {
    final role = await getMyRole();
    return role == 'Owner' || role == 'Admin';
  }

  Future<bool> get isOwner async {
    final role = await getMyRole();
    return role == 'Owner';
  }

  String _cachedRole = 'Member';
  String get cachedRole => _cachedRole;
  bool get isAdminOrOwner =>
      _cachedRole == 'Owner' || _cachedRole == 'Admin';
  bool get isOwnerCached => _cachedRole == 'Owner';

  Future<void> loadRole() async {
    _cachedRole = await getMyRole();
  }

  // ── USERS ─────────────────────────────────────────────

  Stream<QuerySnapshot> getAllUsers() {
    return _db
        .collection('users')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Future<void> updateUserRole(String uid, String role) async {
    final myRole = await getMyRole();
    if (myRole == 'Owner') {
      await _db.collection('users').doc(uid).update({'role': role});
      return;
    }
    if (myRole == 'Admin') {
      if (role == 'Admin' || role == 'Owner') {
        throw Exception('Kamu tidak punya izin untuk memberikan role ini.');
      }
      await _db.collection('users').doc(uid).update({'role': role});
      return;
    }
    throw Exception('Akses ditolak.');
  }

  Future<void> deleteUser(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  // ── PANDUAN / RULES ───────────────────────────────────

  Stream<QuerySnapshot> getRules() {
    return _db.collection('rules').orderBy('order').snapshots();
  }

  Future<void> createRule(
    String title,
    String content, {
    String? imageBase64,
    String? link,
  }) async {
    final count = (await _db.collection('rules').get()).docs.length;
    await _db.collection('rules').add({
      'title': title,
      'content': content,
      'imageBase64': imageBase64 ?? '',
      'link': link ?? '',
      'order': count,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateRule(
    String id,
    String title,
    String content, {
    String? imageBase64,
    String? link,
  }) async {
    await _db.collection('rules').doc(id).update({
      'title': title,
      'content': content,
      if (imageBase64 != null) 'imageBase64': imageBase64,
      if (link != null) 'link': link,
    });
  }

  Future<void> deleteRule(String id) async {
    await _db.collection('rules').doc(id).delete();
  }

  // ── CHANNELS ──────────────────────────────────────────

  Stream<QuerySnapshot> getChannels() {
    return _db.collection('channels').orderBy('createdAt').snapshots();
  }

  Future<void> createChannel(String name, String description) async {
    await _db.collection('channels').add({
      'name': name,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateChannel(
      String id, String name, String description) async {
    await _db.collection('channels').doc(id).update({
      'name': name,
      'description': description,
    });
  }

  Future<void> deleteChannel(String id) async {
    await _db.collection('channels').doc(id).delete();
  }

  // ── PENGUMUMAN ────────────────────────────────────────

  Stream<QuerySnapshot> getAnnouncements() {
    return _db
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> createAnnouncement(
    String title,
    String content, {
    String? imageBase64,
    String? link,
  }) async {
    String createdBy = '';
    try {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        final doc = await _db.collection('users').doc(uid).get();
        createdBy =
            doc.data()?['name'] ?? _auth.currentUser?.email ?? '';
      }
    } catch (e) {
      createdBy = _auth.currentUser?.email ?? '';
    }

    await _db.collection('announcements').add({
      'title': title,
      'content': content,
      'imageBase64': imageBase64 ?? '',
      'link': link ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
    });
  }

  Future<void> updateAnnouncement(
    String id,
    String title,
    String content, {
    String? imageBase64,
    String? link,
  }) async {
    await _db.collection('announcements').doc(id).update({
      'title': title,
      'content': content,
      if (imageBase64 != null) 'imageBase64': imageBase64,
      if (link != null) 'link': link,
    });
  }

  Future<void> deleteAnnouncement(String id) async {
    await _db.collection('announcements').doc(id).delete();
  }
}