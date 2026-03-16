import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class PostService {
  final FirebaseFirestore _db   = FirebaseFirestore.instance;
  final FirebaseAuth      _auth = FirebaseAuth.instance;

  String? get uid => _auth.currentUser?.uid;

  // ── Buat post baru ────────────────────────────────────────────────────────

  Future<void> createPost({
    required File   imageFile,
    required String caption,
    required String userName,
    required String userPhotoBase64,
  }) async {
    if (uid == null) return;

    final compressed = await FlutterImageCompress.compressWithFile(
      imageFile.path,
      quality: 55,
      minWidth: 800,
      minHeight: 800,
    );
    if (compressed == null) throw Exception('Gagal mengompresi foto.');
    if (compressed.length > 900000) {
      throw Exception('Foto terlalu besar. Pilih foto lain yang lebih kecil.');
    }

    await _db.collection('posts').add({
      'uid'            : uid,
      'userName'       : userName,
      'userPhotoBase64': userPhotoBase64,
      'caption'        : caption,
      'imageBase64'    : base64Encode(compressed),
      'likeCount'      : 0,
      'commentCount'   : 0,
      'createdAt'      : FieldValue.serverTimestamp(),
    });
  }

  // ── Hapus post ────────────────────────────────────────────────────────────

  Future<void> deletePost(String postId) async {
    final comments = await _db.collection('posts').doc(postId)
        .collection('comments').get();
    for (final d in comments.docs) await d.reference.delete();

    final likes = await _db.collection('posts').doc(postId)
        .collection('likes').get();
    for (final d in likes.docs) await d.reference.delete();

    await _db.collection('posts').doc(postId).delete();
  }

  // ── Like / Unlike ─────────────────────────────────────────────────────────

  Future<void> toggleLike(String postId) async {
    if (uid == null) return;
    final likeRef = _db.collection('posts').doc(postId).collection('likes').doc(uid);
    final postRef = _db.collection('posts').doc(postId);
    final exists  = (await likeRef.get()).exists;
    final batch   = _db.batch();
    if (exists) {
      batch.delete(likeRef);
      batch.update(postRef, {'likeCount': FieldValue.increment(-1)});
    } else {
      batch.set(likeRef, {'uid': uid, 'likedAt': FieldValue.serverTimestamp()});
      batch.update(postRef, {'likeCount': FieldValue.increment(1)});
    }
    await batch.commit();
  }

  Stream<bool> isLikedStream(String postId) {
    if (uid == null) return Stream.value(false);
    return _db.collection('posts').doc(postId).collection('likes').doc(uid)
        .snapshots().map((d) => d.exists);
  }

  // ── Komentar ──────────────────────────────────────────────────────────────

  Future<void> addComment({
    required String postId,
    required String text,
    required String userName,
    required String userPhotoBase64,
  }) async {
    if (uid == null || text.trim().isEmpty) return;
    final batch      = _db.batch();
    final commentRef = _db.collection('posts').doc(postId)
        .collection('comments').doc();
    batch.set(commentRef, {
      'uid'            : uid,
      'userName'       : userName,
      'userPhotoBase64': userPhotoBase64,
      'text'           : text.trim(),
      'createdAt'      : FieldValue.serverTimestamp(),
    });
    batch.update(_db.collection('posts').doc(postId),
        {'commentCount': FieldValue.increment(1)});
    await batch.commit();
  }

  Future<void> deleteComment(String postId, String commentId) async {
    final batch = _db.batch();
    batch.delete(_db.collection('posts').doc(postId)
        .collection('comments').doc(commentId));
    batch.update(_db.collection('posts').doc(postId),
        {'commentCount': FieldValue.increment(-1)});
    await batch.commit();
  }

  Stream<QuerySnapshot> getComments(String postId) => _db
      .collection('posts').doc(postId)
      .collection('comments')
      .orderBy('createdAt', descending: false)
      .snapshots();

  // ── Streams ───────────────────────────────────────────────────────────────

  // Tanpa orderBy agar tidak butuh composite index.
  // Sorting dilakukan di client side (UI).
  Stream<QuerySnapshot> getUserPosts(String userUid) => _db
      .collection('posts')
      .where('uid', isEqualTo: userUid)
      .snapshots();

  // Stream 1 post untuk likeCount realtime
  Stream<DocumentSnapshot> getPostStream(String postId) => _db
      .collection('posts')
      .doc(postId)
      .snapshots();
}