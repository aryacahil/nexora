import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider._();
  static final ThemeProvider instance = ThemeProvider._();

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? get uid => _auth.currentUser?.uid;

  Future<void> loadTheme() async {
    if (uid == null) return;
    try {
      final doc = await _db.collection('users').doc(uid).get();
      final data = doc.data() ?? {}; // ← fix: hapus cast
      final settings = data['settings'] as Map<String, dynamic>? ?? {};
      _isDarkMode = settings['dark_mode'] ?? false;
      notifyListeners();
    } catch (e) {
      // ignore
    }
  }

  Future<void> toggleDarkMode(bool value) async {
    _isDarkMode = value;
    notifyListeners();
    if (uid == null) return;
    try {
      await _db.collection('users').doc(uid).update({
        'settings.dark_mode': value,
      });
    } catch (e) {
      // ignore
    }
  }

  void reset() {
    _isDarkMode = false;
    notifyListeners();
  }
}