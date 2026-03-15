import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../core/colors.dart';
import '../../../../../services/uno_service.dart';
import '../../../../../services/user_service.dart';
import 'uno_room_screen.dart';

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
            style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textMain)),
        content: TextField(
          controller: ctrl,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 3, fontSize: 18),
          decoration: InputDecoration(
            hintText: 'Contoh: UABC12',
            hintStyle: TextStyle(color: AppColors.textDim, fontWeight: FontWeight.normal, letterSpacing: 0),
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
                borderSide: const BorderSide(color: Color(0xFFE53935), width: 2)),
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
            child: const Text('Gabung',
                style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          children: [
            // Back button
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Row(
                children: [
                  Icon(Icons.chevron_left, color: AppColors.accent, size: 20),
                  Text('KEMBALI',
                      style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Header ──────────────────────────────────────────────────────
            _buildHeader(),
            const SizedBox(height: 20),

            // ── Action buttons ───────────────────────────────────────────────
            _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: CircularProgressIndicator(color: Color(0xFFE53935)),
                    ))
                : _buildActionButtons(),
            const SizedBox(height: 24),

            // ── Rules ────────────────────────────────────────────────────────
            _buildRules(),
            const SizedBox(height: 24),

            // ── Room list ────────────────────────────────────────────────────
            _buildSectionLabel('ROOM TERSEDIA'),
            const SizedBox(height: 10),
            _buildRoomList(),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0000),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Card stack preview
          SizedBox(
            width: 72,
            height: 80,
            child: Stack(
              children: [
                _miniCard('3', const Color(0xFF1565C0), angle: -0.22),
                _miniCard('+2', const Color(0xFF2E7D32), angle: -0.07),
                _miniCard('W', const Color(0xFF1A1A2E), angle: 0.07, isWild: true),
                _miniCard('+4', const Color(0xFF1A1A2E), angle: 0.22, isWild: true),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('UNO',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                        fontStyle: FontStyle.italic,
                        height: 1)),
                const SizedBox(height: 6),
                Container(
                  height: 2,
                  width: 48,
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 12, color: Colors.white38),
                    const SizedBox(width: 5),
                    Text(
                      _myName.isNotEmpty ? _myName : 'Memuat...',
                      style: const TextStyle(fontSize: 11, color: Colors.white38),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniCard(String val, Color c, {double angle = 0, bool isWild = false}) {
    return Positioned(
      left: angle > 0 ? angle * 80 + 8 : 0,
      top: angle.abs() * 20,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: 32,
          height: 48,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 5),
            ],
          ),
          child: Center(
            child: Text(val,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: isWild || c != const Color(0xFFF9A825)
                        ? Colors.white
                        : Colors.black87)),
          ),
        ),
      ),
    );
  }

  // ── Action Buttons ─────────────────────────────────────────────────────────

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _createRoom,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: const Color(0xFFD32F2F),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('BUAT ROOM',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 1.5)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: _showJoinDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login, color: Colors.red.shade400, size: 18),
                  const SizedBox(width: 8),
                  Text('GABUNG',
                      style: TextStyle(
                          color: Colors.red.shade400,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 1.5)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Rules ──────────────────────────────────────────────────────────────────

  Widget _buildRules() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('CARA BERMAIN'),
          const SizedBox(height: 14),
          _rule(Icons.meeting_room_outlined, 'Buat atau gabung room dengan kode unik'),
          _rule(Icons.people_outline, 'Minimal 2 pemain, maksimal 6 pemain'),
          _rule(Icons.style_outlined, 'Setiap pemain mendapat 7 kartu di awal'),
          _rule(Icons.swap_horiz, 'Mainkan kartu yang cocok warna atau nilainya'),
          _rule(Icons.block, 'Skip: lewati giliran lawan'),
          _rule(Icons.swap_horiz, 'Reverse: balik arah putaran'),
          _rule(Icons.add_circle_outline, 'Draw +2 / +4: hukum lawan ambil kartu'),
          _rule(Icons.color_lens_outlined, 'Wild: ganti warna, Wild+4: ganti warna dan hukum lawan'),
          _rule(Icons.timer_outlined, 'Timer 20 detik per giliran — habis = auto ambil kartu'),
          _rule(Icons.emoji_events_outlined, 'Habiskan semua kartu duluan dan tekan UNO saat tersisa 1!'),
        ],
      ),
    );
  }

  Widget _rule(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 13, color: Colors.red.shade400),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 12, color: AppColors.textDim, height: 1.5)),
          ),
        ],
      ),
    );
  }

  // ── Room List ──────────────────────────────────────────────────────────────

  Widget _buildRoomList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _unoService.getOpenRooms(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(color: Color(0xFFE53935), strokeWidth: 2),
          ));
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
                Icon(Icons.search_off, color: AppColors.textDim, size: 20),
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
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final r = rooms[index].data() as Map<String, dynamic>;
            final code = r['code'] ?? '';
            final players = List<Map<String, dynamic>>.from(r['players'] ?? []);
            final host = players.isNotEmpty ? players.first['name'] : '?';
            final isFull = players.length >= 6;

            return GestureDetector(
              onTap: isFull ? null : () => _joinRoom(code),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: isFull
                          ? AppColors.border
                          : Colors.red.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    // Color pip indicator
                    Container(
                      width: 4,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isFull ? AppColors.border : Colors.red.shade700,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(code,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: isFull ? AppColors.textDim : AppColors.textMain,
                                  letterSpacing: 2)),
                          const SizedBox(height: 2),
                          Text('Host: $host',
                              style: TextStyle(fontSize: 11, color: AppColors.textDim)),
                        ],
                      ),
                    ),
                    // Player count
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${players.length}/6',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: isFull ? AppColors.textDim : AppColors.textMain)),
                        Text('pemain',
                            style: TextStyle(fontSize: 9, color: AppColors.textDim)),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isFull
                            ? AppColors.border
                            : const Color(0xFFD32F2F),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isFull ? 'PENUH' : 'MASUK',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: isFull ? AppColors.textDim : Colors.white,
                            letterSpacing: 1),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(label,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.5,
            color: AppColors.textDim));
  }
}