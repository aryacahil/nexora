import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/colors.dart';
import '../../../../services/uno_service.dart';
import '../../../../services/user_service.dart';
import 'uno_room_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Lobby Page
// ─────────────────────────────────────────────────────────────────────────────

class UnoPage extends StatefulWidget {
  const UnoPage({super.key});

  @override
  State<UnoPage> createState() => _UnoPageState();
}

class _UnoPageState extends State<UnoPage> {
  final UnoService _unoService = UnoService();
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
      final code = await _unoService.createRoom(_myName);
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
      await _unoService.joinRoom(code.trim().toUpperCase(), _myName);
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
            style: TextStyle(
                fontWeight: FontWeight.w900, color: AppColors.primary)),
        content: TextField(
          controller: ctrl,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(
              fontWeight: FontWeight.bold, letterSpacing: 2),
          decoration: InputDecoration(
            hintText: 'Contoh: UABC12',
            hintStyle: TextStyle(
                color: AppColors.textDim, fontWeight: FontWeight.normal),
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
              child: Text('Batal',
                  style: TextStyle(color: AppColors.textDim))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _joinRoom(ctrl.text);
            },
            child: Text('Gabung',
                style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Jika sudah di room → tampilkan room screen
    if (_currentRoomCode != null) {
      return UnoRoomScreen(
        roomCode: _currentRoomCode!,
        myUid: _unoService.uid ?? '',
        unoService: _unoService,
        onLeave: () async {
          await _unoService.leaveRoom(_currentRoomCode!);
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
            // ── Back button ──────────────────────────────
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Row(
                children: [
                  Icon(Icons.chevron_left, color: AppColors.accent, size: 22),
                  Text('KEMBALI',
                      style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Header banner ────────────────────────────
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF7C0000), Color(0xFFE53935)],
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
                  // Kartu dekoratif UNO
                  SizedBox(
                    height: 90,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _miniCard('7', const Color(0xFF1E88E5), angle: -0.25),
                        const SizedBox(width: 4),
                        _miniCard('+2', const Color(0xFF43A047), angle: -0.08),
                        const SizedBox(width: 4),
                        _miniCard('★', Colors.black87,
                            isWild: true, angle: 0.0),
                        const SizedBox(width: 4),
                        _miniCard('⊘', const Color(0xFFE53935), angle: 0.08),
                        const SizedBox(width: 4),
                        _miniCard('+4', Colors.black87,
                            isWild: true, angle: 0.2),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('UNO',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                          fontStyle: FontStyle.italic)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people, color: Colors.white70, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        _myName.isNotEmpty
                            ? 'Bermain sebagai $_myName'
                            : 'Memuat profil...',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Cara Bermain ─────────────────────────────
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
                  _buildRule(Icons.meeting_room_outlined,
                      'Buat atau gabung room dengan kode'),
                  _buildRule(Icons.people,
                      'Butuh minimal 2 pemain, maksimal 6 pemain'),
                  _buildRule(Icons.style,
                      'Setiap pemain mendapat 7 kartu di awal'),
                  _buildRule(Icons.swap_horiz,
                      'Mainkan kartu yang cocok warna atau nilainya'),
                  _buildRule(Icons.block,
                      'Skip ⊘ lewati giliran, Reverse ⇄ balik arah, Draw +2/+4 hukum lawan'),
                  _buildRule(Icons.colorize,
                      'Wild ★ ganti warna sesuka hati, Wild+4 ganti warna dan hukum lawan'),
                  _buildRule(Icons.swap_calls,
                      'Kartu 7 tukar tangan dengan pemain lain, kartu 0 semua tangan berputar'),
                  _buildRule(Icons.timer,
                      'Timer 20 detik per giliran — habis waktu = ambil kartu otomatis'),
                  _buildRule(Icons.emoji_events,
                      'Habiskan semua kartu duluan dan teriak UNO saat tersisa 1 kartu!'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Tombol Aksi ──────────────────────────────
            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary))
                : Column(
                    children: [
                      GestureDetector(
                        onTap: _createRoom,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF7C0000),
                                  Color(0xFFE53935)
                                ]),
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
                              Icon(Icons.add_circle_outline,
                                  color: Colors.white, size: 20),
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
                            border: Border.all(
                                color: Colors.red.withValues(alpha: 0.5)),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.login,
                                  color: Colors.red.shade400, size: 20),
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

            // ── Daftar Room Tersedia ──────────────────────
            Text('ROOM TERSEDIA',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: AppColors.textDim)),
            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
              stream: _unoService.getOpenRooms(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary));
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
                        Icon(Icons.style,
                            color: Colors.red.shade200, size: 24),
                        const SizedBox(width: 12),
                        Text('Belum ada room tersedia.',
                            style: TextStyle(
                                color: AppColors.textDim, fontSize: 13)),
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
                    final r =
                        rooms[index].data() as Map<String, dynamic>;
                    final code = r['code'] ?? '';
                    final players =
                        List<Map<String, dynamic>>.from(r['players'] ?? []);
                    final host = players.isNotEmpty
                        ? players.first['name']
                        : '?';
                    final isFull = players.length >= 6;

                    return GestureDetector(
                      onTap: isFull ? null : () => _joinRoom(code),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: isFull
                                    ? AppColors.border
                                    : Colors.red
                                        .withValues(alpha: 0.3))),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Icon(Icons.style,
                                  color: isFull
                                      ? AppColors.textDim
                                      : Colors.red.shade400,
                                  size: 22),
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
                                          color: AppColors.textMain,
                                          letterSpacing: 1)),
                                  Text(
                                      'Host: $host  •  ${players.length}/6 pemain',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textDim)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                  color: isFull
                                      ? AppColors.border
                                      : Colors.red
                                          .withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(20)),
                              child: Text(
                                isFull ? 'PENUH' : 'GABUNG',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isFull
                                        ? AppColors.textDim
                                        : Colors.red.shade400),
                              ),
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

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _miniCard(String val, Color c,
      {bool isWild = false, double angle = 0}) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: 36,
        height: 52,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.3), blurRadius: 6)
          ],
        ),
        child: Center(
          child: isWild
              ? Text(val,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.white))
              : Text(val,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
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
                      fontSize: 12,
                      color: AppColors.textDim,
                      height: 1.5))),
        ],
      ),
    );
  }
}