import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _oneSignalAppId = '';
  static const String _oneSignalRestApiKey = '';

  String? get uid => _auth.currentUser?.uid;

  // ── INIT ──────────────────────────────────────────────

  Future<void> init() async {
    OneSignal.initialize(_oneSignalAppId);
    await OneSignal.Notifications.requestPermission(true);
    await _savePlayerId();
    await applyStoredSettings();
  }

  Future<void> _savePlayerId() async {
    if (uid == null) return;
    try {
      final playerId = OneSignal.User.pushSubscription.id;
      if (playerId != null) {
        await _db.collection('users').doc(uid).update({
          'oneSignalPlayerId': playerId,
        });
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
    await _sendToAllUsers(title: '📢 $title', body: body);
  }

  Future<void> sendDiscussionNotification(
    String channelName,
    String senderName,
    String message,
  ) async {
    final body = message.length > 100
        ? '${message.substring(0, 100)}...'
        : message;
    await _sendOneSignalNotification(
      title: '💬 #$channelName',
      body: '$senderName: $body',
      segment: 'discussion_subscribers',
    );
  }

  // Kirim ke SEMUA user — pakai header "Key" untuk API v2
  Future<void> _sendToAllUsers({
    required String title,
    required String body,
  }) async {
    try {
      print('🔔 Mengirim notifikasi ke semua user...');
      final response = await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Key $_oneSignalRestApiKey', // ← fix: Key bukan Basic
        },
        body: jsonEncode({
          'app_id': _oneSignalAppId,
          'headings': {'en': title, 'id': title},
          'contents': {'en': body, 'id': body},
          'included_segments': ['All'],
        }),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Notifikasi berhasil dikirim: $title');
        await _db.collection('notifications_log').add({
          'title': title,
          'body': body,
          'segment': 'All',
          'sentBy': uid,
          'sentAt': FieldValue.serverTimestamp(),
          'status': 'success',
        });
      } else {
        print('❌ Gagal: ${response.body}');
        await _db.collection('notifications_log').add({
          'title': title,
          'body': body,
          'segment': 'All',
          'sentBy': uid,
          'sentAt': FieldValue.serverTimestamp(),
          'status': 'failed',
          'error': response.body,
        });
      }
    } catch (e) {
      print('❌ Error kirim notifikasi: $e');
    }
  }

  // Kirim ke segment tertentu — pakai header "Key" untuk API v2
  Future<void> _sendOneSignalNotification({
    required String title,
    required String body,
    required String segment,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Key $_oneSignalRestApiKey', // ← fix: Key bukan Basic
        },
        body: jsonEncode({
          'app_id': _oneSignalAppId,
          'headings': {'en': title, 'id': title},
          'contents': {'en': body, 'id': body},
          'filters': [
            {
              'field': 'tag',
              'key': 'segment',
              'relation': '=',
              'value': segment,
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Notifikasi berhasil dikirim ke $segment: $title');
        await _db.collection('notifications_log').add({
          'title': title,
          'body': body,
          'segment': segment,
          'sentBy': uid,
          'sentAt': FieldValue.serverTimestamp(),
          'status': 'success',
        });
      } else {
        print('❌ Gagal: ${response.body}');
        await _db.collection('notifications_log').add({
          'title': title,
          'body': body,
          'segment': segment,
          'sentBy': uid,
          'sentAt': FieldValue.serverTimestamp(),
          'status': 'failed',
          'error': response.body,
        });
      }
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  // ── TAG UNTUK SEGMENTASI ──────────────────────────────

  Future<void> subscribeAnnouncements() async {
    OneSignal.User.addTagWithKey('notif_announcements', 'true');
    OneSignal.User.addTagWithKey('segment', 'announcement_subscribers');
    await _saveNotifSetting('notif_announcements', true);
  }

  Future<void> unsubscribeAnnouncements() async {
    OneSignal.User.removeTag('notif_announcements');
    await _saveNotifSetting('notif_announcements', false);
  }

  Future<void> subscribeDiscussion() async {
    OneSignal.User.addTagWithKey('notif_discussion', 'true');
    OneSignal.User.addTagWithKey('segment', 'discussion_subscribers');
    await _saveNotifSetting('notif_discussion', true);
  }

  Future<void> unsubscribeDiscussion() async {
    OneSignal.User.removeTag('notif_discussion');
    await _saveNotifSetting('notif_discussion', false);
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
      final data = doc.data() ?? {}; // ← fix cast
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
      OneSignal.User.removeTag('notif_announcements');
      OneSignal.User.removeTag('notif_discussion');
      OneSignal.User.removeTag('segment');
      await _db.collection('users').doc(uid).update({
        'oneSignalPlayerId': '',
      });
    } catch (e) {
      print('Error remove token: $e');
    }
  }
}