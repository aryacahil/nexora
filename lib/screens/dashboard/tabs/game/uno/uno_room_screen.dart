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
  // Timer
  Timer? _turnTimer;
  int _timerLeft = UnoService.timerSeconds;
  Timestamp? _lastTurnStarted;

  // Animasi
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Wild color picker
  bool _showColorPicker = false;
  String? _pendingWildCardId;

  // Swap7 target picker
  bool _showSwapPicker = false;
  String? _pendingSwap7CardId;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this)
      ..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _turnTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer(Timestamp? turnStartedAt, bool isMyTurn) {
    if (turnStartedAt == null) return;
    // Cek apakah giliran baru (beda timestamp)
    if (_lastTurnStarted != null &&
        _lastTurnStarted!.seconds == turnStartedAt.seconds) return;
    _lastTurnStarted = turnStartedAt;

    _turnTimer?.cancel();

    final elapsed = DateTime.now().difference(turnStartedAt.toDate()).inSeconds;
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

  // ── Play card ─────────────────────────────────────────────────────────────

  Future<void> _onCardTap(UnoCard card, Map<String, dynamic> data) async {
    if (card.isWild) {
      setState(() {
        _showColorPicker = true;
        _pendingWildCardId = card.id;
      });
      return;
    }
    if (card.value == 'swap7') {
      // Tampilkan picker pemain untuk swap
      setState(() {
        _showSwapPicker = true;
        _pendingSwap7CardId = card.id;
      });
      return;
    }
    await _playCard(card.id);
  }

  Future<void> _playCard(String cardId, {String? chosenColor}) async {
    try {
      await widget.unoService.playCard(
        code: widget.roomCode,
        cardId: cardId,
        chosenColor: chosenColor,
      );
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  Future<void> _onDraw() async {
    try {
      await widget.unoService.drawCard(widget.roomCode);
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  Future<void> _onUno() async {
    await widget.unoService.callUno(widget.roomCode);
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
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
        final status = data['status'] ?? 'waiting';
        final players = List<Map<String, dynamic>>.from(data['players'] ?? []);
        final discardPile = List<Map<String, dynamic>>.from(data['discardPile'] ?? []);
        final int currentTurn = data['currentTurn'] ?? 0;
        final bool waitingColor = data['waitingColor'] ?? false;
        final String chosenColor = data['chosenColor'] ?? '';
        final int pendingDraw = data['pendingDraw'] ?? 0;
        final String lastAction = data['lastAction'] ?? '';
        final String winner = data['winner'] ?? '';
        final int direction = data['direction'] ?? 1;
        final Timestamp? turnStartedAt = data['turnStartedAt'];

        final myIdx = players.indexWhere((p) => p['uid'] == widget.myUid);
        final isMyTurn = status == 'playing' &&
            myIdx != -1 &&
            currentTurn % players.length == myIdx &&
            !waitingColor;
        final isHost = myIdx != -1 && players[myIdx]['isHost'] == true;

        // Timer — jadwalkan setelah build selesai agar tidak setState during build
        if (status == 'playing') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _startTimer(turnStartedAt, isMyTurn);
          });
        }

        final topCard = discardPile.isNotEmpty
            ? UnoCard.fromMap(discardPile.last)
            : null;

        final myHand = myIdx != -1
            ? List<Map<String, dynamic>>.from(players[myIdx]['hand'])
            : <Map<String, dynamic>>[];

        final myCards = myHand.map((m) => UnoCard.fromMap(m)).toList();
        final playableCards = topCard != null
            ? myCards.where((c) => c.canPlayOn(topCard, chosenColor)).toList()
            : <UnoCard>[];

        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: _buildAppBar(status, direction, players),
          body: Stack(
            children: [
              Column(
                children: [
                  // ── Status bar ──────────────────────────
                  _buildStatusBar(lastAction, status),

                  // ── Area lawan ──────────────────────────
                  Expanded(
                    child: status == 'waiting'
                        ? _buildWaitingArea(players, isHost)
                        : status == 'finished'
                            ? _buildFinishedArea(winner, isHost)
                            : _buildPlayArea(
                                players,
                                myIdx,
                                currentTurn,
                                topCard,
                                chosenColor,
                                pendingDraw,
                                isMyTurn,
                                waitingColor,
                                direction,
                              ),
                  ),

                  // ── Tangan pemain ───────────────────────
                  if (status == 'playing') ...[
                    _buildTimerBar(isMyTurn),
                    _buildMyHand(
                      myCards,
                      playableCards,
                      isMyTurn,
                      pendingDraw,
                      data,
                      players,
                      myIdx,
                    ),
                  ],
                ],
              ),

              // ── Color Picker Overlay ────────────────────
              if (_showColorPicker)
                _buildColorPickerOverlay(),

              // ── Swap7 Picker Overlay ────────────────────
              if (_showSwapPicker)
                _buildSwapPickerOverlay(players, myIdx),
            ],
          ),
        );
      },
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  AppBar _buildAppBar(
      String status, int direction, List<Map<String, dynamic>> players) {
    return AppBar(
      backgroundColor: AppColors.bg,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.exit_to_app, color: Colors.red.shade400, size: 28),
        onPressed: () => _confirmLeave(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ROOM: ${widget.roomCode}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.red.shade400,
              letterSpacing: 2,
            ),
          ),
          Row(
            children: [
              Text(
                status == 'waiting'
                    ? 'Menunggu pemain...'
                    : status == 'playing'
                        ? 'Sedang bermain'
                        : 'Game selesai',
                style: TextStyle(fontSize: 10, color: AppColors.textDim),
              ),
              if (status == 'playing') ...[
                const SizedBox(width: 6),
                Icon(
                  direction == 1 ? Icons.rotate_right : Icons.rotate_left,
                  color: AppColors.textDim,
                  size: 12,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Status bar ────────────────────────────────────────────────────────────

  Widget _buildStatusBar(String lastAction, String status) {
    if (lastAction.isEmpty || status == 'waiting') return const SizedBox.shrink();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Container(
        key: ValueKey(lastAction),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: AppColors.card,
        child: Text(
          lastAction,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textDim,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ── Timer bar ─────────────────────────────────────────────────────────────

  Widget _buildTimerBar(bool isMyTurn) {
    final fraction = _timerLeft / UnoService.timerSeconds;
    final color = fraction > 0.5
        ? Colors.green
        : fraction > 0.25
            ? Colors.orange
            : Colors.red;

    return Container(
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: isMyTurn ? fraction.clamp(0.0, 1.0) : 0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  // ── Waiting area ──────────────────────────────────────────────────────────

  Widget _buildWaitingArea(
      List<Map<String, dynamic>> players, bool isHost) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // UNO logo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFE53935), Color(0xFF7C0000)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.red.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8))
              ],
            ),
            child: const Text('UNO',
                style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 4,
                    fontStyle: FontStyle.italic)),
          ),
          const SizedBox(height: 32),

          // Daftar pemain
          Text('PEMAIN (${players.length}/6)',
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: AppColors.textDim)),
          const SizedBox(height: 12),
          ...players.map((p) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          (p['name'] as String).isNotEmpty
                              ? (p['name'] as String)[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(p['name'] ?? '',
                          style: TextStyle(
                              color: AppColors.textMain,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ),
                    if (p['uid'] == widget.myUid)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('KAMU',
                            style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accent)),
                      ),
                    if (p['isHost'] == true) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star,
                                size: 8, color: Colors.orange.shade400),
                            const SizedBox(width: 3),
                            Text('HOST',
                                style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade400)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              )),
          const SizedBox(height: 24),

          // Tombol mulai
          if (isHost)
            GestureDetector(
              onTap: players.length >= 2
                  ? () => widget.unoService.startGame(widget.roomCode)
                  : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: players.length >= 2
                      ? const LinearGradient(
                          colors: [Color(0xFF7C0000), Color(0xFFE53935)])
                      : null,
                  color: players.length < 2 ? AppColors.border : null,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      players.length >= 2
                          ? Icons.play_circle_outline
                          : Icons.hourglass_empty,
                      color: players.length >= 2 ? Colors.white : AppColors.textDim,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      players.length < 2 ? 'Menunggu pemain lain...' : 'MULAI GAME',
                      style: TextStyle(
                          color: players.length >= 2 ? Colors.white : AppColors.textDim,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2)),
                  const SizedBox(width: 12),
                  Text('Menunggu host memulai...',
                      style: TextStyle(color: AppColors.textDim, fontSize: 13)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Finished area ─────────────────────────────────────────────────────────

  Widget _buildFinishedArea(String winner, bool isHost) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFFC026D3)]),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                      color: Colors.purple.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10))
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.emoji_events,
                        color: Colors.amber, size: 48),
                  ),
                  const SizedBox(height: 12),
                  const Text('PEMENANG!',
                      style: TextStyle(
                          color: AppColors.textDim,
                          fontSize: 12,
                          letterSpacing: 3)),
                  const SizedBox(height: 4),
                  Text(winner,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic)),
                  const SizedBox(height: 16),
                  if (isHost)
                    GestureDetector(
                      onTap: () =>
                          widget.unoService.restartGame(widget.roomCode),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20)),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.replay, color: Colors.white, size: 16),
                            SizedBox(width: 8),
                            Text('MAIN LAGI',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Play area (meja + lawan) ───────────────────────────────────────────────

  Widget _buildPlayArea(
    List<Map<String, dynamic>> players,
    int myIdx,
    int currentTurn,
    UnoCard? topCard,
    String chosenColor,
    int pendingDraw,
    bool isMyTurn,
    bool waitingColor,
    int direction,
  ) {
    // Pisahkan lawan (bukan saya)
    final opponents = <Map<String, dynamic>>[];
    for (int i = 0; i < players.length; i++) {
      if (i != myIdx) opponents.add({...players[i], '_idx': i});
    }

    return Column(
      children: [
        // ── Lawan ──────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: opponents.map((p) {
                final pIdx = p['_idx'] as int;
                final isTurn = currentTurn % players.length == pIdx;
                final hand = List.from(p['hand'] ?? []);
                final calledUno = p['calledUno'] ?? false;

                return Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isTurn
                        ? Colors.red.withValues(alpha: 0.15)
                        : AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isTurn
                          ? Colors.red.withValues(alpha: 0.5)
                          : AppColors.border,
                      width: isTurn ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(p['name'] ?? '',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: isTurn ? Colors.red.shade400 : AppColors.textDim,
                                  fontWeight: FontWeight.bold)),
                          if (calledUno) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('UNO!',
                                  style: TextStyle(
                                      fontSize: 7,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                            ),
                          ],
                          if (isTurn) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down,
                                color: Colors.red, size: 14),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Kartu lawan (belakang) ditampilkan overlap
                      SizedBox(
                        width: (hand.length.clamp(1, 7) * 14 + 38).toDouble(),
                        height: 42,
                        child: Stack(
                          children: List.generate(
                              hand.length.clamp(0, 7),
                              (i) => Positioned(
                                    left: i * 13.0,
                                    child: const UnoCardBack(isSmall: true),
                                  )),
                        ),
                      ),
                      Text('${hand.length} kartu',
                          style: const TextStyle(
                              fontSize: 9, color: AppColors.textDim)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // ── Meja tengah ─────────────────────────────
        Expanded(
          child: Center(
            child: _buildTable(
                topCard, chosenColor, pendingDraw, isMyTurn, waitingColor),
          ),
        ),
      ],
    );
  }

  Widget _buildTable(UnoCard? topCard, String chosenColor, int pendingDraw,
      bool isMyTurn, bool waitingColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Warna aktif
        if (chosenColor.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: _colorFromName(chosenColor).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _colorFromName(chosenColor).withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _colorFromName(chosenColor),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  chosenColor.toUpperCase(),
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _colorFromName(chosenColor)),
                ),
              ],
            ),
          ),

        // Tumpukan kartu + discard
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Deck
            Column(
              children: [
                GestureDetector(
                  onTap: isMyTurn ? _onDraw : null,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) => Transform.scale(
                      scale: isMyTurn ? _pulseAnimation.value : 1.0,
                      child: child,
                    ),
                    child: Stack(
                      children: [
                        const UnoCardBack(),
                        const Positioned(
                            left: 3, top: 3, child: UnoCardBack()),
                        const Positioned(
                            left: 6, top: 6, child: UnoCardBack()),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isMyTurn ? 'AMBIL' : 'DECK',
                  style: TextStyle(
                      fontSize: 9,
                      color: isMyTurn ? AppColors.textMain : AppColors.textDim,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1),
                ),
              ],
            ),

            const SizedBox(width: 28),

            // Top card
            Column(
              children: [
                if (topCard != null)
                  UnoCardWidget(card: topCard)
                else
                  Container(
                    width: 62,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white24),
                    ),
                  ),
                const SizedBox(height: 6),
                const Text('PILE',
                    style: TextStyle(
                        fontSize: 9,
                        color: Colors.white24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1)),
              ],
            ),
          ],
        ),

        // Pending draw indicator
        if (pendingDraw > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber, color: Colors.red, size: 14),
                const SizedBox(width: 6),
                Text(
                  '+$pendingDraw kartu menumpuk!',
                  style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── My hand ───────────────────────────────────────────────────────────────

  Widget _buildMyHand(
    List<UnoCard> myCards,
    List<UnoCard> playableCards,
    bool isMyTurn,
    int pendingDraw,
    Map<String, dynamic> data,
    List<Map<String, dynamic>> players,
    int myIdx,
  ) {
    final calledUno = myIdx != -1 && (players[myIdx]['calledUno'] ?? false);
    final showUnoBtn = isMyTurn && myCards.length == 1 && !calledUno;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          // Label giliran
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Container(
              key: ValueKey(isMyTurn),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isMyTurn
                    ? Colors.red.withValues(alpha: 0.15)
                    : AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isMyTurn
                      ? Colors.red.withValues(alpha: 0.4)
                      : AppColors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isMyTurn
                        ? Icons.radio_button_checked
                        : Icons.hourglass_empty,
                    size: 11,
                    color: isMyTurn ? Colors.red.shade300 : Colors.white38,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isMyTurn
                        ? 'Giliran kamu! (${myCards.length} kartu)'
                        : 'Tunggu giliran kamu... (${myCards.length} kartu)',
                    style: TextStyle(
                        fontSize: 11,
                        color:
                            isMyTurn ? Colors.red.shade300 : Colors.white38,
                        fontWeight: FontWeight.bold),
                  ),
                  if (showUnoBtn) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _onUno,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFFE53935), Color(0xFF7C0000)]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('UNO!',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.white)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Kartu di tangan
          SizedBox(
            height: 100,
            child: myCards.isEmpty
                ? const Center(
                    child: Text('Tidak ada kartu',
                        style: TextStyle(color: AppColors.textDim)))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: myCards.length,
                    itemBuilder: (context, i) {
                      final card = myCards[i];
                      final canPlay = isMyTurn &&
                          playableCards.any((c) => c.id == card.id);
                      return Padding(
                        padding: EdgeInsets.only(
                            left: i == 0 ? 0 : 4, top: canPlay ? 0 : 10),
                        child: UnoCardWidget(
                          card: card,
                          isPlayable: canPlay,
                          onTap: () => _onCardTap(card, data),
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

  Widget _buildColorPickerOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('PILIH WARNA',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: AppColors.textDim)),
              const SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.2,
                children: [
                  _colorButton('red', 'MERAH', const Color(0xFFE53935)),
                  _colorButton('green', 'HIJAU', const Color(0xFF43A047)),
                  _colorButton('blue', 'BIRU', const Color(0xFF1E88E5)),
                  _colorButton('yellow', 'KUNING', const Color(0xFFFDD835)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _colorButton(String color, String label, Color c) {
    return GestureDetector(
      onTap: () async {
        final cardId = _pendingWildCardId!;
        setState(() {
          _showColorPicker = false;
          _pendingWildCardId = null;
        });
        await _playCard(cardId, chosenColor: color);
      },
      child: Container(
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: c.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 4))
          ],
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: color == 'yellow' ? Colors.black87 : Colors.white)),
      ),
    );
  }

  // ── Swap7 Picker Overlay ──────────────────────────────────────────────────

  Widget _buildSwapPickerOverlay(
      List<Map<String, dynamic>> players, int myIdx) {
    final opponents = players
        .asMap()
        .entries
        .where((e) => e.key != myIdx)
        .toList();

    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('TUKAR TANGAN DENGAN',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      color: AppColors.textDim)),
              const SizedBox(height: 16),
              ...opponents.map((entry) {
                final p = entry.value;
                final hand = List.from(p['hand'] ?? []);
                return GestureDetector(
                  onTap: () async {
                    final cardId = _pendingSwap7CardId!;
                    setState(() {
                      _showSwapPicker = false;
                      _pendingSwap7CardId = null;
                    });
                    // Mainkan kartu swap7 (service auto swap dengan next player,
                    // ini hanya UI picker — future improvement untuk pilih target)
                    await _playCard(cardId);
                  },
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)]),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              (p['name'] as String).isNotEmpty
                                  ? (p['name'] as String)[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(p['name'] ?? '',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ),
                        Text('${hand.length} kartu',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              }),
              TextButton(
                onPressed: () => setState(() {
                  _showSwapPicker = false;
                  _pendingSwap7CardId = null;
                }),
                child: const Text('Batal',
                    style: TextStyle(color: AppColors.textDim)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Room gone ─────────────────────────────────────────────────────────────

  Widget _buildRoomGone() {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.meeting_room_outlined, size: 56, color: Colors.white24),
            const SizedBox(height: 16),
            const Text('Room tidak ditemukan atau sudah ditutup.',
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

  // ── Confirm leave ─────────────────────────────────────────────────────────

  void _confirmLeave() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar Room',
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Yakin ingin keluar dari room?',
            style: TextStyle(color: AppColors.textDim)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal',
                  style: TextStyle(color: AppColors.textDim))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onLeave();
            },
            child: const Text('Keluar',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Color _colorFromName(String name) {
    switch (name) {
      case 'red': return const Color(0xFFE53935);
      case 'green': return const Color(0xFF43A047);
      case 'blue': return const Color(0xFF1E88E5);
      case 'yellow': return const Color(0xFFFDD835);
      default: return Colors.grey;
    }
  }
}