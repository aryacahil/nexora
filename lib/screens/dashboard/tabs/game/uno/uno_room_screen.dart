import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../core/colors.dart';
import '../../../../../services/uno_service.dart';
import 'uno_card.dart';

class UnoRoomScreen extends StatefulWidget {
  final String roomCode;
  final String myUid;
  final UnoService unoService;
  final VoidCallback onLeave;

  const UnoRoomScreen({
    super.key,
    required this.roomCode,
    required this.myUid,
    required this.unoService,
    required this.onLeave,
  });

  @override
  State<UnoRoomScreen> createState() => _UnoRoomScreenState();
}

class _UnoRoomScreenState extends State<UnoRoomScreen>
    with TickerProviderStateMixin {
  Timer? _turnTimer;
  int _timerLeft = UnoService.timerSeconds;
  Timestamp? _lastTurnStarted;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  bool _showColorPicker = false;
  String? _pendingWildCardId;

  static const _red   = Color(0xFFD32F2F);
  static const _green = Color(0xFF2E7D32);
  static const _blue  = Color(0xFF1565C0);
  static const _gold  = Color(0xFFF9A825);

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        duration: const Duration(milliseconds: 900), vsync: this)
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _turnTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _startTimer(Timestamp? ts, bool isMyTurn) {
    if (ts == null) return;
    if (_lastTurnStarted != null && _lastTurnStarted!.seconds == ts.seconds) return;
    _lastTurnStarted = ts;
    _turnTimer?.cancel();

    final elapsed = DateTime.now().difference(ts.toDate()).inSeconds;
    final remaining = UnoService.timerSeconds - elapsed;
    if (remaining <= 0) {
      if (isMyTurn) widget.unoService.skipTurnByTimeout(widget.roomCode);
      return;
    }
    if (mounted) setState(() => _timerLeft = remaining);
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _timerLeft--);
      if (_timerLeft <= 0) {
        t.cancel();
        if (isMyTurn) widget.unoService.skipTurnByTimeout(widget.roomCode);
      }
    });
  }

  Future<void> _onCardTap(UnoCard card) async {
    if (card.isWild) {
      setState(() { _showColorPicker = true; _pendingWildCardId = card.id; });
      return;
    }
    await _playCard(card.id);
  }

  Future<void> _playCard(String cardId, {String? chosenColor}) async {
    try {
      await widget.unoService.playCard(
          code: widget.roomCode, cardId: cardId, chosenColor: chosenColor);
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  Future<void> _onDraw() async {
    try { await widget.unoService.drawCard(widget.roomCode); }
    catch (e) { _showSnack(e.toString(), isError: true); }
  }

  Future<void> _onUno() async {
    await widget.unoService.callUno(widget.roomCode);
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: widget.unoService.roomStream(widget.roomCode),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildRoomGone();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final status       = data['status'] ?? 'waiting';
        final players      = List<Map<String, dynamic>>.from(data['players'] ?? []);
        final discardPile  = List<Map<String, dynamic>>.from(data['discardPile'] ?? []);
        final int curTurn  = data['currentTurn'] ?? 0;
        final bool waitCol = data['waitingColor'] ?? false;
        final String color = data['chosenColor'] ?? '';
        final int pending  = data['pendingDraw'] ?? 0;
        final String last  = data['lastAction'] ?? '';
        final String winner = data['winner'] ?? '';
        final int direction = data['direction'] ?? 1;
        final Timestamp? ts = data['turnStartedAt'];

        final myIdx   = players.indexWhere((p) => p['uid'] == widget.myUid);
        final isMyTurn = status == 'playing' && myIdx != -1 &&
            curTurn % players.length == myIdx && !waitCol;
        final isHost  = myIdx != -1 && players[myIdx]['isHost'] == true;

        if (status == 'playing') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _startTimer(ts, isMyTurn);
          });
        }

        final topCard = discardPile.isNotEmpty
            ? UnoCard.fromMap(discardPile.last) : null;

        final myHand = myIdx != -1
            ? List<Map<String, dynamic>>.from(players[myIdx]['hand'])
            : <Map<String, dynamic>>[];
        final myCards = myHand.map((m) => UnoCard.fromMap(m)).toList();
        final playable = topCard != null
            ? myCards.where((c) => c.canPlayOn(topCard, color)).toList()
            : <UnoCard>[];

        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: _buildAppBar(status, direction, players),
          body: Stack(
            children: [
              Column(
                children: [
                  if (last.isNotEmpty && status != 'waiting')
                    _buildStatusBanner(last),
                  Expanded(
                    child: status == 'waiting'
                        ? _buildWaiting(players, isHost)
                        : status == 'finished'
                            ? _buildFinished(winner, isHost)
                            : _buildPlay(players, myIdx, curTurn, topCard,
                                color, pending, isMyTurn, waitCol, direction),
                  ),
                  if (status == 'playing') ...[
                    _buildTimer(isMyTurn),
                    _buildHand(myCards, playable, isMyTurn, pending,
                        players, myIdx),
                  ],
                ],
              ),
              if (_showColorPicker) _buildColorOverlay(),
            ],
          ),
        );
      },
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  AppBar _buildAppBar(String status, int direction, List players) {
    return AppBar(
      backgroundColor: AppColors.bg,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.exit_to_app, color: Colors.red.shade400, size: 24),
        onPressed: _confirmLeave,
      ),
      title: Row(
        children: [
          Text(widget.roomCode,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Colors.red.shade400,
                  letterSpacing: 3)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: status == 'playing'
                  ? Colors.green.withValues(alpha: 0.15)
                  : AppColors.border,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status == 'waiting' ? 'LOBBY' : status == 'playing' ? 'LIVE' : 'SELESAI',
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: status == 'playing' ? Colors.green.shade400 : AppColors.textDim),
            ),
          ),
          if (status == 'playing') ...[
            const SizedBox(width: 8),
            Icon(
              direction == 1 ? Icons.rotate_right : Icons.rotate_left,
              size: 14,
              color: AppColors.textDim,
            ),
          ],
        ],
      ),
    );
  }

  // ── Status Banner ─────────────────────────────────────────────────────────

  Widget _buildStatusBanner(String msg) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(msg),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        color: AppColors.card,
        child: Text(msg,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12, color: AppColors.textDim, fontWeight: FontWeight.w500)),
      ),
    );
  }

  // ── Timer ─────────────────────────────────────────────────────────────────

  Widget _buildTimer(bool isMyTurn) {
    final frac = (_timerLeft / UnoService.timerSeconds).clamp(0.0, 1.0);
    final color = frac > 0.5 ? Colors.green.shade600
        : frac > 0.25 ? Colors.orange.shade600
        : Colors.red.shade600;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: isMyTurn ? frac : 0,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 3,
              ),
            ),
          ),
          if (isMyTurn) ...[
            const SizedBox(width: 8),
            Text('${_timerLeft}s',
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          ],
        ],
      ),
    );
  }

  // ── Waiting ───────────────────────────────────────────────────────────────

  Widget _buildWaiting(List<Map<String, dynamic>> players, bool isHost) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Spacer(),
          // UNO logo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            decoration: BoxDecoration(
              color: _red,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: _red.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 10))],
            ),
            child: const Text('UNO',
                style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900,
                    color: Colors.white, letterSpacing: 6, fontStyle: FontStyle.italic)),
          ),
          const SizedBox(height: 28),

          // Players list
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Row(
                    children: [
                      Text('PEMAIN', style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w900,
                          letterSpacing: 2, color: AppColors.textDim)),
                      const Spacer(),
                      Text('${players.length} / 6',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w900,
                              color: AppColors.textMain)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ...players.asMap().entries.map((e) {
                  final i = e.key;
                  final p = e.value;
                  final isMe = p['uid'] == widget.myUid;
                  return Column(
                    children: [
                      if (i > 0) Divider(height: 1, color: AppColors.border),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                        child: Row(
                          children: [
                            Container(
                              width: 34, height: 34,
                              decoration: BoxDecoration(
                                color: _playerColor(i).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  (p['name'] as String? ?? '?').isNotEmpty
                                      ? (p['name'] as String)[0].toUpperCase() : '?',
                                  style: TextStyle(
                                      color: _playerColor(i),
                                      fontWeight: FontWeight.w900, fontSize: 15),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(p['name'] ?? '',
                                  style: TextStyle(
                                      color: AppColors.textMain, fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                            ),
                            if (isMe)
                              _badge('KAMU', AppColors.accent),
                            if (p['isHost'] == true) ...[
                              const SizedBox(width: 6),
                              _badge('HOST', Colors.amber.shade600),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (isHost)
            GestureDetector(
              onTap: players.length >= 2
                  ? () => widget.unoService.startGame(widget.roomCode) : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: players.length >= 2 ? _red : AppColors.border,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: players.length >= 2
                      ? [BoxShadow(color: _red.withValues(alpha: 0.35),
                          blurRadius: 14, offset: const Offset(0, 5))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      players.length >= 2 ? Icons.play_arrow_rounded : Icons.hourglass_empty,
                      color: players.length >= 2 ? Colors.white : AppColors.textDim,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      players.length < 2 ? 'Menunggu pemain lain...' : 'MULAI GAME',
                      style: TextStyle(
                          color: players.length >= 2 ? Colors.white : AppColors.textDim,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppColors.card, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2)),
                  const SizedBox(width: 12),
                  Text('Menunggu host memulai...',
                      style: TextStyle(color: AppColors.textDim, fontSize: 13)),
                ],
              ),
            ),
          const Spacer(),
        ],
      ),
    );
  }

  // ── Finished ──────────────────────────────────────────────────────────────

  Widget _buildFinished(String winner, bool isHost) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3), width: 2),
              ),
              child: const Icon(Icons.emoji_events_rounded,
                  color: Colors.amber, size: 44),
            ),
            const SizedBox(height: 20),
            Text('PEMENANG',
                style: TextStyle(
                    fontSize: 11, letterSpacing: 4,
                    fontWeight: FontWeight.w900, color: AppColors.textDim)),
            const SizedBox(height: 8),
            Text(winner,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w900,
                    color: Colors.white, fontStyle: FontStyle.italic)),
            const SizedBox(height: 28),
            if (isHost)
              GestureDetector(
                onTap: () => widget.unoService.restartGame(widget.roomCode),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                  decoration: BoxDecoration(
                    color: _red,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(
                        color: _red.withValues(alpha: 0.4),
                        blurRadius: 14, offset: const Offset(0, 5))],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.replay_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('MAIN LAGI',
                          style: TextStyle(color: Colors.white,
                              fontWeight: FontWeight.w900, letterSpacing: 2)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Play Area ─────────────────────────────────────────────────────────────

  Widget _buildPlay(
    List<Map<String, dynamic>> players,
    int myIdx,
    int curTurn,
    UnoCard? topCard,
    String chosenColor,
    int pending,
    bool isMyTurn,
    bool waitCol,
    int direction,
  ) {
    final opponents = <Map<String, dynamic>>[];
    for (int i = 0; i < players.length; i++) {
      if (i != myIdx) opponents.add({...players[i], '_idx': i});
    }

    return Column(
      children: [
        // Opponents strip
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: opponents.map((p) {
                final pIdx = p['_idx'] as int;
                final isTurn = curTurn % players.length == pIdx;
                final hand = List.from(p['hand'] ?? []);
                final calledUno = p['calledUno'] ?? false;
                final cardCount = hand.length;

                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
                  decoration: BoxDecoration(
                    color: isTurn
                        ? _red.withValues(alpha: 0.12)
                        : AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isTurn ? _red.withValues(alpha: 0.4) : AppColors.border,
                      width: isTurn ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isTurn)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(Icons.arrow_drop_down,
                                  color: _red, size: 13),
                            ),
                          Text(p['name'] ?? '',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: isTurn ? Colors.red.shade300 : AppColors.textDim)),
                          if (calledUno) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                  color: _red, borderRadius: BorderRadius.circular(5)),
                              child: const Text('UNO',
                                  style: TextStyle(
                                      fontSize: 7, fontWeight: FontWeight.w900,
                                      color: Colors.white)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      // Mini card stack
                      SizedBox(
                        width: (cardCount.clamp(1, 6) * 11 + 36).toDouble(),
                        height: 36,
                        child: Stack(
                          children: List.generate(cardCount.clamp(0, 6),
                              (i) => Positioned(
                                    left: i * 10.0,
                                    child: const UnoCardBack(isSmall: true),
                                  )),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text('$cardCount kartu',
                          style: TextStyle(fontSize: 9, color: AppColors.textDim)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Table center
        Expanded(
          child: Center(
            child: _buildTable(topCard, chosenColor, pending, isMyTurn),
          ),
        ),
      ],
    );
  }

  Widget _buildTable(UnoCard? topCard, String chosenColor, int pending, bool isMyTurn) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Chosen color badge
        if (chosenColor.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _colorFromName(chosenColor).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _colorFromName(chosenColor).withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 9, height: 9,
                  decoration: BoxDecoration(
                      color: _colorFromName(chosenColor), shape: BoxShape.circle),
                ),
                const SizedBox(width: 7),
                Text(
                  _colorLabel(chosenColor),
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w900,
                      color: _colorFromName(chosenColor)),
                ),
              ],
            ),
          ),

        // Deck + Discard
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Draw deck
            Column(
              children: [
                GestureDetector(
                  onTap: isMyTurn ? _onDraw : null,
                  child: AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, child) => Transform.scale(
                      scale: isMyTurn ? _pulseAnim.value : 1.0,
                      child: child,
                    ),
                    child: const Stack(
                      children: [
                        UnoCardBack(),
                        Positioned(left: 3, top: 3, child: UnoCardBack()),
                        Positioned(left: 6, top: 6, child: UnoCardBack()),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(isMyTurn ? 'AMBIL' : 'DECK',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        color: isMyTurn ? AppColors.textMain : AppColors.textDim)),
              ],
            ),
            const SizedBox(width: 30),
            // Discard pile
            Column(
              children: [
                topCard != null
                    ? UnoCardWidget(card: topCard)
                    : Container(
                        width: 60, height: 88,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12),
                        ),
                      ),
                const SizedBox(height: 6),
                Text('PILE',
                    style: TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w900,
                        letterSpacing: 1, color: AppColors.textDim)),
              ],
            ),
          ],
        ),

        // Pending draw warning
        if (pending > 0) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _red.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _red.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red.shade400, size: 15),
                const SizedBox(width: 7),
                Text('+$pending kartu menumpuk!',
                    style: TextStyle(
                        color: Colors.red.shade400,
                        fontSize: 12,
                        fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── My Hand ───────────────────────────────────────────────────────────────

  Widget _buildHand(
    List<UnoCard> myCards,
    List<UnoCard> playable,
    bool isMyTurn,
    int pending,
    List<Map<String, dynamic>> players,
    int myIdx,
  ) {
    final calledUno = myIdx != -1 && (players[myIdx]['calledUno'] ?? false);
    final showUnoBtn = isMyTurn && myCards.length == 1 && !calledUno;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 22),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Turn indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isMyTurn ? _red.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isMyTurn ? _red.withValues(alpha: 0.3) : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7, height: 7,
                  decoration: BoxDecoration(
                    color: isMyTurn ? _red : Colors.white24,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  isMyTurn
                      ? 'Giliran kamu  •  ${myCards.length} kartu'
                      : 'Tunggu giliran  •  ${myCards.length} kartu',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isMyTurn ? Colors.red.shade300 : Colors.white38),
                ),
                if (showUnoBtn) ...[
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _onUno,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                      decoration: BoxDecoration(
                        color: _red,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(
                            color: _red.withValues(alpha: 0.4),
                            blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: const Text('UNO!',
                          style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w900,
                              color: Colors.white, letterSpacing: 1)),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Cards
          SizedBox(
            height: 100,
            child: myCards.isEmpty
                ? Center(child: Text('Tidak ada kartu',
                    style: TextStyle(color: AppColors.textDim)))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: myCards.length,
                    itemBuilder: (ctx, i) {
                      final card = myCards[i];
                      final canPlay = isMyTurn &&
                          playable.any((c) => c.id == card.id);
                      return Padding(
                        padding: EdgeInsets.only(
                            left: i == 0 ? 0 : 4, top: canPlay ? 0 : 10),
                        child: UnoCardWidget(
                          card: card,
                          isPlayable: canPlay,
                          onTap: () => _onCardTap(card),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ── Color Picker Overlay ──────────────────────────────────────────────────

  Widget _buildColorOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 36),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('PILIH WARNA',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5,
                      color: AppColors.textDim)),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: _colorBtn('red',    'MERAH',  _red)),
                  const SizedBox(width: 10),
                  Expanded(child: _colorBtn('green',  'HIJAU',  _green)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _colorBtn('blue',   'BIRU',   _blue)),
                  const SizedBox(width: 10),
                  Expanded(child: _colorBtn('yellow', 'KUNING', _gold, dark: true)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _colorBtn(String colorKey, String label, Color c, {bool dark = false}) {
    return GestureDetector(
      onTap: () async {
        final id = _pendingWildCardId!;
        setState(() { _showColorPicker = false; _pendingWildCardId = null; });
        await _playCard(id, chosenColor: colorKey);
      },
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: c.withValues(alpha: 0.4),
              blurRadius: 8, offset: const Offset(0, 3))],
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                color: dark ? const Color(0xFF1A1A1A) : Colors.white)),
      ),
    );
  }

  // ── Room Gone ─────────────────────────────────────────────────────────────

  Widget _buildRoomGone() {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.meeting_room_outlined, size: 52, color: Colors.white24),
            const SizedBox(height: 16),
            Text('Room tidak ditemukan atau sudah ditutup.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textDim)),
            const SizedBox(height: 16),
            TextButton(
                onPressed: widget.onLeave,
                child: const Text('Kembali',
                    style: TextStyle(color: AppColors.accent))),
          ],
        ),
      ),
    );
  }

  // ── Confirm Leave ─────────────────────────────────────────────────────────

  void _confirmLeave() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Keluar Room',
            style: TextStyle(
                fontWeight: FontWeight.w900, color: AppColors.textMain)),
        content: Text('Yakin ingin keluar dari room ini?',
            style: TextStyle(color: AppColors.textDim)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal', style: TextStyle(color: AppColors.textDim))),
          TextButton(
            onPressed: () { Navigator.pop(context); widget.onLeave(); },
            child: const Text('Keluar',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Color _colorFromName(String name) {
    switch (name) {
      case 'red':    return _red;
      case 'green':  return _green;
      case 'blue':   return _blue;
      case 'yellow': return _gold;
      default:       return Colors.grey;
    }
  }

  String _colorLabel(String name) {
    switch (name) {
      case 'red':    return 'MERAH';
      case 'green':  return 'HIJAU';
      case 'blue':   return 'BIRU';
      case 'yellow': return 'KUNING';
      default:       return name.toUpperCase();
    }
  }

  Color _playerColor(int idx) {
    const colors = [_red, _blue, _green, _gold,
        Color(0xFF7C3AED), Color(0xFFE91E63)];
    return colors[idx % colors.length];
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.5)),
    );
  }
}