import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _oneSignalAppId = '';
  static const String _oneSignalRestApiKey = '';

  String? get uid => _auth.currentUser?.uid;
  bool _initialized = false;

  // ── INIT ──────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    OneSignal.initialize(_oneSignalAppId);
    await OneSignal.Notifications.requestPermission(true);
    await Future.delayed(const Duration(seconds: 2));
    await _savePlayerId();
    await applyStoredSettings();
  }

  Future<void> _savePlayerId() async {
    if (uid == null) return;
    try {
      final playerId = OneSignal.User.pushSubscription.id;
      if (playerId != null && playerId.isNotEmpty) {
        await _db.collection('users').doc(uid).update({
          'oneSignalPlayerId': playerId,
        });
        print('✅ Player ID tersimpan: $playerId');
      }
    } catch (e) {
      print('Error save player ID: $e');
    }
  }

  // ── KIRIM NOTIFIKASI ──────────────────────────────────

  Future<void> sendAnnouncementNotification(String title, String content) async {
    final body = content.length > 100
        ? '${content.substring(0, 100)}...'
        : content;
    await _sendToAllUsers(title: title, body: body);
  }

  Future<void> sendDiscussionNotification(
    String channelName,
    String senderName,
    String message,
  ) async {
    final body = message.length > 100
        ? '${message.substring(0, 100)}...'
        : message;
    await _sendToDiscussionSubscribers(
      title: '#$channelName',
      body: '$senderName: $body',
    );
  }

  // Kirim ke semua user — untuk pengumuman
  Future<void> _sendToAllUsers({
    required String title,
    required String body,
  }) async {
    try {
      print('🔔 Mengirim notifikasi pengumuman...');

      final safeBody = body.isEmpty ? 'Notifikasi baru' : body;
      final safeTitle = title.isEmpty ? 'Marga Void' : title;

      final payload = {
        'app_id': _oneSignalAppId,
        'headings': {'en': safeTitle},
        'contents': {'en': safeBody},
        'included_segments': ['All'],
      };

      final response = await http.post(
        Uri.parse('https://api.onesignal.com/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_oneSignalRestApiKey',
        },
        body: jsonEncode(payload),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Notifikasi pengumuman berhasil dikirim: $safeTitle');
      } else {
        print('❌ Gagal kirim pengumuman: ${response.body}');
      }
    } catch (e) {
      print('❌ Error kirim notifikasi: $e');
    }
  }

  // Kirim ke subscriber diskusi — filter by tag notif_discussion=true
  Future<void> _sendToDiscussionSubscribers({
    required String title,
    required String body,
  }) async {
    try {
      print('🔔 Mengirim notifikasi diskusi...');

      final safeBody = body.isEmpty ? 'Pesan baru' : body;
      final safeTitle = title.isEmpty ? 'Marga Void' : title;

      final payload = {
        'app_id': _oneSignalAppId,
        'headings': {'en': safeTitle},
        'contents': {'en': safeBody},
        'filters': [
          {
            'field': 'tag',
            'key': 'notif_discussion',
            'relation': '=',
            'value': 'true',
          },
        ],
      };

      final response = await http.post(
        Uri.parse('https://api.onesignal.com/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_oneSignalRestApiKey',
        },
        body: jsonEncode(payload),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Notifikasi diskusi berhasil dikirim: $safeTitle');
      } else {
        print('❌ Gagal kirim diskusi: ${response.body}');
      }
    } catch (e) {
      print('❌ Error kirim notifikasi diskusi: $e');
    }
  }

  // ── TAG UNTUK SEGMENTASI ──────────────────────────────

  Future<void> subscribeAnnouncements() async {
    OneSignal.User.addTagWithKey('notif_announcements', 'true');
    await _saveNotifSetting('notif_announcements', true);
    print('✅ Subscribe announcements');
  }

  Future<void> unsubscribeAnnouncements() async {
    OneSignal.User.addTagWithKey('notif_announcements', 'false');
    await _saveNotifSetting('notif_announcements', false);
    print('✅ Unsubscribe announcements');
  }

  Future<void> subscribeDiscussion() async {
    OneSignal.User.addTagWithKey('notif_discussion', 'true');
    await _saveNotifSetting('notif_discussion', true);
    print('✅ Subscribe discussion');
  }

  Future<void> unsubscribeDiscussion() async {
    OneSignal.User.addTagWithKey('notif_discussion', 'false');
    await _saveNotifSetting('notif_discussion', false);
    print('✅ Unsubscribe discussion');
  }

  // ── SETTINGS ──────────────────────────────────────────

  Future<void> _saveNotifSetting(String key, bool value) async {
    if (uid == null) return;
    try {
      await _db.collection('users').doc(uid).update({
        'settings.$key': value,
      });
    } catch (e) {
      print('Error save notif setting: $e');
    }
  }

  Future<Map<String, bool>> getNotifSettings() async {
    if (uid == null) return {};
    try {
      final doc = await _db.collection('users').doc(uid).get();
      final data = doc.data() ?? {};
      final settings = data['settings'] as Map<String, dynamic>? ?? {};
      return {
        'notif_announcements': settings['notif_announcements'] ?? true,
        'notif_discussion': settings['notif_discussion'] ?? true,
      };
    } catch (e) {
      return {
        'notif_announcements': true,
        'notif_discussion': true,
      };
    }
  }

  Future<void> applyStoredSettings() async {
    try {
      final settings = await getNotifSettings();
      if (settings['notif_announcements'] == true) {
        await subscribeAnnouncements();
      } else {
        await unsubscribeAnnouncements();
      }
      if (settings['notif_discussion'] == true) {
        await subscribeDiscussion();
      } else {
        await unsubscribeDiscussion();
      }
    } catch (e) {
      print('Error apply settings: $e');
    }
  }

  Future<void> removeFcmToken() async {
    if (uid == null) return;
    try {
      _initialized = false;
      OneSignal.User.addTagWithKey('notif_announcements', 'false');
      OneSignal.User.addTagWithKey('notif_discussion', 'false');
      await _db.collection('users').doc(uid).update({
        'oneSignalPlayerId': '',
      });
    } catch (e) {
      print('Error remove token: $e');
    }
  }
}