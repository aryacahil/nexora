import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Email yang otomatis jadi Owner
  static const List<String> ownerEmails = [
    'campgreget2@gmail.com',
    // tambahkan email owner lain di sini
  ];

  String get currentEmail => _auth.currentUser?.email ?? '';
  String? get currentUid => _auth.currentUser?.uid;

  // Cek apakah email ini adalah owner
  bool get isOwnerEmail => ownerEmails.contains(currentEmail);

  // Cek role dari Firestore (async)
  Future<String> getMyRole() async {
    if (currentUid == null) return 'Member';
    try {
      // Kalau email owner, pastikan role di Firestore juga Owner
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

  // Pastikan owner email selalu punya role Owner di Firestore
  Future<void> _ensureOwnerRole() async {
    if (currentUid == null) return;
    try {
      await _db.collection('users').doc(currentUid).update({'role': 'Owner'});
    } catch (e) {
      // ignore
    }
  }

  // Cek apakah bisa akses admin (Owner atau Admin)
  Future<bool> get canAccessAdmin async {
    final role = await getMyRole();
    return role == 'Owner' || role == 'Admin';
  }

  // Cek apakah Owner
  Future<bool> get isOwner async {
    final role = await getMyRole();
    return role == 'Owner';
  }

  // Cek sync (dari cache local, untuk UI cepat)
  // Gunakan ini setelah loadRole() dipanggil
  String _cachedRole = 'Member';
  String get cachedRole => _cachedRole;
  bool get isAdminOrOwner => _cachedRole == 'Owner' || _cachedRole == 'Admin';
  bool get isOwnerCached => _cachedRole == 'Owner';

  Future<void> loadRole() async {
    _cachedRole = await getMyRole();
  }

  // ── USERS ─────────────────────────────────────────────

  Stream<QuerySnapshot> getAllUsers() {
    return _db.collection('users').orderBy('createdAt', descending: false).snapshots();
  }

  // Hanya Owner yang bisa ubah role ke Admin/Owner
  Future<void> updateUserRole(String uid, String role) async {
    final myRole = await getMyRole();

    // Owner bisa set semua role
    if (myRole == 'Owner') {
      await _db.collection('users').doc(uid).update({'role': role});
      return;
    }

    // Admin hanya bisa set Member dan Member Senior
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

  Future<void> createRule(String title, String content) async {
    final count = (await _db.collection('rules').get()).docs.length;
    await _db.collection('rules').add({
      'title': title,
      'content': content,
      'order': count,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateRule(String id, String title, String content) async {
    await _db.collection('rules').doc(id).update({
      'title': title,
      'content': content,
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

  Future<void> updateChannel(String id, String name, String description) async {
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
    return _db.collection('announcements').orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> createAnnouncement(String title, String content) async {
    await _db.collection('announcements').add({
      'title': title,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': _auth.currentUser?.email ?? '',
    });
  }

  Future<void> updateAnnouncement(String id, String title, String content) async {
    await _db.collection('announcements').doc(id).update({
      'title': title,
      'content': content,
    });
  }

  Future<void> deleteAnnouncement(String id) async {
    await _db.collection('announcements').doc(id).delete();
  }
}