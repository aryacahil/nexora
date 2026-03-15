import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Konstanta Role
// ─────────────────────────────────────────────────────────────────────────────

class WRole {
  // Tim Werewolf
  static const String werewolf   = 'werewolf';
  static const String alphaWolf  = 'alpha_wolf';   // Bisa konversi pemain jadi werewolf
  static const String lycan      = 'lycan';         // Terlihat sebagai Villager oleh Seer

  // Tim Desa
  static const String villager   = 'villager';
  static const String seer       = 'seer';          // Bisa melihat role seseorang tiap malam
  static const String doctor     = 'doctor';        // Melindungi 1 orang tiap malam
  static const String hunter     = 'hunter';        // Saat mati, bisa membunuh 1 orang
  static const String witch      = 'witch';         // Punya 1 ramuan sembuh & 1 racun
  static const String bodyguard  = 'bodyguard';     // Melindungi 1 orang, boleh diri sendiri
  static const String mayor      = 'mayor';         // Vote-nya dihitung 2x

  // Netral
  static const String cupid      = 'cupid';         // Malam 1: memilih 2 orang jadi pasangan
  static const String jester     = 'jester';        // Menang jika di-vote mati oleh desa

  static bool isWolf(String role) =>
      role == werewolf || role == alphaWolf || role == lycan;

  static bool isVillageTeam(String role) =>
      !isWolf(role) && role != cupid && role != jester;

  static String label(String role) {
    switch (role) {
      case werewolf:   return 'Werewolf';
      case alphaWolf:  return 'Alpha Wolf';
      case lycan:      return 'Lycan';
      case villager:   return 'Villager';
      case seer:       return 'Seer (Peramal)';
      case doctor:     return 'Doctor';
      case hunter:     return 'Hunter';
      case witch:      return 'Witch';
      case bodyguard:  return 'Bodyguard';
      case mayor:      return 'Mayor';
      case cupid:      return 'Cupid';
      case jester:     return 'Jester';
      default:         return role;
    }
  }

  static String description(String role) {
    switch (role) {
      case werewolf:
        return 'Setiap malam, werewolf memilih satu pemain untuk dibunuh. Tujuanmu: kalahkan desa.';
      case alphaWolf:
        return 'Seperti Werewolf, tapi sekali per game bisa mengonversi 1 Villager jadi Werewolf.';
      case lycan:
        return 'Berpihak pada Werewolf, tapi Seer melihatmu sebagai Villager biasa.';
      case villager:
        return 'Tidak punya kemampuan khusus. Gunakan logikamu untuk menemukan Werewolf!';
      case seer:
        return 'Setiap malam, pilih 1 pemain untuk mengetahui apakah dia Werewolf atau bukan.';
      case doctor:
        return 'Setiap malam, lindungi 1 pemain dari serangan. Tidak bisa melindungi orang yang sama 2 malam berturut.';
      case hunter:
        return 'Jika kamu mati (oleh apapun), kamu bisa membunuh 1 pemain sebagai balas dendam.';
      case witch:
        return 'Punya 1 ramuan sembuh (selamatkan korban malam) dan 1 racun (bunuh pemain). Masing-masing 1x seumur game.';
      case bodyguard:
        return 'Setiap malam, lindungi 1 pemain. Jika diserang, kamu yang mati menggantikannya (boleh pilih dirimu sendiri).';
      case mayor:
        return 'Suaramu dihitung 2x saat voting siang. Kemampuan tersembunyi — tidak diketahui pemain lain.';
      case cupid:
        return 'Malam pertama, pilih 2 pemain sebagai pasangan. Jika salah satu mati, yang lain ikut mati.';
      case jester:
        return 'Kamu menang jika desa menghukum matimu lewat voting. Tujuanmu: terlihat mencurigakan!';
      default:
        return '';
    }
  }

  static String emoji(String role) {
    switch (role) {
      case werewolf:   return '🐺';
      case alphaWolf:  return '🐺👑';
      case lycan:      return '🐺🎭';
      case villager:   return '👨‍🌾';
      case seer:       return '🔮';
      case doctor:     return '💊';
      case hunter:     return '🏹';
      case witch:      return '🧙';
      case bodyguard:  return '🛡️';
      case mayor:      return '⭐';
      case cupid:      return '💘';
      case jester:     return '🃏';
      default:         return '❓';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phase Enum
// ─────────────────────────────────────────────────────────────────────────────

class WPhase {
  static const String waiting      = 'waiting';
  static const String night        = 'night';
  static const String nightResult  = 'night_result';
  static const String day          = 'day';
  static const String voting       = 'voting';
  static const String voteResult   = 'vote_result';
  static const String hunterRevenge = 'hunter_revenge';
  static const String finished     = 'finished';
}

// ─────────────────────────────────────────────────────────────────────────────
// Role Assignment Helper
// ─────────────────────────────────────────────────────────────────────────────

List<String> assignRoles(int playerCount) {
  // Distribusi role berdasarkan jumlah pemain
  // Selalu ada setidaknya 1 werewolf untuk setiap 3 pemain
  final roles = <String>[];

  if (playerCount <= 4) {
    // 4: 1 wolf, 1 seer, 2 villager
    roles.addAll([WRole.werewolf, WRole.seer, WRole.villager, WRole.villager]);
  } else if (playerCount == 5) {
    roles.addAll([WRole.werewolf, WRole.seer, WRole.doctor, WRole.villager, WRole.villager]);
  } else if (playerCount == 6) {
    roles.addAll([WRole.werewolf, WRole.werewolf, WRole.seer, WRole.doctor, WRole.villager, WRole.villager]);
  } else if (playerCount == 7) {
    roles.addAll([WRole.werewolf, WRole.alphaWolf, WRole.seer, WRole.doctor, WRole.hunter, WRole.villager, WRole.villager]);
  } else if (playerCount == 8) {
    roles.addAll([WRole.werewolf, WRole.alphaWolf, WRole.seer, WRole.doctor, WRole.hunter, WRole.witch, WRole.villager, WRole.villager]);
  } else if (playerCount == 9) {
    roles.addAll([WRole.werewolf, WRole.alphaWolf, WRole.lycan, WRole.seer, WRole.doctor, WRole.hunter, WRole.witch, WRole.villager, WRole.villager]);
  } else if (playerCount == 10) {
    roles.addAll([WRole.werewolf, WRole.alphaWolf, WRole.lycan, WRole.seer, WRole.doctor, WRole.hunter, WRole.witch, WRole.bodyguard, WRole.villager, WRole.cupid]);
  } else if (playerCount == 11) {
    roles.addAll([WRole.werewolf, WRole.alphaWolf, WRole.lycan, WRole.seer, WRole.doctor, WRole.hunter, WRole.witch, WRole.bodyguard, WRole.mayor, WRole.cupid, WRole.villager]);
  } else {
    // 12
    roles.addAll([WRole.werewolf, WRole.alphaWolf, WRole.lycan, WRole.seer, WRole.doctor, WRole.hunter, WRole.witch, WRole.bodyguard, WRole.mayor, WRole.cupid, WRole.jester, WRole.villager]);
  }

  roles.shuffle(Random());
  return roles;
}

// ─────────────────────────────────────────────────────────────────────────────
// WerewolfService
// ─────────────────────────────────────────────────────────────────────────────

class WerewolfService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get uid => _auth.currentUser?.uid;

  CollectionReference get _rooms => _db.collection('werewolf_rooms');

  // ── Room Management ────────────────────────────────────────────────────────

  Future<String> createRoom(String playerName) async {
    final code = _generateCode();
    await _rooms.doc(code).set({
      'code': code,
      'status': WPhase.waiting,
      'phase': WPhase.waiting,
      'round': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': uid,
      'players': [
        {
          'uid': uid,
          'name': playerName,
          'isAlive': true,
          'isHost': true,
          'role': '',
          'votedFor': '',
          'isProtected': false,
          'isCursed': false,
          'isLovers': false,
          'loversPartner': '',
          'calledHunterRevenge': false,
          'witchHealUsed': false,
          'witchPoisonUsed': false,
          'convertedByAlpha': false,
        }
      ],
      'gameLog': [],
      'nightActions': {},   // uid -> action (wolf kill, seer check, doctor save, etc)
      'wolfTarget': '',
      'doctorSave': '',
      'bodyguardSave': '',
      'seerResult': {},     // uid -> {target, isWolf}
      'witchHeal': false,
      'witchPoison': '',
      'alphaConvert': '',
      'cupidLovers': [],    // [uid1, uid2]
      'pendingHunterRevenge': '', // uid of hunter who just died
      'winner': '',
      'dayDiscussion': true,
    });
    return code;
  }

  Future<void> joinRoom(String code, String playerName) async {
    final doc = await _rooms.doc(code).get();
    if (!doc.exists) throw Exception('Room tidak ditemukan.');
    final data = doc.data()! as Map<String, dynamic>;
    if (data['status'] != WPhase.waiting) throw Exception('Game sudah dimulai.');
    final players = List<Map<String, dynamic>>.from(data['players']);
    if (players.length >= 12) throw Exception('Room penuh (maks 12 pemain).');
    if (players.any((p) => p['uid'] == uid)) throw Exception('Kamu sudah ada di room ini.');

    players.add({
      'uid': uid,
      'name': playerName,
      'isAlive': true,
      'isHost': false,
      'role': '',
      'votedFor': '',
      'isProtected': false,
      'isCursed': false,
      'isLovers': false,
      'loversPartner': '',
      'calledHunterRevenge': false,
      'witchHealUsed': false,
      'witchPoisonUsed': false,
      'convertedByAlpha': false,
    });
    await _rooms.doc(code).update({'players': players});
  }

  Future<void> leaveRoom(String code) async {
    final doc = await _rooms.doc(code).get();
    if (!doc.exists) return;
    final data = doc.data()! as Map<String, dynamic>;
    final players = List<Map<String, dynamic>>.from(data['players']);
    players.removeWhere((p) => p['uid'] == uid);
    if (players.isEmpty) {
      await _rooms.doc(code).delete();
      return;
    }
    if (!players.any((p) => p['isHost'] == true)) {
      players[0]['isHost'] = true;
    }
    await _rooms.doc(code).update({'players': players});
  }

  Stream<DocumentSnapshot> roomStream(String code) =>
      _rooms.doc(code).snapshots();

  Stream<QuerySnapshot> getOpenRooms() => _rooms
      .where('status', isEqualTo: WPhase.waiting)
      .snapshots();

  // ── Start Game ─────────────────────────────────────────────────────────────

  Future<void> startGame(String code) async {
    final doc = await _rooms.doc(code).get();
    final data = doc.data()! as Map<String, dynamic>;
    final players = List<Map<String, dynamic>>.from(data['players']);
    if (players.length < 4) throw Exception('Minimal 4 pemain.');

    final roles = assignRoles(players.length);
    for (int i = 0; i < players.length; i++) {
      players[i]['role'] = roles[i];
    }

    // Cek apakah ada cupid
    final hasCupid = players.any((p) => p['role'] == WRole.cupid);

    await _rooms.doc(code).update({
      'players': players,
      'status': WPhase.night,
      'phase': WPhase.night,
      'round': 1,
      'gameLog': ['MULAI: Game dimulai! Malam pertama... 🌙'],
      'nightActions': {},
      'wolfTarget': '',
      'doctorSave': '',
      'bodyguardSave': '',
      'seerResult': {},
      'witchHeal': false,
      'witchPoison': '',
      'alphaConvert': '',
      'cupidLovers': hasCupid ? [] : ['_no_cupid'],
      'pendingHunterRevenge': '',
      'winner': '',
    });
  }

  // ── Night Actions ──────────────────────────────────────────────────────────

  /// Werewolf memilih target
  Future<void> wolfVote(String code, String targetUid) async {
    await _rooms.doc(code).update({'wolfTarget': targetUid});
    await _checkNightComplete(code);
  }

  /// Alpha Wolf konversi target (1x seumur game)
  Future<void> alphaConvert(String code, String targetUid) async {
    await _rooms.doc(code).update({'alphaConvert': targetUid});
    await _checkNightComplete(code);
  }

  /// Seer melihat role seseorang
  Future<void> seerCheck(String code, String targetUid) async {
    final doc = await _rooms.doc(code).get();
    final data = doc.data()! as Map<String, dynamic>;
    final players = List<Map<String, dynamic>>.from(data['players']);
    final target = players.firstWhere((p) => p['uid'] == targetUid, orElse: () => {});
    final role = target['role'] as String? ?? '';

    // Lycan terlihat sebagai villager oleh seer
    final appearsAsWolf = WRole.isWolf(role) && role != WRole.lycan;

    final seerResult = Map<String, dynamic>.from(data['seerResult'] as Map? ?? {});
    seerResult[uid!] = {'target': targetUid, 'isWolf': appearsAsWolf, 'role': role == WRole.lycan ? WRole.villager : role};

    await _rooms.doc(code).update({'seerResult': seerResult});
    await _checkNightComplete(code);
  }

  /// Doctor melindungi seseorang
  Future<void> doctorSave(String code, String targetUid) async {
    await _rooms.doc(code).update({'doctorSave': targetUid});
    await _checkNightComplete(code);
  }

  /// Bodyguard melindungi seseorang
  Future<void> bodyguardSave(String code, String targetUid) async {
    await _rooms.doc(code).update({'bodyguardSave': targetUid});
    await _checkNightComplete(code);
  }

  /// Witch menggunakan ramuan
  Future<void> witchAction(String code, {bool heal = false, String poisonTarget = ''}) async {
    final updates = <String, dynamic>{};
    if (heal) updates['witchHeal'] = true;
    if (poisonTarget.isNotEmpty) updates['witchPoison'] = poisonTarget;
    if (updates.isNotEmpty) {
      await _rooms.doc(code).update(updates);
    }
    await _checkNightComplete(code);
  }

  /// Cupid memilih pasangan (malam 1 saja)
  Future<void> cupidChooseLovers(String code, String uid1, String uid2) async {
    await _rooms.doc(code).update({'cupidLovers': [uid1, uid2]});
    await _checkNightComplete(code);
  }

  /// Tandai bahwa role ini sudah selesai aksi malam (skip)
  Future<void> skipNightAction(String code) async {
    final doc = await _rooms.doc(code).get();
    final data = doc.data()! as Map<String, dynamic>;
    final nightActions = Map<String, dynamic>.from(data['nightActions'] as Map? ?? {});
    nightActions[uid!] = 'skip';
    await _rooms.doc(code).update({'nightActions': nightActions});
    await _checkNightComplete(code);
  }

  // ── Check Night Complete ───────────────────────────────────────────────────

  Future<void> _checkNightComplete(String code) async {
    final doc = await _rooms.doc(code).get();
    final data = doc.data()! as Map<String, dynamic>;
    final players = List<Map<String, dynamic>>.from(data['players']);
    final round = data['round'] as int;

    final alivePlayers = players.where((p) => p['isAlive'] == true).toList();

    final wolfTarget  = data['wolfTarget'] as String;
    final doctorSave  = data['doctorSave'] as String;
    final witchHeal   = data['witchHeal'] as bool;
    final witchPoison = data['witchPoison'] as String;
    final alphaConvert = data['alphaConvert'] as String;
    final cupidLovers  = List<String>.from(data['cupidLovers'] as List? ?? []);

    // Cek role apa saja yang ada & masih hidup
    final hasSeer      = alivePlayers.any((p) => p['role'] == WRole.seer);
    final hasDoctor    = alivePlayers.any((p) => p['role'] == WRole.doctor);
    final hasBodyguard = alivePlayers.any((p) => p['role'] == WRole.bodyguard);
    final hasWitch     = alivePlayers.any((p) => p['role'] == WRole.witch);
    final hasCupid     = alivePlayers.any((p) => p['role'] == WRole.cupid);
    final cupidDone    = cupidLovers.isNotEmpty;

    // Apakah semua aksi malam yang wajib sudah dilakukan?
    bool allDone = wolfTarget.isNotEmpty;
    if (hasSeer) {
      final seerResult = Map<String, dynamic>.from(data['seerResult'] as Map? ?? {});
      final seerUid = alivePlayers.firstWhere((p) => p['role'] == WRole.seer, orElse: () => {})['uid'] ?? '';
      if (seerUid.isNotEmpty && !seerResult.containsKey(seerUid)) allDone = false;
    }
    if (hasDoctor && doctorSave.isEmpty) allDone = false;
    if (hasBodyguard && (data['bodyguardSave'] as String).isEmpty) allDone = false;
    if (hasWitch) {
      final nightActions = Map<String, dynamic>.from(data['nightActions'] as Map? ?? {});
      final witchUid = alivePlayers.firstWhere((p) => p['role'] == WRole.witch, orElse: () => {})['uid'] ?? '';
      if (witchUid.isNotEmpty && !nightActions.containsKey(witchUid)) allDone = false;
    }
    if (hasCupid && round == 1 && !cupidDone) allDone = false;

    if (!allDone) return;

    // ── Proses hasil malam ────────────────────────────────────────────────
    final gameLog = List<String>.from(data['gameLog'] as List? ?? []);
    final updates = <String, dynamic>{};

    // Set cupid lovers
    if (cupidLovers.length == 2 && !cupidLovers.contains('_no_cupid')) {
      for (final p in players) {
        if (p['uid'] == cupidLovers[0]) {
          p['isLovers'] = true;
          p['loversPartner'] = cupidLovers[1];
        }
        if (p['uid'] == cupidLovers[1]) {
          p['isLovers'] = true;
          p['loversPartner'] = cupidLovers[0];
        }
      }
    }

    // Alpha Wolf konversi
    if (alphaConvert.isNotEmpty) {
      final idx = players.indexWhere((p) => p['uid'] == alphaConvert);
      if (idx != -1 && players[idx]['role'] == WRole.villager) {
        players[idx]['role'] = WRole.werewolf;
        players[idx]['convertedByAlpha'] = true;
        gameLog.add('MALAM: Seseorang telah dikonversi oleh Alpha Wolf...');
      }
    }

    // Tentukan siapa yang mati malam ini
    String? deadUid;
    final bodyguardSave = data['bodyguardSave'] as String;

    if (wolfTarget.isNotEmpty) {
      // Doctor / Witch heal melindungi target wolf
      final isProtectedByDoctor = doctorSave == wolfTarget;
      final isHealedByWitch = witchHeal && wolfTarget == wolfTarget; // witch heal korban wolf
      final isProtectedByBodyguard = bodyguardSave == wolfTarget;

      if (!isProtectedByDoctor && !isHealedByWitch && !isProtectedByBodyguard) {
        deadUid = wolfTarget;
      } else if (isProtectedByBodyguard && bodyguardSave != wolfTarget) {
        // bodyguard tidak tepat sasaran
        deadUid = wolfTarget;
      } else {
        if (isProtectedByBodyguard) {
          // Bodyguard mati menggantikan
          final bgIdx = players.indexWhere((p) => p['uid'] == bodyguardSave && p['role'] == WRole.bodyguard);
          if (bgIdx != -1) {
            players[bgIdx]['isAlive'] = false;
            final bgName = players[bgIdx]['name'];
            gameLog.add('MALAM: $bgName (Bodyguard) mati melindungi targetnya! 🛡️');
            deadUid = null;
            // Cek lovers
            _checkLoversChain(players, bodyguardSave, gameLog);
          }
        } else {
          gameLog.add('MALAM: Serangan werewolf berhasil digagalkan! 🌟');
        }
      }
    }

    // Witch poison
    if (witchPoison.isNotEmpty) {
      final poisonIdx = players.indexWhere((p) => p['uid'] == witchPoison);
      if (poisonIdx != -1 && players[poisonIdx]['isAlive'] == true) {
        players[poisonIdx]['isAlive'] = false;
        final pName = players[poisonIdx]['name'];
        gameLog.add('MALAM: $pName diracuni Witch! 🧪');
        _checkLoversChain(players, witchPoison, gameLog);
        // Update witch flag
        final witchIdx = players.indexWhere((p) => p['role'] == WRole.witch);
        if (witchIdx != -1) players[witchIdx]['witchPoisonUsed'] = true;
      }
    }

    // Bunuh target wolf
    if (deadUid != null) {
      final deadIdx = players.indexWhere((p) => p['uid'] == deadUid);
      if (deadIdx != -1) {
        players[deadIdx]['isAlive'] = false;
        final dName = players[deadIdx]['name'];
        final dRole = players[deadIdx]['role'];
        gameLog.add('MALAM: $dName ditemukan tewas! (${ WRole.label(dRole)}) 💀');
        _checkLoversChain(players, deadUid, gameLog);

        // Cek hunter
        if (dRole == WRole.hunter) {
          updates['pendingHunterRevenge'] = deadUid;
        }
      }
    } else if (wolfTarget.isEmpty) {
      gameLog.add('MALAM: Semua selamat malam ini... 🌙');
    }

    updates['players'] = players;
    updates['gameLog'] = gameLog;
    updates['phase'] = WPhase.nightResult;
    updates['status'] = WPhase.nightResult;

    // Reset night actions
    updates['wolfTarget'] = '';
    updates['doctorSave'] = '';
    updates['bodyguardSave'] = '';
    updates['witchHeal'] = false;
    updates['witchPoison'] = '';
    updates['alphaConvert'] = '';
    updates['nightActions'] = {};
    updates['seerResult'] = {};

    await _rooms.doc(code).update(updates);
  }

  void _checkLoversChain(List<Map<String, dynamic>> players, String deadUid, List<String> gameLog) {
    final deadIdx = players.indexWhere((p) => p['uid'] == deadUid);
    if (deadIdx == -1) return;
    final isLovers = players[deadIdx]['isLovers'] == true;
    if (!isLovers) return;
    final partnerUid = players[deadIdx]['loversPartner'] as String? ?? '';
    if (partnerUid.isEmpty) return;
    final partnerIdx = players.indexWhere((p) => p['uid'] == partnerUid);
    if (partnerIdx == -1) return;
    if (players[partnerIdx]['isAlive'] == true) {
      players[partnerIdx]['isAlive'] = false;
      final pName = players[partnerIdx]['name'];
      gameLog.add('MALAM: $pName mati karena pasangannya (Cupid) telah tiada 💔');
    }
  }

  // ── Advance Phase ──────────────────────────────────────────────────────────

  /// Dari night_result → day (host / semua setuju)
  Future<void> advanceToDay(String code) async {
    final doc = await _rooms.doc(code).get();
    final data = doc.data()! as Map<String, dynamic>;
    final gameLog = List<String>.from(data['gameLog'] as List? ?? []);
    final round = data['round'] as int;

    gameLog.add('SIANG: Hari ke-$round dimulai. Diskusikan siapa Werewolf! ☀️');

    final winCheck = _checkWinCondition(data);
    if (winCheck != null) {
      await _endGame(code, winCheck, gameLog);
      return;
    }

    await _rooms.doc(code).update({
      'phase': WPhase.day,
      'status': WPhase.day,
      'gameLog': gameLog,
      'votes': {},
    });
  }

  /// Mulai voting
  Future<void> startVoting(String code) async {
    final doc = await _rooms.doc(code).get();
    final data = doc.data()! as Map<String, dynamic>;
    final gameLog = List<String>.from(data['gameLog'] as List? ?? []);
    gameLog.add('VOTING: Saatnya voting! Pilih siapa yang kalian curigai... 🗳️');

    await _rooms.doc(code).update({
      'phase': WPhase.voting,
      'status': WPhase.voting,
      'gameLog': gameLog,
      'votes': {},
    });
  }

  /// Pemain vote
  Future<void> castVote(String code, String targetUid) async {
    final doc = await _rooms.doc(code).get();
    final data = doc.data()! as Map<String, dynamic>;
    final players = List<Map<String, dynamic>>.from(data['players']);
    final votes = Map<String, dynamic>.from(data['votes'] as Map? ?? {});

    votes[uid!] = targetUid;
    await _rooms.doc(code).update({'votes': votes});

    // Cek apakah semua pemain hidup sudah vote
    final alivePlayers = players.where((p) => p['isAlive'] == true).toList();
    if (votes.length >= alivePlayers.length) {
      await _processVotes(code);
    }
  }

  Future<void> _processVotes(String code) async {
    final doc = await _rooms.doc(code).get();
    final data = doc.data()! as Map<String, dynamic>;
    final players = List<Map<String, dynamic>>.from(data['players']);
    final votes = Map<String, dynamic>.from(data['votes'] as Map? ?? {});
    final gameLog = List<String>.from(data['gameLog'] as List? ?? []);

    // Hitung vote (mayor dihitung 2x)
    final tally = <String, int>{};
    for (final entry in votes.entries) {
      final voterUid = entry.key;
      final target = entry.value as String;
      final voter = players.firstWhere((p) => p['uid'] == voterUid, orElse: () => {});
      final weight = voter['role'] == WRole.mayor ? 2 : 1;
      tally[target] = (tally[target] ?? 0) + weight;
    }

    if (tally.isEmpty) {
      gameLog.add('VOTING: Tidak ada yang di-vote. Tidak ada yang dihukum.');
      await _rooms.doc(code).update({
        'phase': WPhase.voteResult,
        'status': WPhase.voteResult,
        'gameLog': gameLog,
        'votes': {},
      });
      return;
    }

    // Cari yang paling banyak vote
    final maxVote = tally.values.reduce((a, b) => a > b ? a : b);
    final topCandidates = tally.entries.where((e) => e.value == maxVote).toList();

    if (topCandidates.length > 1) {
      // Seri — tidak ada yang dihukum
      gameLog.add('VOTING: Hasil seri! Tidak ada yang dihukum hari ini. 🤝');
      await _rooms.doc(code).update({
        'phase': WPhase.voteResult,
        'status': WPhase.voteResult,
        'gameLog': gameLog,
        'votes': {},
        'voteEliminated': '',
      });
      return;
    }

    final eliminatedUid = topCandidates.first.key;
    final idx = players.indexWhere((p) => p['uid'] == eliminatedUid);
    if (idx != -1) {
      players[idx]['isAlive'] = false;
      final eName = players[idx]['name'];
      final eRole = players[idx]['role'];
      gameLog.add('VOTING: $eName dihukum mati oleh desa! (${WRole.label(eRole)}) ⚖️');

      // Cek jester menang
      if (eRole == WRole.jester) {
        gameLog.add('MENANG: $eName adalah Jester dan menang! 🃏');
        await _rooms.doc(code).update({
          'players': players,
          'gameLog': gameLog,
          'phase': WPhase.finished,
          'status': WPhase.finished,
          'winner': '$eName (Jester)',
          'votes': {},
        });
        return;
      }

      // Cek lovers
      _checkLoversChain(players, eliminatedUid, gameLog);

      // Cek hunter
      final updates = <String, dynamic>{
        'players': players,
        'gameLog': gameLog,
        'votes': {},
        'voteEliminated': eliminatedUid,
      };

      if (eRole == WRole.hunter) {
        updates['pendingHunterRevenge'] = eliminatedUid;
        updates['phase'] = WPhase.hunterRevenge;
        updates['status'] = WPhase.hunterRevenge;
      } else {
        final winCheck = _checkWinCondition({...data, 'players': players});
        if (winCheck != null) {
          await _endGame(code, winCheck, gameLog);
          return;
        }
        updates['phase'] = WPhase.voteResult;
        updates['status'] = WPhase.voteResult;
      }

      await _rooms.doc(code).update(updates);
    }
  }

  /// Hunter balas dendam
  Future<void> hunterShoot(String code, String targetUid) async {
    final doc = await _rooms.doc(code).get();
    final data = doc.data()! as Map<String, dynamic>;
    final players = List<Map<String, dynamic>>.from(data['players']);
    final gameLog = List<String>.from(data['gameLog'] as List? ?? []);

    final idx = players.indexWhere((p) => p['uid'] == targetUid);
    if (idx != -1) {
      players[idx]['isAlive'] = false;
      final name = players[idx]['name'];
      final role = players[idx]['role'];
      gameLog.add('HUNTER: Hunter menembak $name (${WRole.label(role)})! 🏹');
      _checkLoversChain(players, targetUid, gameLog);
    }

    final winCheck = _checkWinCondition({...data, 'players': players});
    if (winCheck != null) {
      await _endGame(code, winCheck, gameLog);
      return;
    }

    await _rooms.doc(code).update({
      'players': players,
      'gameLog': gameLog,
      'pendingHunterRevenge': '',
      'phase': WPhase.voteResult,
      'status': WPhase.voteResult,
    });
  }

  /// Dari vote_result → night berikutnya
  Future<void> advanceToNight(String code) async {
    final doc = await _rooms.doc(code).get();
    final data = doc.data()! as Map<String, dynamic>;
    final round = (data['round'] as int) + 1;
    final gameLog = List<String>.from(data['gameLog'] as List? ?? []);
    gameLog.add('MALAM: Malam ke-$round tiba... 🌙');

    await _rooms.doc(code).update({
      'phase': WPhase.night,
      'status': WPhase.night,
      'round': round,
      'gameLog': gameLog,
      'wolfTarget': '',
      'doctorSave': '',
      'bodyguardSave': '',
      'witchHeal': false,
      'witchPoison': '',
      'alphaConvert': '',
      'nightActions': {},
      'seerResult': {},
      'votes': {},
      'pendingHunterRevenge': '',
    });
  }

  // ── Win Condition ──────────────────────────────────────────────────────────

  String? _checkWinCondition(Map<String, dynamic> data) {
    final players = List<Map<String, dynamic>>.from(data['players'] as List);
    final alive = players.where((p) => p['isAlive'] == true).toList();

    final wolves = alive.where((p) => WRole.isWolf(p['role'])).length;
    final villagers = alive.where((p) => !WRole.isWolf(p['role'])).length;

    if (wolves == 0) return 'village'; // Desa menang
    if (wolves >= villagers) return 'wolves'; // Serigala menang
    return null;
  }

  Future<void> _endGame(String code, String winner, List<String> gameLog) async {
    final msg = winner == 'village'
        ? 'MENANG: Desa menang! Semua werewolf telah dibasmi! 🎉'
        : 'MENANG: Werewolf menang! Mereka menguasai desa! 🐺';
    gameLog.add(msg);

    await _rooms.doc(code).update({
      'phase': WPhase.finished,
      'status': WPhase.finished,
      'winner': winner,
      'gameLog': gameLog,
    });
  }

  Future<void> restartGame(String code) async {
    final doc = await _rooms.doc(code).get();
    final data = doc.data()! as Map<String, dynamic>;
    final players = List<Map<String, dynamic>>.from(data['players']);

    for (final p in players) {
      p['isAlive'] = true;
      p['role'] = '';
      p['votedFor'] = '';
      p['isProtected'] = false;
      p['isLovers'] = false;
      p['loversPartner'] = '';
      p['calledHunterRevenge'] = false;
      p['witchHealUsed'] = false;
      p['witchPoisonUsed'] = false;
      p['convertedByAlpha'] = false;
    }

    await _rooms.doc(code).update({
      'players': players,
      'status': WPhase.waiting,
      'phase': WPhase.waiting,
      'round': 0,
      'gameLog': ['RESTART: Game di-restart!'],
      'nightActions': {},
      'wolfTarget': '',
      'doctorSave': '',
      'bodyguardSave': '',
      'seerResult': {},
      'witchHeal': false,
      'witchPoison': '',
      'alphaConvert': '',
      'cupidLovers': [],
      'pendingHunterRevenge': '',
      'winner': '',
      'votes': {},
    });
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

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