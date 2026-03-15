import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model: UnoCard
// ─────────────────────────────────────────────────────────────────────────────

class UnoCard {
  final String id;
  final String color; // 'red','green','blue','yellow','wild'
  final String value; // '0'-'9','skip','reverse','draw2','wild','wild4'

  const UnoCard({required this.id, required this.color, required this.value});

  factory UnoCard.fromMap(Map<String, dynamic> m) =>
      UnoCard(id: m['id'], color: m['color'], value: m['value']);

  Map<String, dynamic> toMap() => {'id': id, 'color': color, 'value': value};

  bool get isWild => color == 'wild';
  bool get isAction =>
      value == 'skip' ||
      value == 'reverse' ||
      value == 'draw2' ||
      value == 'wild' ||
      value == 'wild4';

  bool canPlayOn(UnoCard topCard, String chosenColor) {
    if (isWild) return true;
    if (color == chosenColor) return true;
    if (color == topCard.color) return true;
    if (value == topCard.value) return true;
    return false;
  }

  String get displayValue {
    switch (value) {
      case 'skip':    return 'SKIP';
      case 'reverse': return 'REV';
      case 'draw2':   return '+2';
      case 'wild':    return 'W';
      case 'wild4':   return '+4';
      default:        return value.toUpperCase();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Deck Builder
// ─────────────────────────────────────────────────────────────────────────────

class UnoDeck {
  static final _rng = Random();

  static List<UnoCard> buildDeck() {
    final List<UnoCard> deck = [];
    int idx = 0;

    for (final color in ['red', 'green', 'blue', 'yellow']) {
      deck.add(UnoCard(id: 'c${idx++}', color: color, value: '0'));
      for (final value in ['1','2','3','4','5','6','7','8','9','skip','reverse','draw2']) {
        deck.add(UnoCard(id: 'c${idx++}', color: color, value: value));
        deck.add(UnoCard(id: 'c${idx++}', color: color, value: value));
      }
    }

    for (int i = 0; i < 4; i++) {
      deck.add(UnoCard(id: 'c${idx++}', color: 'wild', value: 'wild'));
      deck.add(UnoCard(id: 'c${idx++}', color: 'wild', value: 'wild4'));
    }

    return _shuffle(deck);
  }

  static List<UnoCard> _shuffle(List<UnoCard> deck) {
    final d = List<UnoCard>.from(deck);
    for (int i = d.length - 1; i > 0; i--) {
      final j = _rng.nextInt(i + 1);
      final tmp = d[i]; d[i] = d[j]; d[j] = tmp;
    }
    return d;
  }

  static List<UnoCard> reshuffleDiscard(List<Map<String,dynamic>> discard) {
    final cards = discard.map((m) => UnoCard.fromMap(m)).toList();
    return _shuffle(cards);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UnoService
// ─────────────────────────────────────────────────────────────────────────────

class UnoService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get uid => _auth.currentUser?.uid;

  static const int timerSeconds = 20;

  Future<String> createRoom(String playerName) async {
    final code = _generateCode();
    await _db.collection('uno_rooms').doc(code).set({
      'code': code,
      'status': 'waiting',
      'createdAt': FieldValue.serverTimestamp(),
      'players': [
        {'uid': uid, 'name': playerName, 'isHost': true, 'hand': [], 'calledUno': false}
      ],
      'deck': [],
      'discardPile': [],
      'currentTurn': 0,
      'direction': 1,
      'chosenColor': '',
      'pendingDraw': 0,
      'lastAction': '',
      'turnStartedAt': null,
      'winner': '',
      'waitingColor': false,
    });
    return code;
  }

  Future<void> joinRoom(String code, String playerName) async {
    final doc = await _db.collection('uno_rooms').doc(code).get();
    if (!doc.exists) throw Exception('Room tidak ditemukan.');
    final data = doc.data()!;
    if (data['status'] != 'waiting') throw Exception('Game sudah dimulai.');
    final players = List<Map<String, dynamic>>.from(data['players']);
    if (players.length >= 6) throw Exception('Room penuh (maks 6 pemain).');
    if (players.any((p) => p['uid'] == uid)) throw Exception('Kamu sudah ada di room.');
    players.add({'uid': uid, 'name': playerName, 'isHost': false, 'hand': [], 'calledUno': false});
    await _db.collection('uno_rooms').doc(code).update({'players': players});
  }

  Future<void> startGame(String code) async {
    final doc = await _db.collection('uno_rooms').doc(code).get();
    final data = doc.data()!;
    final players = List<Map<String, dynamic>>.from(data['players']);
    if (players.length < 2) throw Exception('Minimal 2 pemain.');

    var deck = UnoDeck.buildDeck();
    final discardPile = <Map<String, dynamic>>[];

    for (final p in players) {
      final hand = <Map<String, dynamic>>[];
      for (int i = 0; i < 7; i++) {
        hand.add(deck.removeAt(0).toMap());
      }
      p['hand'] = hand;
      p['calledUno'] = false;
    }

    UnoCard firstCard;
    do {
      firstCard = deck.removeAt(0);
      if (firstCard.isWild) deck.add(firstCard);
    } while (firstCard.isWild);

    discardPile.add(firstCard.toMap());

    await _db.collection('uno_rooms').doc(code).update({
      'status': 'playing',
      'players': players,
      'deck': deck.map((c) => c.toMap()).toList(),
      'discardPile': discardPile,
      'currentTurn': 0,
      'direction': 1,
      'chosenColor': firstCard.color,
      'pendingDraw': 0,
      'lastAction': 'Game dimulai! Giliran ${players[0]['name']}',
      'turnStartedAt': FieldValue.serverTimestamp(),
      'winner': '',
      'waitingColor': false,
    });
  }

  Future<void> playCard({
    required String code,
    required String cardId,
    String? chosenColor,
  }) async {
    final doc = await _db.collection('uno_rooms').doc(code).get();
    final data = doc.data()!;

    var players = List<Map<String, dynamic>>.from(data['players']);
    var deck = List<Map<String, dynamic>>.from(data['deck']);
    var discardPile = List<Map<String, dynamic>>.from(data['discardPile']);
    int currentTurn = data['currentTurn'];
    int direction = data['direction'];
    String curChosenColor = data['chosenColor'];
    int pendingDraw = data['pendingDraw'];
    bool waitingColor = data['waitingColor'];

    final myIdx = players.indexWhere((p) => p['uid'] == uid);
    if (myIdx == -1) throw Exception('Kamu tidak ada di room ini.');
    if (currentTurn % players.length != myIdx) throw Exception('Bukan giliran kamu.');
    if (waitingColor) throw Exception('Pilih warna dulu!');

    final hand = List<Map<String, dynamic>>.from(players[myIdx]['hand']);
    final cardIdx = hand.indexWhere((c) => c['id'] == cardId);
    if (cardIdx == -1) throw Exception('Kartu tidak ditemukan.');

    final card = UnoCard.fromMap(hand[cardIdx]);
    final topCard = UnoCard.fromMap(discardPile.last);

    if (pendingDraw > 0) {
      final isStackable = (topCard.value == 'draw2' && card.value == 'draw2') ||
          (topCard.value == 'wild4' && card.value == 'wild4');
      if (!isStackable) throw Exception('Kamu harus ambil kartu atau stack Draw!');
    }

    if (!card.canPlayOn(topCard, curChosenColor)) {
      throw Exception('Kartu tidak bisa dimainkan.');
    }

    hand.removeAt(cardIdx);
    players[myIdx]['hand'] = hand;
    players[myIdx]['calledUno'] = false;
    discardPile.add(card.toMap());

    if (hand.isEmpty) {
      await _db.collection('uno_rooms').doc(code).update({
        'players': players,
        'discardPile': discardPile,
        'deck': deck,
        'status': 'finished',
        'winner': players[myIdx]['name'],
        'lastAction': '${players[myIdx]['name']} menang!',
      });
      return;
    }

    String lastAction = '${players[myIdx]['name']} mainkan ${card.displayValue}';
    bool isWaitingColor = false;
    int nextTurn = currentTurn;

    switch (card.value) {
      case 'skip':
        nextTurn = _nextTurn(currentTurn, direction, players.length, skip: 1);
        lastAction = '${players[myIdx]['name']} Skip! ${players[nextTurn % players.length]['name']} dilewati!';
        nextTurn = _nextTurn(nextTurn, direction, players.length);
        break;

      case 'reverse':
        direction = direction * -1;
        if (players.length == 2) {
          nextTurn = _nextTurn(currentTurn, direction, players.length, skip: 1);
        } else {
          nextTurn = _nextTurn(currentTurn, direction, players.length);
        }
        lastAction = '${players[myIdx]['name']} Reverse! Arah dibalik.';
        break;

      case 'draw2':
        pendingDraw += 2;
        nextTurn = _nextTurn(currentTurn, direction, players.length);
        lastAction = '${players[myIdx]['name']} Draw+2! ${players[nextTurn % players.length]['name']} kena!';
        break;

      case 'wild':
        isWaitingColor = true;
        nextTurn = _nextTurn(currentTurn, direction, players.length);
        lastAction = '${players[myIdx]['name']} Wild! Pilih warna...';
        break;

      case 'wild4':
        pendingDraw += 4;
        isWaitingColor = true;
        nextTurn = _nextTurn(currentTurn, direction, players.length);
        lastAction = '${players[myIdx]['name']} Wild+4! ${players[nextTurn % players.length]['name']} kena!';
        break;

      default:
        nextTurn = _nextTurn(currentTurn, direction, players.length);
    }

    if (card.isWild && chosenColor != null && chosenColor.isNotEmpty) {
      curChosenColor = chosenColor;
      isWaitingColor = false;
      lastAction = '${players[myIdx]['name']} pilih warna $chosenColor';
    } else if (card.isWild) {
      isWaitingColor = true;
    } else {
      curChosenColor = card.color;
    }

    if (deck.length < 5 && discardPile.length > 1) {
      final top = discardPile.removeLast();
      deck = UnoDeck.reshuffleDiscard(discardPile).map((c) => c.toMap()).toList();
      discardPile.clear();
      discardPile.add(top);
    }

    await _db.collection('uno_rooms').doc(code).update({
      'players': players,
      'deck': deck,
      'discardPile': discardPile,
      'currentTurn': nextTurn,
      'direction': direction,
      'chosenColor': curChosenColor,
      'pendingDraw': pendingDraw,
      'lastAction': lastAction,
      'turnStartedAt': FieldValue.serverTimestamp(),
      'waitingColor': isWaitingColor,
    });
  }

  Future<void> chooseColor(String code, String color) async {
    final doc = await _db.collection('uno_rooms').doc(code).get();
    final data = doc.data()!;
    final players = List<Map<String, dynamic>>.from(data['players']);
    final myIdx = players.indexWhere((p) => p['uid'] == uid);
    if (myIdx == -1) return;
    await _db.collection('uno_rooms').doc(code).update({
      'chosenColor': color,
      'waitingColor': false,
      'lastAction': '${players[myIdx]['name']} pilih warna $color',
    });
  }

  Future<void> drawCard(String code) async {
    final doc = await _db.collection('uno_rooms').doc(code).get();
    final data = doc.data()!;

    var players = List<Map<String, dynamic>>.from(data['players']);
    var deck = List<Map<String, dynamic>>.from(data['deck']);
    var discardPile = List<Map<String, dynamic>>.from(data['discardPile']);
    int currentTurn = data['currentTurn'];
    int direction = data['direction'];
    int pendingDraw = data['pendingDraw'];

    final myIdx = players.indexWhere((p) => p['uid'] == uid);
    if (myIdx == -1) return;
    if (currentTurn % players.length != myIdx) throw Exception('Bukan giliran kamu.');

    final hand = List<Map<String, dynamic>>.from(players[myIdx]['hand']);
    final drawCount = pendingDraw > 0 ? pendingDraw : 1;

    for (int i = 0; i < drawCount; i++) {
      if (deck.isEmpty) {
        if (discardPile.length <= 1) break;
        final top = discardPile.removeLast();
        deck = UnoDeck.reshuffleDiscard(discardPile).map((c) => c.toMap()).toList();
        discardPile.clear();
        discardPile.add(top);
      }
      if (deck.isNotEmpty) hand.add(deck.removeAt(0));
    }

    players[myIdx]['hand'] = hand;
    players[myIdx]['calledUno'] = false;

    final nextTurn = _nextTurn(currentTurn, direction, players.length);
    final lastAction = pendingDraw > 0
        ? '${players[myIdx]['name']} ambil $drawCount kartu!'
        : '${players[myIdx]['name']} ambil 1 kartu.';

    await _db.collection('uno_rooms').doc(code).update({
      'players': players,
      'deck': deck,
      'discardPile': discardPile,
      'currentTurn': nextTurn,
      'pendingDraw': 0,
      'lastAction': lastAction,
      'turnStartedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> callUno(String code) async {
    final doc = await _db.collection('uno_rooms').doc(code).get();
    final data = doc.data()!;
    final players = List<Map<String, dynamic>>.from(data['players']);
    final myIdx = players.indexWhere((p) => p['uid'] == uid);
    if (myIdx == -1) return;
    if ((players[myIdx]['hand'] as List).length != 1) return;
    players[myIdx]['calledUno'] = true;
    await _db.collection('uno_rooms').doc(code).update({
      'players': players,
      'lastAction': '${players[myIdx]['name']} teriak UNO!',
    });
  }

  Future<void> skipTurnByTimeout(String code) async {
    final doc = await _db.collection('uno_rooms').doc(code).get();
    if (!doc.exists) return;
    final data = doc.data()!;
    if (data['status'] != 'playing') return;

    var players = List<Map<String, dynamic>>.from(data['players']);
    var deck = List<Map<String, dynamic>>.from(data['deck']);
    var discardPile = List<Map<String, dynamic>>.from(data['discardPile']);
    int currentTurn = data['currentTurn'];
    int direction = data['direction'];
    int pendingDraw = data['pendingDraw'];

    final myIdx = currentTurn % players.length;
    final hand = List<Map<String, dynamic>>.from(players[myIdx]['hand']);

    if (deck.isEmpty && discardPile.length > 1) {
      final top = discardPile.removeLast();
      deck = UnoDeck.reshuffleDiscard(discardPile).map((c) => c.toMap()).toList();
      discardPile.clear();
      discardPile.add(top);
    }

    final drawCount = pendingDraw > 0 ? pendingDraw : 1;
    for (int i = 0; i < drawCount; i++) {
      if (deck.isNotEmpty) hand.add(deck.removeAt(0));
    }

    players[myIdx]['hand'] = hand;
    final nextTurn = _nextTurn(currentTurn, direction, players.length);

    await _db.collection('uno_rooms').doc(code).update({
      'players': players,
      'deck': deck,
      'discardPile': discardPile,
      'currentTurn': nextTurn,
      'pendingDraw': 0,
      'waitingColor': false,
      'lastAction': '${players[myIdx]['name']} timeout! Auto skip.',
      'turnStartedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> leaveRoom(String code) async {
    final doc = await _db.collection('uno_rooms').doc(code).get();
    if (!doc.exists) return;
    final data = doc.data()!;
    final status = data['status'];
    var players = List<Map<String, dynamic>>.from(data['players']);
    var deck = List<Map<String, dynamic>>.from(data['deck']);

    final myIdx = players.indexWhere((p) => p['uid'] == uid);
    if (myIdx == -1) return;

    final myHand = List<Map<String, dynamic>>.from(players[myIdx]['hand']);
    deck.addAll(myHand);
    players.removeAt(myIdx);

    if (players.isEmpty) {
      await _db.collection('uno_rooms').doc(code).delete();
      return;
    }

    if (status == 'playing' && players.length == 1) {
      await _db.collection('uno_rooms').doc(code).update({
        'players': players,
        'deck': deck,
        'status': 'finished',
        'winner': players[0]['name'],
        'lastAction': '${players[0]['name']} menang karena semua pemain keluar!',
      });
      return;
    }

    if (!players.any((p) => p['isHost'] == true)) {
      players[0]['isHost'] = true;
    }

    int currentTurn = data['currentTurn'];
    if (myIdx <= currentTurn % (players.length + 1)) {
      currentTurn = currentTurn > 0 ? currentTurn - 1 : 0;
    }

    await _db.collection('uno_rooms').doc(code).update({
      'players': players,
      'deck': deck,
      'currentTurn': currentTurn % players.length,
    });
  }

  Future<void> restartGame(String code) async {
    final doc = await _db.collection('uno_rooms').doc(code).get();
    final data = doc.data()!;
    final players = List<Map<String, dynamic>>.from(data['players']);

    var deck = UnoDeck.buildDeck();
    final discardPile = <Map<String, dynamic>>[];

    for (final p in players) {
      final hand = <Map<String, dynamic>>[];
      for (int i = 0; i < 7; i++) {
        if (deck.isNotEmpty) hand.add(deck.removeAt(0).toMap());
      }
      p['hand'] = hand;
      p['calledUno'] = false;
    }

    UnoCard firstCard;
    do {
      firstCard = deck.removeAt(0);
      if (firstCard.isWild) deck.add(firstCard);
    } while (firstCard.isWild);
    discardPile.add(firstCard.toMap());

    await _db.collection('uno_rooms').doc(code).update({
      'status': 'playing',
      'players': players,
      'deck': deck.map((c) => c.toMap()).toList(),
      'discardPile': discardPile,
      'currentTurn': 0,
      'direction': 1,
      'chosenColor': firstCard.color,
      'pendingDraw': 0,
      'lastAction': 'Game dimulai ulang! Giliran ${players[0]['name']}',
      'turnStartedAt': FieldValue.serverTimestamp(),
      'winner': '',
      'waitingColor': false,
    });
  }

  Stream<DocumentSnapshot> roomStream(String code) =>
      _db.collection('uno_rooms').doc(code).snapshots();

  Stream<QuerySnapshot> getOpenRooms() => _db
      .collection('uno_rooms')
      .where('status', isEqualTo: 'waiting')
      .snapshots();

  int _nextTurn(int current, int direction, int playerCount, {int skip = 0}) {
    return (current + direction * (1 + skip) % playerCount + playerCount * 2) % playerCount;
  }

  String _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final now = DateTime.now().millisecondsSinceEpoch;
    String code = '';
    int n = now;
    for (int i = 0; i < 5; i++) {
      code += chars[n % chars.length];
      n = n ~/ chars.length;
    }
    return 'U$code';
  }
}