import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get uid => _auth.currentUser?.uid;

  Future<void> sendFeedback({
    required String message,
    required String senderName,
    bool isAnonymous = false,
  }) async {
    await _db.collection('feedbacks').add({
      'message': message,
      'senderName': isAnonymous ? 'Anonim' : senderName,
      'senderUid': isAnonymous ? '' : uid,
      'isAnonymous': isAnonymous,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getAllFeedbacks() {
    return _db
        .collection('feedbacks')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getUnreadFeedbacks() {
    return _db
        .collection('feedbacks')
        .where('isRead', isEqualTo: false)
        .snapshots();
  }

  Future<void> markAsRead(String id) async {
    await _db.collection('feedbacks').doc(id).update({'isRead': true});
  }

  Future<void> markAllAsRead(List<QueryDocumentSnapshot> docs) async {
    for (final doc in docs) {
      await _db.collection('feedbacks').doc(doc.id).update({'isRead': true});
    }
  }

  Future<void> deleteFeedback(String id) async {
    await _db.collection('feedbacks').doc(id).delete();
  }

  Stream<int> unreadCount() {
    return _db
        .collection('feedbacks')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }
}