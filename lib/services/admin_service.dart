import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ⚠️ GANTI dengan email admin kamu
  static const List<String> adminEmails = [
    'campgreget2@gmail.com',
    // tambahkan email lain di sini
  ];

  bool get isAdmin {
    final email = _auth.currentUser?.email ?? '';
    return adminEmails.contains(email);
  }

  // ── USERS ─────────────────────────────────────────────

  Stream<QuerySnapshot> getAllUsers() {
    return _db.collection('users').orderBy('createdAt', descending: false).snapshots();
  }

  Future<void> updateUserRole(String uid, String role) async {
    await _db.collection('users').doc(uid).update({'role': role});
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