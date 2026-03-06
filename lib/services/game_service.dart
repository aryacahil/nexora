import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GameService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get uid => _auth.currentUser?.uid;

  // Buat room baru
  Future<String> createRoom(String playerName) async {
    final roomCode = _generateCode();
    await _db.collection('game_rooms').doc(roomCode).set({
      'code': roomCode,
      'status': 'waiting',
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': uid,
      'currentTurn': 0,
      'bulletPosition': _randomBullet(),
      'triggerCount': 0,
      'players': [
        {
          'uid': uid,
          'name': playerName,
          'isAlive': true,
          'isHost': true,
        }
      ],
      'gameLog': [],
    });
    return roomCode;
  }

  // Gabung room
  Future<void> joinRoom(String code, String playerName) async {
    final doc = await _db.collection('game_rooms').doc(code).get();
    if (!doc.exists) throw Exception('Room tidak ditemukan.');

    final data = doc.data()!;
    if (data['status'] != 'waiting') {
      throw Exception('Game sudah dimulai atau selesai.');
    }

    final players = List<Map<String, dynamic>>.from(data['players']);
    if (players.length >= 6) throw Exception('Room sudah penuh (maks 6 pemain).');
    if (players.any((p) => p['uid'] == uid)) {
      throw Exception('Kamu sudah ada di room ini.');
    }

    players.add({
      'uid': uid,
      'name': playerName,
      'isAlive': true,
      'isHost': false,
    });

    await _db.collection('game_rooms').doc(code).update({'players': players});
  }

  // Mulai game (host only)
  Future<void> startGame(String code) async {
    final doc = await _db.collection('game_rooms').doc(code).get();
    final data = doc.data()!;
    final players = List<Map<String, dynamic>>.from(data['players']);
    if (players.length < 2) throw Exception('Minimal 2 pemain.');

    // ✅ Buat list dulu, baru masukkan ke update
    final gameLog = <String>['MULAI: Game dimulai! Selamat bermain...'];

    await _db.collection('game_rooms').doc(code).update({
      'status': 'playing',
      'bulletPosition': _randomBullet(),
      'triggerCount': 0,
      'currentTurn': 0,
      'gameLog': gameLog,
    });
  }

  // Tarik pelatuk
  Future<void> pullTrigger(String code) async {
    final doc = await _db.collection('game_rooms').doc(code).get();
    final data = doc.data()!;

    final players = List<Map<String, dynamic>>.from(data['players']);
    final currentTurn = data['currentTurn'] as int;
    final bulletPosition = data['bulletPosition'] as int;
    int triggerCount = data['triggerCount'] as int;
    final gameLog = List<String>.from(data['gameLog'] ?? []);

    final alivePlayers = players
        .asMap()
        .entries
        .where((e) => e.value['isAlive'] == true)
        .toList();

    if (alivePlayers.isEmpty) return;

    final currentPlayerEntry =
        alivePlayers[currentTurn % alivePlayers.length];
    final currentPlayer = currentPlayerEntry.value;
    final currentIndex = currentPlayerEntry.key;

    triggerCount++;

    if (triggerCount == bulletPosition) {
      // KENA TEMBAK
      players[currentIndex]['isAlive'] = false;
      gameLog.add('MATI: ${currentPlayer['name']} kena tembak!');

      final stillAlive = players.where((p) => p['isAlive'] == true).toList();

      if (stillAlive.length <= 1) {
        final winner = stillAlive.isNotEmpty ? stillAlive.first['name'] : '-';
        gameLog.add('MENANG: $winner memenangkan game!');
        await _db.collection('game_rooms').doc(code).update({
          'players': players,
          'triggerCount': triggerCount,
          'status': 'finished',
          'winner': winner,
          'gameLog': gameLog,
        });
      } else {
        final newBullet = _randomBullet();
        gameLog.add('RESET: Putaran baru! Revolver dikocok ulang...');
        await _db.collection('game_rooms').doc(code).update({
          'players': players,
          'triggerCount': 0,
          'bulletPosition': newBullet,
          'currentTurn': 0,
          'gameLog': gameLog,
        });
      }
    } else {
      // SELAMAT
      gameLog.add('SELAMAT: ${currentPlayer['name']} selamat! *klik*');

      final newAlive = players.where((p) => p['isAlive'] == true).toList();
      final nextTurn = (currentTurn + 1) % newAlive.length;

      await _db.collection('game_rooms').doc(code).update({
        'players': players,
        'triggerCount': triggerCount,
        'currentTurn': nextTurn,
        'gameLog': gameLog,
      });
    }
  }

  // Keluar dari room
  Future<void> leaveRoom(String code) async {
    final doc = await _db.collection('game_rooms').doc(code).get();
    if (!doc.exists) return;
    final data = doc.data()!;
    final players = List<Map<String, dynamic>>.from(data['players']);
    players.removeWhere((p) => p['uid'] == uid);

    if (players.isEmpty) {
      await _db.collection('game_rooms').doc(code).delete();
    } else {
      if (!players.any((p) => p['isHost'] == true)) {
        players[0]['isHost'] = true;
      }
      await _db.collection('game_rooms').doc(code).update({'players': players});
    }
  }

  // Main ulang
  Future<void> restartGame(String code) async {
    final doc = await _db.collection('game_rooms').doc(code).get();
    final data = doc.data()!;
    final players = List<Map<String, dynamic>>.from(data['players']);

    for (var p in players) {
      p['isAlive'] = true;
    }

    // ✅ Buat list dulu, baru masukkan ke update
    final gameLog = <String>['MULAI: Game dimulai ulang!'];

    await _db.collection('game_rooms').doc(code).update({
      'status': 'playing',
      'players': players,
      'bulletPosition': _randomBullet(),
      'triggerCount': 0,
      'currentTurn': 0,
      'gameLog': gameLog,
      'winner': '',
    });
  }

  Stream<DocumentSnapshot> roomStream(String code) {
    return _db.collection('game_rooms').doc(code).snapshots();
  }

  Stream<QuerySnapshot> getOpenRooms() {
    return _db
        .collection('game_rooms')
        .where('status', isEqualTo: 'waiting')
        .snapshots();
  }

  int _randomBullet() => (DateTime.now().millisecondsSinceEpoch % 6) + 1;

  String _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final now = DateTime.now().millisecondsSinceEpoch;
    String code = '';
    int n = now;
    for (int i = 0; i < 5; i++) {
      code += chars[n % chars.length];
      n = n ~/ chars.length;
    }
    return code;
  }
}