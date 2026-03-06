import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'user_service.dart';
import 'notification_service.dart';
import '../core/theme_provider.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final UserService _userService = UserService();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> loginWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _initAfterLogin();
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<UserCredential?> registerWithEmail(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _userService.createProfile(email);
      await _initAfterLogin();
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<UserCredential?> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final result = await _auth.signInWithCredential(credential);
      await _userService.createProfile(googleUser.email);
      await _initAfterLogin();
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> _initAfterLogin() async {
    try {
      // Init notifikasi
      await NotificationService.instance.init();
      await NotificationService.instance.applyStoredSettings();
      // Load tema tersimpan
      await ThemeProvider.instance.loadTheme();
    } catch (e) {
      // ignore agar login tetap jalan
    }
  }

  Future<void> logout() async {
    try {
      await NotificationService.instance.removeFcmToken();
      ThemeProvider.instance.reset();
    } catch (e) {
      // ignore
    }
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found': return 'Akun tidak ditemukan.';
      case 'wrong-password': return 'Sandi salah.';
      case 'email-already-in-use': return 'Email sudah digunakan.';
      case 'weak-password': return 'Sandi terlalu lemah (min. 6 karakter).';
      case 'invalid-email': return 'Format email tidak valid.';
      case 'network-request-failed': return 'Koneksi internet bermasalah.';
      default: return 'Terjadi kesalahan: ${e.message}';
    }
  }
}