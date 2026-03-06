import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get uid => _auth.currentUser?.uid;

  // Buat profil baru saat register
  Future<void> createProfile(String email) async {
    if (uid == null) return;
    final existing = await _db.collection('users').doc(uid).get();
    if (!existing.exists) {
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'name': email.split('@')[0],
        'bio': 'Kesunyian adalah kekuatan. Marga Void selamanya.',
        'photoBase64': '',
        'role': 'Member',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Ambil data profil sendiri (Future, bukan stream)
  Future<Map<String, dynamic>?> getMyProfile() async {
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  // Stream profil sendiri (realtime)
  Stream myProfileStream() {
    return _db.collection('users').doc(uid).snapshots();
  }

  // Update profil nama & bio
  Future<void> updateProfile({String? name, String? bio}) async {
    if (uid == null) return;
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (bio != null) data['bio'] = bio;
    await _db.collection('users').doc(uid).update(data);
  }

  // Kompres foto lalu simpan sebagai Base64 ke Firestore
  Future<void> uploadPhotoBase64(File file) async {
    if (uid == null) return;

    final compressed = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      quality: 40,
      minWidth: 300,
      minHeight: 300,
    );

    if (compressed == null) throw Exception('Gagal mengompres foto.');
    if (compressed.length > 700000) {
      throw Exception('Foto terlalu besar, pilih foto yang lebih kecil.');
    }

    final base64Str = base64Encode(compressed);
    await _db.collection('users').doc(uid).update({'photoBase64': base64Str});
  }

  // Ambil semua anggota
  Stream getAllMembers() {
    return _db.collection('users').orderBy('createdAt', descending: false).snapshots();
  }
}