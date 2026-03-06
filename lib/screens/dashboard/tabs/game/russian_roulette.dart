import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../core/colors.dart';
import '../../../../services/game_service.dart';
import '../../../../services/user_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Custom Painter: Pistol
// ─────────────────────────────────────────────────────────────────────────────

class PistolPainter extends CustomPainter {
  final Color color;
  final double glowIntensity;

  PistolPainter({required this.color, this.glowIntensity = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bodyPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final darkPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    // Glow effect
    if (glowIntensity > 0) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.3 * glowIntensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.05, h * 0.1, w * 0.9, h * 0.8),
          const Radius.circular(20),
        ),
        glowPaint,
      );
    }

    // ── Laras (barrel) ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.55, h * 0.28, w * 0.42, h * 0.18),
        const Radius.circular(4),
      ),
      bodyPaint,
    );

    // Ujung laras
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.93, h * 0.25, w * 0.05, h * 0.24),
        const Radius.circular(2),
      ),
      darkPaint,
    );

    // ── Badan utama (frame) ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.2, h * 0.22, w * 0.38, h * 0.32),
        const Radius.circular(6),
      ),
      bodyPaint,
    );

    // Highlight badan
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.22, h * 0.24, w * 0.34, h * 0.08),
        const Radius.circular(4),
      ),
      highlightPaint,
    );

    // ── Silinder (cylinder) ──
    canvas.drawCircle(
      Offset(w * 0.42, h * 0.38),
      w * 0.13,
      Paint()
        ..color = color.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill,
    );

    // 6 lubang silinder
    final holePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    final holeBorderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < 6; i++) {
      final angle = i * (pi * 2 / 6) - pi / 2;
      final cx = w * 0.42 + w * 0.075 * cos(angle);
      final cy = h * 0.38 + w * 0.075 * sin(angle);
      canvas.drawCircle(Offset(cx, cy), w * 0.028, holePaint);
      canvas.drawCircle(Offset(cx, cy), w * 0.028, holeBorderPaint);
    }
    canvas.drawCircle(Offset(w * 0.42, h * 0.38), w * 0.02, holePaint);

    // ── Grip ──
    final gripPath = Path()
      ..moveTo(w * 0.22, h * 0.52)
      ..lineTo(w * 0.35, h * 0.52)
      ..lineTo(w * 0.30, h * 0.82)
      ..lineTo(w * 0.16, h * 0.82)
      ..lineTo(w * 0.14, h * 0.65)
      ..close();
    canvas.drawPath(
        gripPath,
        Paint()
          ..color = color.withValues(alpha: 0.75)
          ..style = PaintingStyle.fill);

    // Tekstur grip
    final gripTexturePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 5; i++) {
      final y = h * 0.57 + i * h * 0.045;
      canvas.drawLine(
          Offset(w * 0.16, y), Offset(w * 0.32, y + h * 0.01), gripTexturePaint);
    }

    // ── Trigger guard ──
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.28, h * 0.54)
        ..quadraticBezierTo(w * 0.28, h * 0.70, w * 0.18, h * 0.68),
      Paint()
        ..color = color.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.03
        ..strokeCap = StrokeCap.round,
    );

    // ── Trigger ──
    canvas.drawLine(
      Offset(w * 0.265, h * 0.57),
      Offset(w * 0.245, h * 0.65),
      Paint()
        ..color = darkPaint.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.025
        ..strokeCap = StrokeCap.round,
    );

    // ── Hammer ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.18, h * 0.20, w * 0.06, h * 0.10),
        const Radius.circular(2),
      ),
      darkPaint,
    );

    // ── Sight ──
    canvas.drawRect(Rect.fromLTWH(w * 0.88, h * 0.24, w * 0.04, h * 0.05), darkPaint);
    canvas.drawRect(Rect.fromLTWH(w * 0.38, h * 0.22, w * 0.03, h * 0.04), darkPaint);
  }

  @override
  bool shouldRepaint(PistolPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.glowIntensity != glowIntensity;
}

// ─────────────────────────────────────────────────────────────────────────────
// Lobby Page
// ─────────────────────────────────────────────────────────────────────────────

class RussianRoulettePage extends StatefulWidget {
  const RussianRoulettePage({super.key});

  @override
  State<RussianRoulettePage> createState() => _RussianRoulettePageState();
}

class _RussianRoulettePageState extends State<RussianRoulettePage> {
  final GameService _gameService = GameService();
  final UserService _userService = UserService();
  String _myName = '';
  bool _isLoading = false;
  String? _currentRoomCode;

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final profile = await _userService.getMyProfile();
    if (mounted) setState(() => _myName = profile?['name'] ?? 'Anggota');
  }

  Future<void> _createRoom() async {
    setState(() => _isLoading = true);
    try {
      final code = await _gameService.createRoom(_myName);
      if (mounted) setState(() => _currentRoomCode = code);
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinRoom(String code) async {
    if (code.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await _gameService.joinRoom(code.trim().toUpperCase(), _myName);
      if (mounted) setState(() => _currentRoomCode = code.trim().toUpperCase());
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showJoinDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Masukkan Kode Room',
            style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary)),
        content: TextField(
          controller: ctrl,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: 'Contoh: AB12C',
            hintStyle: TextStyle(color: AppColors.textDim),
            filled: true,
            fillColor: AppColors.bg,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.accent, width: 2)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal', style: TextStyle(color: AppColors.textDim))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _joinRoom(ctrl.text);
            },
            child: Text('Gabung',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_currentRoomCode != null) {
      return _RoomScreen(
        roomCode: _currentRoomCode!,
        myUid: _gameService.uid ?? '',
        myName: _myName,
        gameService: _gameService,
        onLeave: () async {
          await _gameService.leaveRoom(_currentRoomCode!);
          if (mounted) setState(() => _currentRoomCode = null);
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF7C0000), Color(0xFFDC2626)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                      color: Colors.red.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10))
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: 140,
                    height: 80,
                    child: CustomPaint(
                        painter: PistolPainter(
                            color: Colors.white.withValues(alpha: 0.9))),
                  ),
                  const SizedBox(height: 16),
                  const Text('RUSSIAN ROULETTE',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.people, color: Colors.white70, size: 14),
                      SizedBox(width: 6),
                      Text('Uji nyalimu bersama teman-teman!',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Cara Main
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CARA BERMAIN',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: AppColors.textDim)),
                  const SizedBox(height: 12),
                  _buildRule(Icons.meeting_room_outlined, 'Buat atau gabung room dengan kode'),
                  _buildRule(Icons.people, 'Tunggu minimal 2 pemain, lalu mulai'),
                  _buildRule(Icons.ads_click, 'Setiap giliran, pemain menarik pelatuk revolver'),
                  _buildRule(Icons.casino_outlined, '1 dari 6 kemungkinan peluru akan mengenaimu'),
                  _buildRule(Icons.emoji_events_outlined, 'Pemain terakhir yang selamat adalah pemenang!'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tombol Aksi
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : Column(
                    children: [
                      GestureDetector(
                        onTap: _createRoom,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFF7C0000), Color(0xFFDC2626)]),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5))
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
                              SizedBox(width: 10),
                              Text('BUAT ROOM BARU',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _showJoinDialog,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.login, color: Colors.red.shade400, size: 20),
                              const SizedBox(width: 10),
                              Text('GABUNG ROOM',
                                  style: TextStyle(
                                      color: Colors.red.shade400,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 32),

            // Daftar Room
            Text('ROOM TERSEDIA',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: AppColors.textDim)),
            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
              stream: _gameService.getOpenRooms(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border)),
                    child: Row(
                      children: [
                        Icon(Icons.meeting_room_outlined,
                            color: Colors.red.shade200, size: 24),
                        const SizedBox(width: 12),
                        Text('Belum ada room tersedia.',
                            style: TextStyle(color: AppColors.textDim, fontSize: 13)),
                      ],
                    ),
                  );
                }
                final rooms = snapshot.data!.docs;
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rooms.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final r = rooms[index].data() as Map<String, dynamic>;
                    final code = r['code'] ?? '';
                    final players = List.from(r['players'] ?? []);
                    final host = players.isNotEmpty ? players.first['name'] : '?';

                    return GestureDetector(
                      onTap: () => _joinRoom(code),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3))),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Icon(Icons.meeting_room,
                                  color: Colors.red.shade400, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Room: $code',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.textMain)),
                                  Text('Host: $host  •  ${players.length}/6 pemain',
                                      style: TextStyle(
                                          fontSize: 11, color: AppColors.textDim)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text('GABUNG',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade400)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRule(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 14, color: Colors.red.shade400),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textDim, height: 1.5))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Room Screen
// ─────────────────────────────────────────────────────────────────────────────

class _RoomScreen extends StatefulWidget {
  final String roomCode;
  final String myUid;
  final String myName;
  final GameService gameService;
  final VoidCallback onLeave;

  const _RoomScreen({
    required this.roomCode,
    required this.myUid,
    required this.myName,
    required this.gameService,
    required this.onLeave,
  });

  @override
  State<_RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<_RoomScreen> with TickerProviderStateMixin {
  bool _isShooting = false;
  bool _showBlast = false;

  late AnimationController _recoilController;
  late AnimationController _pulseController;
  late AnimationController _flashController;
  late AnimationController _glowController;

  late Animation<double> _recoilAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _flashAnimation;
  late Animation<double> _glowAnimation;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();

    // Recoil - pistol mundur saat ditembak/diklik
    _recoilController = AnimationController(
        duration: const Duration(milliseconds: 350), vsync: this);
    _recoilAnimation = TweenSequence([
      TweenSequenceItem(
          tween: Tween<double>(begin: 0, end: -20)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 25),
      TweenSequenceItem(
          tween: Tween<double>(begin: -20, end: 0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 75),
    ]).animate(_recoilController);

    // Pulse saat giliran
    _pulseController = AnimationController(
        duration: const Duration(milliseconds: 900), vsync: this)
      ..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    // Flash merah
    _flashController = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);
    _flashAnimation = Tween<double>(begin: 1, end: 0).animate(
        CurvedAnimation(parent: _flashController, curve: Curves.easeOut));

    // Glow pistol saat giliran
    _glowController = AnimationController(
        duration: const Duration(milliseconds: 1200), vsync: this)
      ..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _recoilController.dispose();
    _pulseController.dispose();
    _flashController.dispose();
    _glowController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playSound(String type) async {
    try {
      switch (type) {
        case 'spin':
          await _audioPlayer.play(AssetSource('sounds/spin.wav'));
          break;
        case 'click':
          await _audioPlayer.play(AssetSource('sounds/click.wav'));
          break;
        case 'gunshot':
          await _audioPlayer.play(AssetSource('sounds/gunshot.wav'));
          break;
        case 'win':
          await _audioPlayer.play(AssetSource('sounds/win.wav'));
          break;
      }
    } catch (_) {}
  }

  Future<void> _pullTrigger() async {
    if (_isShooting) return;
    setState(() => _isShooting = true);

    // Cek hasil sebelum animasi
    final doc = await widget.gameService.roomStream(widget.roomCode).first;
    final data = doc.data() as Map<String, dynamic>;
    final triggerCount = (data['triggerCount'] as int) + 1;
    final bulletPosition = data['bulletPosition'] as int;
    final isShot = triggerCount == bulletPosition;

    // Putar suara spin dulu
    await _playSound('spin');
    await Future.delayed(const Duration(milliseconds: 700));

    if (isShot) {
      await _playSound('gunshot');
      _recoilController.forward(from: 0);
      _flashController.forward(from: 0);
      setState(() => _showBlast = true);
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) setState(() => _showBlast = false);
    } else {
      await _playSound('click');
      _recoilController.forward(from: 0);
    }

    try {
      await widget.gameService.pullTrigger(widget.roomCode);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isShooting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: widget.gameService.roomStream(widget.roomCode),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            backgroundColor: AppColors.bg,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.meeting_room_outlined, size: 56, color: AppColors.textDim),
                  const SizedBox(height: 16),
                  Text('Room tidak ditemukan.',
                      style: TextStyle(color: AppColors.textDim)),
                  TextButton(
                      onPressed: widget.onLeave,
                      child: Text('Kembali',
                          style: TextStyle(color: AppColors.accent))),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final status = data['status'] ?? 'waiting';
        final players = List<Map<String, dynamic>>.from(data['players'] ?? []);
        final currentTurn = data['currentTurn'] ?? 0;

        // ✅ FIX: pakai 'gameLog'
        final gameLog = List<String>.from(data['gameLog'] ?? []);
        final winner = data['winner'] ?? '';

        final alivePlayers = players.where((p) => p['isAlive'] == true).toList();
        final isHost =
            players.any((p) => p['uid'] == widget.myUid && p['isHost'] == true);
        final myPlayer = players.firstWhere(
            (p) => p['uid'] == widget.myUid,
            orElse: () => {});
        final isAlive = myPlayer['isAlive'] ?? false;
        final isMyTurn = status == 'playing' &&
            alivePlayers.isNotEmpty &&
            alivePlayers[currentTurn % alivePlayers.length]['uid'] ==
                widget.myUid &&
            isAlive;

        if (status == 'finished') _playSound('win');

        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: AppColors.bg,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.exit_to_app, color: Colors.red.shade400, size: 28),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: AppColors.card,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
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
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ROOM: ${widget.roomCode}',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.red.shade400,
                        letterSpacing: 2)),
                Text(
                  status == 'waiting'
                      ? 'Menunggu pemain...'
                      : status == 'playing'
                          ? 'Sedang bermain'
                          : 'Game selesai',
                  style: TextStyle(fontSize: 10, color: AppColors.textDim),
                ),
              ],
            ),
          ),
          body: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                children: [

                  // ── Game Selesai ──────────────────────────
                  if (status == 'finished') ...[
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
                                  color: Colors.white70,
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
                                  widget.gameService.restartGame(widget.roomCode),
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
                    const SizedBox(height: 20),
                  ],

                  // ── Pistol Animasi ────────────────────────
                  if (status == 'playing') ...[
                    const SizedBox(height: 16),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.symmetric(
                          vertical: 28, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF120000),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isMyTurn
                              ? Colors.red.withValues(alpha: 0.6)
                              : Colors.white.withValues(alpha: 0.06),
                          width: isMyTurn ? 2 : 1,
                        ),
                        boxShadow: isMyTurn
                            ? [
                                BoxShadow(
                                    color: Colors.red.withValues(alpha: 0.25),
                                    blurRadius: 28,
                                    spreadRadius: 2)
                              ]
                            : [],
                      ),
                      child: Column(
                        children: [
                          // Pistol dengan recoil + glow + pulse
                          AnimatedBuilder(
                            animation: Listenable.merge(
                                [_recoilAnimation, _glowAnimation]),
                            builder: (context, _) {
                              return Transform.translate(
                                offset: Offset(_recoilAnimation.value, 0),
                                child: ScaleTransition(
                                  scale: isMyTurn
                                      ? _pulseAnimation
                                      : const AlwaysStoppedAnimation(1.0),
                                  child: SizedBox(
                                    width: 220,
                                    height: 120,
                                    child: CustomPaint(
                                      painter: PistolPainter(
                                        color: isMyTurn
                                            ? Colors.red.shade400
                                            : Colors.grey.shade600,
                                        glowIntensity: isMyTurn
                                            ? _glowAnimation.value
                                            : 0,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 14),

                          // Status badge
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              key: ValueKey(isMyTurn),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 7),
                              decoration: BoxDecoration(
                                color: isMyTurn
                                    ? Colors.red.withValues(alpha: 0.15)
                                    : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isMyTurn
                                      ? Colors.red.withValues(alpha: 0.4)
                                      : Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isMyTurn
                                        ? Icons.radio_button_checked
                                        : isAlive
                                            ? Icons.hourglass_empty
                                            : Icons.person_off,
                                    size: 13,
                                    color: isMyTurn
                                        ? Colors.red.shade400
                                        : Colors.white38,
                                  ),
                                  const SizedBox(width: 7),
                                  Text(
                                    isMyTurn
                                        ? 'Giliran kamu! Tarik pelatuk...'
                                        : isAlive
                                            ? 'Tunggu giliran kamu...'
                                            : 'Kamu sudah gugur',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isMyTurn
                                          ? Colors.red.shade400
                                          : Colors.white38,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tombol tembak
                    if (isMyTurn)
                      GestureDetector(
                        onTap: _isShooting ? null : _pullTrigger,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isShooting
                                  ? [Colors.grey.shade700, Colors.grey.shade800]
                                  : [const Color(0xFF7C0000), const Color(0xFFDC2626)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8))
                            ],
                          ),
                          alignment: Alignment.center,
                          child: _isShooting
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text('Memutar silinder...',
                                        style: TextStyle(
                                            color: Colors.white70, fontSize: 14)),
                                  ],
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.radio_button_checked,
                                        color: Colors.white, size: 20),
                                    SizedBox(width: 10),
                                    Text('TARIK PELATUK',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 2)),
                                  ],
                                ),
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],

                  // ── Daftar Pemain ─────────────────────────
                  Text('PEMAIN (${players.length}/6)',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: AppColors.textDim)),
                  const SizedBox(height: 10),

                  ...players.map((p) {
                    final isCurrentTurn = status == 'playing' &&
                        alivePlayers.isNotEmpty &&
                        alivePlayers[currentTurn % alivePlayers.length]['uid'] ==
                            p['uid'];
                    final alive = p['isAlive'] ?? true;
                    final isMe = p['uid'] == widget.myUid;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isCurrentTurn
                            ? Colors.red.withValues(alpha: 0.12)
                            : AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCurrentTurn
                              ? Colors.red.shade400
                              : AppColors.border,
                          width: isCurrentTurn ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: alive
                                  ? (isCurrentTurn
                                      ? Colors.red.withValues(alpha: 0.2)
                                      : AppColors.primary.withValues(alpha: 0.15))
                                  : Colors.grey.withValues(alpha: 0.2),
                            ),
                            child: Icon(
                              alive
                                  ? (isCurrentTurn
                                      ? Icons.radio_button_checked
                                      : Icons.person)
                                  : Icons.person_off,
                              color: alive
                                  ? (isCurrentTurn
                                      ? Colors.red.shade400
                                      : AppColors.primary)
                                  : Colors.grey,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(p['name'] ?? '',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                            color: alive
                                                ? AppColors.textMain
                                                : AppColors.textDim,
                                            decoration: alive
                                                ? null
                                                : TextDecoration.lineThrough)),
                                    if (isMe) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: Text('KAMU',
                                            style: TextStyle(
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary)),
                                      ),
                                    ],
                                    if (p['isHost'] == true) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                            color: Colors.orange
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.star,
                                                size: 8,
                                                color: Colors.orange.shade700),
                                            const SizedBox(width: 2),
                                            Text('HOST',
                                                style: TextStyle(
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        Colors.orange.shade700)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      alive
                                          ? (isCurrentTurn
                                              ? Icons.arrow_right_alt
                                              : Icons.hourglass_empty)
                                          : Icons.close,
                                      size: 12,
                                      color: isCurrentTurn
                                          ? Colors.red.shade400
                                          : AppColors.textDim,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      alive
                                          ? isCurrentTurn
                                              ? 'Giliran ini!'
                                              : 'Menunggu giliran'
                                          : 'Gugur',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: isCurrentTurn
                                              ? Colors.red.shade400
                                              : AppColors.textDim),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  // ── Tombol Mulai ──────────────────────────
                  if (status == 'waiting' && isHost) ...[
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: players.length >= 2
                          ? () => widget.gameService.startGame(widget.roomCode)
                          : null,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: players.length >= 2
                              ? const LinearGradient(colors: [
                                  Color(0xFF7C0000),
                                  Color(0xFFDC2626)
                                ])
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
                              color: players.length >= 2
                                  ? Colors.white
                                  : AppColors.textDim,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              players.length < 2
                                  ? 'Menunggu pemain lain...'
                                  : 'MULAI GAME',
                              style: TextStyle(
                                  color: players.length >= 2
                                      ? Colors.white
                                      : AppColors.textDim,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  if (status == 'waiting' && !isHost) ...[
                    const SizedBox(height: 16),
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
                                color: AppColors.primary, strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Text('Menunggu host memulai...',
                              style: TextStyle(
                                  color: AppColors.textDim, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],

                  // ── Log Game ──────────────────────────────
                  if (gameLog.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('LOG GAME',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: AppColors.textDim)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: gameLog.reversed.take(10).map((entry) {
                          IconData logIcon;
                          Color logColor;
                          String displayText;

                          if (entry.startsWith('MATI:')) {
                            logIcon = Icons.close_rounded;
                            logColor = Colors.red;
                            displayText = entry.substring(5).trim();
                          } else if (entry.startsWith('SELAMAT:')) {
                            logIcon = Icons.check_circle_outline;
                            logColor = Colors.green;
                            displayText = entry.substring(8).trim();
                          } else if (entry.startsWith('MENANG:')) {
                            logIcon = Icons.emoji_events;
                            logColor = Colors.amber;
                            displayText = entry.substring(7).trim();
                          } else if (entry.startsWith('RESET:')) {
                            logIcon = Icons.refresh;
                            logColor = Colors.blue;
                            displayText = entry.substring(6).trim();
                          } else if (entry.startsWith('MULAI:')) {
                            logIcon = Icons.play_circle_outline;
                            logColor = AppColors.primary;
                            displayText = entry.substring(6).trim();
                          } else {
                            logIcon = Icons.info_outline;
                            logColor = AppColors.textDim;
                            displayText = entry;
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                      color: logColor.withValues(alpha: 0.13),
                                      borderRadius: BorderRadius.circular(7)),
                                  child: Icon(logIcon, size: 13, color: logColor),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(displayText,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textMain,
                                          height: 1.5)),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),

              // Flash merah saat kena tembak
              if (_showBlast)
                AnimatedBuilder(
                  animation: _flashAnimation,
                  builder: (context, _) => Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        color: Colors.red
                            .withValues(alpha: 0.5 * _flashAnimation.value),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}