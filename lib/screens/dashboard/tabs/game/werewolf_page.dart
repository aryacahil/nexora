import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../../core/colors.dart';
import '../../../../services/user_service.dart';
import '../../../../services/werewolf_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TTS Narrator (tidak berubah)
// ─────────────────────────────────────────────────────────────────────────────

class WerewolfNarrator {
  static final FlutterTts _tts = FlutterTts();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await _tts.setLanguage('id-ID');
    await _tts.setSpeechRate(0.85);
    await _tts.setVolume(1.0);
    await _tts.setPitch(0.9);
    _initialized = true;
  }

  static Future<void> speak(String text) async {
    await init(); await _tts.stop(); await _tts.speak(text);
  }
  static Future<void> stop() async => await _tts.stop();

  static Future<void> onNight(int round)    => speak('Malam ke $round telah tiba. Seluruh penduduk desa tertidur. Para werewolf terbangun dari kegelapan.');
  static Future<void> onDay(int round)      => speak('Hari ke $round. Matahari terbit. Penduduk desa berkumpul untuk berdiskusi.');
  static Future<void> onVoting()            => speak('Saatnya pemungutan suara. Pilih siapa yang paling mencurigakan di antara kalian.');
  static Future<void> onPlayerDied(String name)      => speak('$name ditemukan tewas malam ini.');
  static Future<void> onPlayerVotedOut(String name)  => speak('$name dieksekusi oleh warga desa.');
  static Future<void> onNobodyDied()        => speak('Sunyi. Tidak ada korban malam ini.');
  static Future<void> onVillageWin()        => speak('Selamat! Seluruh werewolf telah dibasmi. Desa selamat!');
  static Future<void> onWolfWin()           => speak('Werewolf menguasai desa. Semua penduduk telah binasa.');
  static Future<void> onHunterRevenge()     => speak('Hunter gugur! Ia mengangkat senjata terakhirnya untuk membalas dendam.');
  static Future<void> onWolfAttack()        => speak('Para werewolf menyerang di kegelapan malam.');
  static Future<void> onGameStart()         => speak('Permainan dimulai. Semoga keberuntungan berpihak padamu.');
  static Future<void> onJesterWin()         => speak('Jester berhasil dieksekusi oleh warga. Jester menang!');
}

// ─────────────────────────────────────────────────────────────────────────────
// Role Icon Helper (tidak berubah)
// ─────────────────────────────────────────────────────────────────────────────

IconData _roleIconData(String role) {
  switch (role) {
    case WRole.werewolf:  return Icons.pets;
    case WRole.alphaWolf: return Icons.crisis_alert;
    case WRole.lycan:     return Icons.masks;
    case WRole.villager:  return Icons.person;
    case WRole.seer:      return Icons.visibility;
    case WRole.doctor:    return Icons.medical_services;
    case WRole.hunter:    return Icons.gps_fixed;
    case WRole.witch:     return Icons.science;
    case WRole.bodyguard: return Icons.shield;
    case WRole.mayor:     return Icons.star;
    case WRole.cupid:     return Icons.favorite;
    case WRole.jester:    return Icons.sentiment_very_dissatisfied;
    default:              return Icons.help_outline;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lobby — layout mengikuti UNO
// ─────────────────────────────────────────────────────────────────────────────

class WerewolfPage extends StatefulWidget {
  const WerewolfPage({super.key});
  @override
  State<WerewolfPage> createState() => _WerewolfPageState();
}

class _WerewolfPageState extends State<WerewolfPage> {
  final WerewolfService _svc         = WerewolfService();
  final UserService     _userService = UserService();
  String  _myName   = '';
  bool    _isLoading = false;
  String? _roomCode;

  static const _purple     = Color(0xFF6B21A8);
  static const _purpleDark = Color(0xFF1A1A2E);

  @override
  void initState() {
    super.initState();
    _loadName();
    WerewolfNarrator.init();
  }

  @override
  void dispose() {
    WerewolfNarrator.stop();
    super.dispose();
  }

  Future<void> _loadName() async {
    final p = await _userService.getMyProfile();
    if (mounted) setState(() => _myName = p?['name'] ?? 'Anggota');
  }

  Future<void> _createRoom() async {
    setState(() => _isLoading = true);
    try {
      final code = await _svc.createRoom(_myName);
      if (mounted) setState(() => _roomCode = code);
    } catch (e) {
      _snack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinRoom(String code) async {
    if (code.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await _svc.joinRoom(code.trim().toUpperCase(), _myName);
      if (mounted) setState(() => _roomCode = code.trim().toUpperCase());
    } catch (e) {
      _snack(e.toString(), error: true);
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
          style: const TextStyle(fontWeight: FontWeight.bold,
            letterSpacing: 2, fontSize: 18),
          decoration: InputDecoration(
            hintText: 'Contoh: AB12C',
            hintStyle: TextStyle(color: AppColors.textDim,
              fontWeight: FontWeight.normal, letterSpacing: 0),
            filled: true, fillColor: AppColors.bg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.accent, width: 2)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: AppColors.textDim))),
          TextButton(
            onPressed: () { Navigator.pop(context); _joinRoom(ctrl.text); },
            child: Text('Gabung',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_roomCode != null) {
      return WerewolfRoomScreen(
        roomCode: _roomCode!,
        myUid: _svc.uid ?? '',
        service: _svc,
        onLeave: () async {
          await _svc.leaveRoom(_roomCode!);
          if (mounted) setState(() => _roomCode = null);
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          children: [
            // ── Back ─────────────────────────────────────────────────
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Row(children: [
                Icon(Icons.chevron_left, color: AppColors.accent, size: 20),
                Text('KEMBALI', style: TextStyle(
                  color: AppColors.accent, fontSize: 10,
                  fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ]),
            ),
            const SizedBox(height: 20),

            // ── Header card ───────────────────────────────────────────
            _buildHeader(),
            const SizedBox(height: 20),

            // ── Action buttons ────────────────────────────────────────
            _isLoading
                ? const Center(child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(color: _purple)))
                : _buildActionButtons(),
            const SizedBox(height: 24),

            // ── Roles ─────────────────────────────────────────────────
            _buildRoles(),
            const SizedBox(height: 24),

            // ── Room list ─────────────────────────────────────────────
            _buildSectionLabel('ROOM TERSEDIA'),
            const SizedBox(height: 10),
            _buildRoomList(),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: _purpleDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(
          color: Colors.deepPurple.withValues(alpha: 0.15),
          blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Row(children: [
        // Wolf icon
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle),
          child: const Icon(Icons.pets, color: Colors.white, size: 38)),
        const SizedBox(width: 20),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('WEREWOLF', style: TextStyle(
              color: Colors.white, fontSize: 28,
              fontWeight: FontWeight.w900, letterSpacing: 3)),
            const SizedBox(height: 6),
            Container(height: 2, width: 48,
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade400,
                borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.person_outline, size: 12, color: Colors.white38),
              const SizedBox(width: 5),
              Text(_myName.isNotEmpty ? _myName : 'Memuat...',
                style: const TextStyle(fontSize: 11, color: Colors.white38)),
            ]),
          ],
        )),
      ]),
    );
  }

  // ── Action Buttons ────────────────────────────────────────────────────────

  Widget _buildActionButtons() {
    return Row(children: [
      Expanded(
        child: GestureDetector(
          onTap: _createRoom,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_purpleDark, _purple]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(
                color: Colors.deepPurple.withValues(alpha: 0.35),
                blurRadius: 12, offset: const Offset(0, 5))],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('BUAT ROOM', style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w900,
                  fontSize: 13, letterSpacing: 1.5)),
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
              border: Border.all(
                color: Colors.deepPurple.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.login, color: Colors.deepPurple.shade300, size: 18),
                const SizedBox(width: 8),
                Text('GABUNG', style: TextStyle(
                  color: Colors.deepPurple.shade300,
                  fontWeight: FontWeight.w900,
                  fontSize: 13, letterSpacing: 1.5)),
              ],
            ),
          ),
        ),
      ),
    ]);
  }

  // ── Roles ─────────────────────────────────────────────────────────────────

  Widget _buildRoles() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildSectionLabel('SEMUA ROLE'),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 8, children: [
          WRole.werewolf, WRole.alphaWolf, WRole.lycan,
          WRole.villager, WRole.seer, WRole.doctor,
          WRole.hunter, WRole.witch, WRole.bodyguard,
          WRole.mayor, WRole.cupid, WRole.jester,
        ].map((r) => GestureDetector(
          onTap: () => _showRoleDetail(r),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _roleColor(r).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _roleColor(r).withValues(alpha: 0.3))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(_roleIconData(r), size: 13, color: _roleColor(r)),
              const SizedBox(width: 5),
              Text(WRole.label(r), style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold,
                color: _roleColor(r))),
            ]),
          ),
        )).toList()),
        const SizedBox(height: 8),
        Text('Tap role untuk melihat deskripsi',
          style: TextStyle(fontSize: 10, color: AppColors.textDim)),
      ]),
    );
  }

  // ── Room List ─────────────────────────────────────────────────────────────

  Widget _buildRoomList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _svc.getOpenRooms(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(
              color: _purple, strokeWidth: 2)));
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border)),
            child: Row(children: [
              Icon(Icons.search_off, color: AppColors.textDim, size: 20),
              const SizedBox(width: 12),
              Text('Belum ada room tersedia.',
                style: TextStyle(color: AppColors.textDim, fontSize: 13)),
            ]),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snap.data!.docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final r       = snap.data!.docs[i].data() as Map<String, dynamic>;
            final code    = r['code'] ?? '';
            final players = List.from(r['players'] ?? []);
            final host    = players.isNotEmpty ? players.first['name'] : '?';
            final isFull  = players.length >= 12;

            return GestureDetector(
              onTap: isFull ? null : () => _joinRoom(code),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isFull
                        ? AppColors.border
                        : Colors.deepPurple.withValues(alpha: 0.25)),
                ),
                child: Row(children: [
                  // Color pip
                  Container(
                    width: 4, height: 36,
                    decoration: BoxDecoration(
                      color: isFull
                          ? AppColors.border : Colors.deepPurple.shade700,
                      borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(code, style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w900,
                        color: isFull ? AppColors.textDim : AppColors.textMain,
                        letterSpacing: 2)),
                      const SizedBox(height: 2),
                      Text('Host: $host',
                        style: TextStyle(fontSize: 11,
                          color: AppColors.textDim)),
                    ],
                  )),
                  // Player count
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${players.length}/12', style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w900,
                      color: isFull ? AppColors.textDim : AppColors.textMain)),
                    Text('pemain',
                      style: TextStyle(fontSize: 9, color: AppColors.textDim)),
                  ]),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isFull
                          ? AppColors.border
                          : Colors.deepPurple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20)),
                    child: Text(isFull ? 'PENUH' : 'MASUK',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
                        color: isFull
                            ? AppColors.textDim : Colors.deepPurple.shade300,
                        letterSpacing: 1)),
                  ),
                ]),
              ),
            );
          },
        );
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _showRoleDetail(String role) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: _roleColor(role).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14)),
              child: Icon(_roleIconData(role),
                color: _roleColor(role), size: 26)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(WRole.label(role), style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w900,
                color: _roleColor(role))),
              Text(_roleTeam(role),
                style: TextStyle(fontSize: 11, color: AppColors.textDim)),
            ]),
          ]),
          const SizedBox(height: 16),
          Text(WRole.description(role), style: TextStyle(
            fontSize: 13, color: AppColors.textDim, height: 1.6)),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  String _roleTeam(String role) {
    if (WRole.isWolf(role)) return 'Tim Werewolf';
    if (role == WRole.jester || role == WRole.cupid) return 'Netral';
    return 'Tim Desa';
  }

  Color _roleColor(String role) {
    if (WRole.isWolf(role))        return Colors.red.shade400;
    if (role == WRole.seer)        return Colors.purple.shade300;
    if (role == WRole.doctor)      return Colors.green.shade400;
    if (role == WRole.hunter)      return Colors.orange.shade400;
    if (role == WRole.witch)       return Colors.teal.shade300;
    if (role == WRole.bodyguard)   return Colors.blue.shade400;
    if (role == WRole.mayor)       return Colors.amber.shade400;
    if (role == WRole.cupid)       return Colors.pink.shade400;
    if (role == WRole.jester)      return Colors.lime.shade400;
    return AppColors.textDim;
  }

  Widget _buildSectionLabel(String label) => Text(label, style: TextStyle(
    fontSize: 10, fontWeight: FontWeight.w900,
    letterSpacing: 2.5, color: AppColors.textDim));
}

// ─────────────────────────────────────────────────────────────────────────────
// Room Screen
// ─────────────────────────────────────────────────────────────────────────────

class WerewolfRoomScreen extends StatefulWidget {
  final String roomCode;
  final String myUid;
  final WerewolfService service;
  final VoidCallback onLeave;

  const WerewolfRoomScreen({
    super.key,
    required this.roomCode,
    required this.myUid,
    required this.service,
    required this.onLeave,
  });

  @override
  State<WerewolfRoomScreen> createState() => _WerewolfRoomScreenState();
}

class _WerewolfRoomScreenState extends State<WerewolfRoomScreen>
    with SingleTickerProviderStateMixin {
  bool _roleRevealed = false;
  bool _actionDone = false;

  // ── Transisi ──────────────────────────────────────────────────
  String _lastPhase = '';
  int _lastRound = 0;
  String _lastLog = '';
  bool _showTransition = false;
  String _transitionLabel = '';
  List<Color> _transitionColors = [];
  IconData _transitionIcon = Icons.nightlight_round;
  late AnimationController _transitionCtrl;
  late Animation<double> _transitionAnim;

  @override
  void initState() {
    super.initState();
    WerewolfNarrator.init();
    _transitionCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _transitionAnim = CurvedAnimation(parent: _transitionCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    WerewolfNarrator.stop();
    _transitionCtrl.dispose();
    super.dispose();
  }

  // ── Deteksi perubahan fase & trigger TTS ──────────────────────
  void _handlePhaseChange(String newPhase, int newRound, List<String> gameLog) {
    final latestLog = gameLog.isNotEmpty ? gameLog.last : '';
    final phaseChanged = newPhase != _lastPhase;
    final roundChanged = newRound != _lastRound;
    final newLogEntry = latestLog != _lastLog && latestLog.isNotEmpty;

    if (phaseChanged || (roundChanged && newPhase == WPhase.night)) {
      _lastPhase = newPhase;
      _lastRound = newRound;

      switch (newPhase) {
        case WPhase.night:
          _triggerTransition(
            label: 'MALAM KE-$newRound',
            colors: [const Color(0xFF0F0C29), const Color(0xFF1a0533)],
            icon: Icons.nightlight_round,
          );
          WerewolfNarrator.onNight(newRound);
          break;

        case WPhase.nightResult:
          _triggerTransition(
            label: 'FAJAR TIBA',
            colors: [const Color(0xFF373B44), const Color(0xFF4286f4)],
            icon: Icons.wb_twilight,
          );
          // Cek apakah ada korban di log terbaru
          final nightLogs = gameLog.where((l) => l.startsWith('MALAM:')).toList();
          if (nightLogs.isNotEmpty) {
            final lastNight = nightLogs.last.replaceAll('MALAM: ', '');
            if (lastNight.contains('tidak ada korban') || lastNight.contains('selamat')) {
              WerewolfNarrator.onNobodyDied();
            } else {
              WerewolfNarrator.speak(lastNight);
            }
          }
          break;

        case WPhase.day:
          _triggerTransition(
            label: 'HARI KE-$newRound',
            colors: [const Color(0xFFf7971e), const Color(0xFFffd200)],
            icon: Icons.wb_sunny,
          );
          WerewolfNarrator.onDay(newRound);
          break;

        case WPhase.voting:
          _triggerTransition(
            label: 'VOTING DIMULAI',
            colors: [const Color(0xFFe53935), const Color(0xFFb71c1c)],
            icon: Icons.how_to_vote,
          );
          WerewolfNarrator.onVoting();
          break;

        case WPhase.voteResult:
          _triggerTransition(
            label: 'HASIL VOTING',
            colors: [const Color(0xFF4A00E0), const Color(0xFF8E2DE2)],
            icon: Icons.balance,
          );
          // Baca hasil voting dari log
          final voteLogs = gameLog.where((l) => l.startsWith('VOTING:')).toList();
          if (voteLogs.isNotEmpty) {
            final lastVote = voteLogs.last.replaceAll('VOTING: ', '');
            WerewolfNarrator.speak(lastVote);
          }
          break;

        case WPhase.hunterRevenge:
          _triggerTransition(
            label: 'HUNTER BALAS DENDAM',
            colors: [const Color(0xFFf7971e), const Color(0xFFe53935)],
            icon: Icons.gps_fixed,
          );
          WerewolfNarrator.onHunterRevenge();
          break;

        case WPhase.finished:
          _triggerTransition(
            label: 'GAME SELESAI',
            colors: [const Color(0xFF1A1A2E), const Color(0xFF6B21A8)],
            icon: Icons.flag,
          );
          // Narasi menang/kalah dihandle di _buildFinished saat pertama kali muncul
          break;
      }
    }

    // Narasi log baru (khusus malam — serangan wolf)
    if (newLogEntry && newPhase == WPhase.night) {
      if (latestLog.contains('menyerang') || latestLog.contains('memilih korban')) {
        WerewolfNarrator.onWolfAttack();
      }
      _lastLog = latestLog;
    } else if (newLogEntry) {
      _lastLog = latestLog;
    }
  }

  void _triggerTransition({
    required String label,
    required List<Color> colors,
    required IconData icon,
  }) {
    if (!mounted) return;
    setState(() {
      _transitionLabel = label;
      _transitionColors = colors;
      _transitionIcon = icon;
      _showTransition = true;
    });
    _transitionCtrl.forward(from: 0);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _transitionCtrl.reverse().then((_) {
          if (mounted) setState(() => _showTransition = false);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: widget.service.roomStream(widget.roomCode),
      builder: (ctx, snap) {
        if (!snap.hasData || !snap.data!.exists) return _roomGone();

        final data = snap.data!.data() as Map<String, dynamic>;
        final phase = data['phase'] as String? ?? WPhase.waiting;
        final players = List<Map<String, dynamic>>.from(data['players'] ?? []);
        final me = players.firstWhere((p) => p['uid'] == widget.myUid, orElse: () => {});
        final isHost = me['isHost'] == true;
        final myRole = me['role'] as String? ?? '';
        final amAlive = me['isAlive'] ?? true;
        final round = data['round'] as int? ?? 0;
        final gameLog = List<String>.from(data['gameLog'] ?? []);

        // Trigger TTS & transisi saat fase berubah
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handlePhaseChange(phase, round, gameLog);

          // Narasi khusus game selesai (hanya sekali)
          if (phase == WPhase.finished && _lastPhase != WPhase.finished) {
            final winner = data['winner'] as String? ?? '';
            if (winner == 'village') {
              WerewolfNarrator.onVillageWin();
            } else {
              WerewolfNarrator.onWolfWin();
            }
          }

          // Narasi game start
          if (phase == WPhase.night && round == 1 && _lastRound == 0) {
            WerewolfNarrator.onGameStart();
          }
        });

        if (phase == WPhase.night && _actionDone) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _actionDone = false);
          });
        }

        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: _buildAppBar(phase, round, isHost, players, data),
          body: Stack(
            children: [
              Column(children: [
                _buildPhaseBanner(phase, round),
                if (myRole.isNotEmpty && phase != WPhase.waiting)
                  _buildMyRoleCard(myRole, amAlive, data),
                Expanded(child: _buildPhaseContent(
                    phase, players, me, myRole, amAlive, isHost, data, gameLog)),
                if (gameLog.isNotEmpty && phase != WPhase.waiting)
                  _buildLogStrip(gameLog),
              ]),

              // ── Transisi overlay ──────────────────────────────
              if (_showTransition)
                FadeTransition(
                  opacity: _transitionAnim,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.85),
                    child: Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: _transitionColors),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(
                              color: _transitionColors.last.withValues(alpha: 0.5),
                              blurRadius: 32, spreadRadius: 8,
                            )],
                          ),
                          child: Icon(_transitionIcon, color: Colors.white, size: 50),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _transitionLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 60, height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: _transitionColors),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  AppBar _buildAppBar(String phase, int round, bool isHost,
      List<Map<String, dynamic>> players, Map<String, dynamic> data) {
    return AppBar(
      backgroundColor: AppColors.bg,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.exit_to_app, color: Colors.deepPurple.shade300, size: 26),
        onPressed: _confirmLeave,
      ),
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ROOM: ${widget.roomCode}',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900,
                color: Colors.deepPurple.shade300, letterSpacing: 2)),
        Text('${players.where((p) => p['isAlive'] == true).length} hidup  •  ${players.length} total',
            style: TextStyle(fontSize: 10, color: AppColors.textDim)),
      ]),
      actions: [
        if (isHost && phase == WPhase.nightResult)
          TextButton.icon(
            onPressed: () => widget.service.advanceToDay(widget.roomCode),
            icon: Icon(Icons.wb_sunny, color: Colors.amber.shade400, size: 14),
            label: Text('SIANG', style: TextStyle(
                color: Colors.amber.shade400, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        if (isHost && phase == WPhase.day)
          TextButton.icon(
            onPressed: () => widget.service.startVoting(widget.roomCode),
            icon: Icon(Icons.how_to_vote, color: Colors.orange.shade400, size: 14),
            label: Text('VOTING', style: TextStyle(
                color: Colors.orange.shade400, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        if (isHost && phase == WPhase.voteResult)
          TextButton.icon(
            onPressed: () => widget.service.advanceToNight(widget.roomCode),
            icon: Icon(Icons.nightlight_round, color: Colors.indigo.shade300, size: 14),
            label: Text('MALAM', style: TextStyle(
                color: Colors.indigo.shade300, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
      ],
    );
  }

  // ── Phase Banner ──────────────────────────────────────────────────────────

  Widget _buildPhaseBanner(String phase, int round) {
    final cfg = _phaseConfig(phase, round);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: cfg['colors'] as List<Color>),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(cfg['icon'] as IconData, color: Colors.white70, size: 14),
        const SizedBox(width: 8),
        Text(cfg['label'] as String,
            style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 13)),
      ]),
    );
  }

  Map<String, dynamic> _phaseConfig(String phase, int round) {
    switch (phase) {
      case WPhase.waiting:
        return {'label': 'Menunggu pemain...', 'icon': Icons.hourglass_empty,
          'colors': [const Color(0xFF1A1A2E), const Color(0xFF4A1942)]};
      case WPhase.night:
        return {'label': 'MALAM KE-$round — Lakukan aksi malammu!', 'icon': Icons.nightlight_round,
          'colors': [const Color(0xFF0F0C29), const Color(0xFF302B63)]};
      case WPhase.nightResult:
        return {'label': 'Fajar tiba — Lihat hasilnya...', 'icon': Icons.wb_twilight,
          'colors': [const Color(0xFF373B44), const Color(0xFF4286f4)]};
      case WPhase.day:
        return {'label': 'HARI KE-$round — Diskusi & temukan Werewolf!', 'icon': Icons.wb_sunny,
          'colors': [const Color(0xFFf7971e), const Color(0xFFffd200)]};
      case WPhase.voting:
        return {'label': 'VOTING — Pilih siapa yang paling mencurigakan!', 'icon': Icons.how_to_vote,
          'colors': [const Color(0xFFe53935), const Color(0xFFe35d5b)]};
      case WPhase.voteResult:
        return {'label': 'Hasil voting telah ditentukan', 'icon': Icons.balance,
          'colors': [const Color(0xFF4A00E0), const Color(0xFF8E2DE2)]};
      case WPhase.hunterRevenge:
        return {'label': 'Hunter memilih target balas dendam!', 'icon': Icons.gps_fixed,
          'colors': [const Color(0xFFf7971e), const Color(0xFFe53935)]};
      case WPhase.finished:
        return {'label': 'GAME SELESAI', 'icon': Icons.flag,
          'colors': [const Color(0xFF1A1A2E), const Color(0xFF6B21A8)]};
      default:
        return {'label': phase, 'icon': Icons.info_outline,
          'colors': [AppColors.card, AppColors.card]};
    }
  }

  // ── My Role Card ──────────────────────────────────────────────────────────

  Widget _buildMyRoleCard(String role, bool amAlive, Map<String, dynamic> data) {
    final seerResult = Map<String, dynamic>.from(data['seerResult'] as Map? ?? {});
    final mySeerResult = seerResult[widget.myUid];

    return GestureDetector(
      onTap: () => setState(() => _roleRevealed = !_roleRevealed),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: amAlive
              ? _roleColor(role).withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: amAlive ? _roleColor(role).withValues(alpha: 0.3) : AppColors.border),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _roleRevealed
                  ? _roleColor(role).withValues(alpha: 0.2)
                  : AppColors.border,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _roleRevealed ? _roleIconData(role) : Icons.help_outline,
              color: _roleRevealed ? _roleColor(role) : AppColors.textDim,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_roleRevealed ? WRole.label(role) : 'Tap untuk reveal role',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold,
                    color: amAlive ? _roleColor(role) : AppColors.textDim)),
            if (!amAlive)
              Text('Kamu sudah gugur', style: TextStyle(fontSize: 10, color: AppColors.textDim)),
          ])),
          if (mySeerResult != null && role == WRole.seer)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: (mySeerResult['isWolf'] as bool)
                      ? Colors.red.withValues(alpha: 0.2)
                      : Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  (mySeerResult['isWolf'] as bool) ? Icons.pets : Icons.check_circle_outline,
                  size: 12,
                  color: (mySeerResult['isWolf'] as bool) ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 4),
                Text(
                  (mySeerResult['isWolf'] as bool) ? 'SERIGALA!' : 'Bukan Serigala',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold,
                      color: (mySeerResult['isWolf'] as bool) ? Colors.red : Colors.green),
                ),
              ]),
            ),
        ]),
      ),
    );
  }

  // ── Phase Content ─────────────────────────────────────────────────────────

  Widget _buildPhaseContent(String phase, List<Map<String, dynamic>> players,
      Map<String, dynamic> me, String myRole, bool amAlive, bool isHost,
      Map<String, dynamic> data, List<String> gameLog) {
    switch (phase) {
      case WPhase.waiting:   return _buildWaiting(players, isHost);
      case WPhase.night:     return _buildNight(players, me, myRole, amAlive, data);
      case WPhase.nightResult: return _buildNightResult(gameLog, isHost);
      case WPhase.day:       return _buildDay(players, me, isHost, data);
      case WPhase.voting:    return _buildVoting(players, me, myRole, amAlive, data);
      case WPhase.voteResult: return _buildVoteResult(gameLog, players, isHost, data);
      case WPhase.hunterRevenge: return _buildHunterRevenge(players, me, myRole, amAlive, data);
      case WPhase.finished:  return _buildFinished(data, players, isHost);
      default:               return const SizedBox.shrink();
    }
  }

  // ── Waiting ───────────────────────────────────────────────────────────────

  Widget _buildWaiting(List<Map<String, dynamic>> players, bool isHost) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('DISTRIBUSI ROLE (${players.length} pemain)',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
                  letterSpacing: 2, color: AppColors.textDim)),
          const SizedBox(height: 10),
          _buildRolePreviewWidgets(players.length),
        ]),
      ),
      const SizedBox(height: 16),
      Text('PEMAIN (${players.length}/12)',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
              letterSpacing: 2, color: AppColors.textDim)),
      const SizedBox(height: 10),
      ...players.map((p) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border)),
        child: Row(children: [
          _avatar(p['name'] ?? ''),
          const SizedBox(width: 12),
          Expanded(child: Text(p['name'] ?? '',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                  color: AppColors.textMain))),
          if (p['uid'] == widget.myUid) _badge('KAMU', AppColors.primary.withValues(alpha: 0.15), AppColors.accent),
          if (p['isHost'] == true) ...[
            const SizedBox(width: 6),
            _badge('HOST', Colors.orange.withValues(alpha: 0.15), Colors.orange.shade600),
          ],
        ]),
      )),
      const SizedBox(height: 16),
      if (isHost)
        GestureDetector(
          onTap: players.length >= 4
              ? () => widget.service.startGame(widget.roomCode)
              : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: players.length >= 4
                  ? const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF6B21A8)])
                  : null,
              color: players.length < 4 ? AppColors.border : null,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              players.length < 4 ? 'Butuh minimal 4 pemain...' : 'MULAI GAME',
              style: TextStyle(
                  color: players.length >= 4 ? Colors.white : AppColors.textDim,
                  fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
          ),
        )
      else
        _waitingHost(),
    ]);
  }

  Widget _buildRolePreviewWidgets(int count) {
    if (count < 4) {
      return Text('Butuh minimal 4 pemain',
          style: TextStyle(fontSize: 12, color: AppColors.textDim));
    }
    final roles = assignRoles(count);
    final tally = <String, int>{};
    for (final r in roles) {
      tally[r] = (tally[r] ?? 0) + 1;
    }
    return Wrap(spacing: 8, runSpacing: 8, children: tally.entries.map((e) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_roleIconData(e.key), size: 12, color: _roleColor(e.key)),
        const SizedBox(width: 4),
        Text('${WRole.label(e.key)} ×${e.value}',
            style: TextStyle(fontSize: 11, color: AppColors.textDim)),
      ],
    )).toList());
  }

  // ── Night ─────────────────────────────────────────────────────────────────

  Widget _buildNight(List<Map<String, dynamic>> players,
      Map<String, dynamic> me, String myRole, bool amAlive,
      Map<String, dynamic> data) {
    final alivePlayers = players.where((p) => p['isAlive'] == true && p['uid'] != widget.myUid).toList();
    final round = data['round'] as int? ?? 1;

    if (!amAlive) return _deadPlayerView('Kamu sudah gugur. Tunggu siang...');
    if (_actionDone) return _waitingActionDone();

    Widget actionArea;

    switch (myRole) {
      case WRole.werewolf:
      case WRole.alphaWolf:
      case WRole.lycan:
        final wolves = players.where((p) => WRole.isWolf(p['role']) && p['isAlive'] == true).toList();
        actionArea = _buildNightActionPanel(
          titleIcon: Icons.pets,
          titleColor: Colors.red.shade400,
          title: 'Pilih korban malam ini',
          subtitle: 'Tim serigala: ${wolves.map((w) => w['name']).join(', ')}',
          players: alivePlayers.where((p) => !WRole.isWolf(p['role'])).toList(),
          onSelect: (uid) async {
            setState(() => _actionDone = true);
            await widget.service.wolfVote(widget.roomCode, uid);
          },
          canSkip: false,
        );
        break;

      case WRole.seer:
        actionArea = _buildNightActionPanel(
          titleIcon: Icons.visibility,
          titleColor: Colors.purple.shade300,
          title: 'Lihat role seseorang',
          subtitle: 'Pilih 1 pemain untuk mengetahui rolnya',
          players: alivePlayers,
          onSelect: (uid) async {
            setState(() => _actionDone = true);
            await widget.service.seerCheck(widget.roomCode, uid);
          },
          canSkip: false,
        );
        break;

      case WRole.doctor:
        final allAlive = players.where((p) => p['isAlive'] == true).toList();
        actionArea = _buildNightActionPanel(
          titleIcon: Icons.medical_services,
          titleColor: Colors.green.shade400,
          title: 'Lindungi seseorang malam ini',
          subtitle: 'Termasuk dirimu sendiri',
          players: allAlive,
          onSelect: (uid) async {
            setState(() => _actionDone = true);
            await widget.service.doctorSave(widget.roomCode, uid);
          },
          canSkip: false,
        );
        break;

      case WRole.bodyguard:
        final allAlive = players.where((p) => p['isAlive'] == true).toList();
        actionArea = _buildNightActionPanel(
          titleIcon: Icons.shield,
          titleColor: Colors.blue.shade400,
          title: 'Lindungi seseorang malam ini',
          subtitle: 'Jika diserang, kamu yang mati menggantikan',
          players: allAlive,
          onSelect: (uid) async {
            setState(() => _actionDone = true);
            await widget.service.bodyguardSave(widget.roomCode, uid);
          },
          canSkip: false,
        );
        break;

      case WRole.witch:
        actionArea = _buildWitchPanel(alivePlayers, me, data);
        break;

      case WRole.cupid:
        if (round == 1) {
          actionArea = _buildCupidPanel(alivePlayers);
        } else {
          actionArea = _skipRolePanel(Icons.favorite, Colors.pink.shade400,
              'Cupid', 'Kamu sudah memilih pasangan di malam pertama.');
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!_actionDone) {
              setState(() => _actionDone = true);
              await widget.service.skipNightAction(widget.roomCode);
            }
          });
        }
        break;

      case WRole.hunter:
      case WRole.mayor:
      case WRole.jester:
      case WRole.villager:
      default:
        actionArea = _skipRolePanel(
          _roleIconData(myRole), _roleColor(myRole),
          WRole.label(myRole),
          'Rolemu tidak memiliki aksi malam. Tunggu siang tiba...',
        );
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!_actionDone) {
            setState(() => _actionDone = true);
            await widget.service.skipNightAction(widget.roomCode);
          }
        });
        break;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: actionArea,
    );
  }

  Widget _buildNightActionPanel({
    required IconData titleIcon,
    required Color titleColor,
    required String title,
    required String subtitle,
    required List<Map<String, dynamic>> players,
    required Function(String uid) onSelect,
    required bool canSkip,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: const Color(0xFF0F0C29),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: titleColor.withValues(alpha: 0.4))),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: titleColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(titleIcon, color: titleColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white,
                fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ])),
        ]),
      ),
      const SizedBox(height: 16),
      ...players.map((p) => GestureDetector(
        onTap: () => onSelect(p['uid'] as String),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: titleColor.withValues(alpha: 0.2))),
          child: Row(children: [
            _avatar(p['name'] ?? ''),
            const SizedBox(width: 12),
            Expanded(child: Text(p['name'] ?? '',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                    color: AppColors.textMain))),
            Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textDim),
          ]),
        ),
      )),
      if (canSkip) ...[
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            setState(() => _actionDone = true);
            await widget.service.skipNightAction(widget.roomCode);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border)),
            child: Text('Lewati', style: TextStyle(color: AppColors.textDim)),
          ),
        ),
      ],
    ]);
  }

  Widget _buildWitchPanel(List<Map<String, dynamic>> alivePlayers,
      Map<String, dynamic> me, Map<String, dynamic> data) {
    final healUsed = me['witchHealUsed'] == true;
    final poisonUsed = me['witchPoisonUsed'] == true;
    final wolfTarget = data['wolfTarget'] as String? ?? '';
    final targetPlayer = wolfTarget.isNotEmpty
        ? alivePlayers.firstWhere((p) => p['uid'] == wolfTarget, orElse: () => {})
        : null;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: const Color(0xFF0F0C29),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.teal.withValues(alpha: 0.4))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.science, color: Colors.teal.shade300, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Kemampuan Witch',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _potionBadge(Icons.healing, 'Ramuan Sembuh', !healUsed, Colors.green),
            const SizedBox(width: 8),
            _potionBadge(Icons.dangerous, 'Racun', !poisonUsed, Colors.red),
          ]),
        ]),
      ),
      const SizedBox(height: 16),

      if (!healUsed && targetPlayer != null && targetPlayer.isNotEmpty) ...[
        Row(children: [
          Icon(Icons.my_location, size: 13, color: AppColors.textDim),
          const SizedBox(width: 6),
          Text('Korban werewolf malam ini: ${targetPlayer['name']}',
              style: TextStyle(color: AppColors.textDim, fontSize: 13)),
        ]),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            setState(() => _actionDone = true);
            await widget.service.witchAction(widget.roomCode, heal: true);
          },
          child: _witchActionBtn(Icons.healing, 'Selamatkan ${targetPlayer['name']}', Colors.green),
        ),
        const SizedBox(height: 12),
      ],

      if (!poisonUsed) ...[
        Row(children: [
          Icon(Icons.dangerous, size: 13, color: AppColors.textDim),
          const SizedBox(width: 6),
          Text('Pilih target racun:', style: TextStyle(color: AppColors.textDim, fontSize: 13)),
        ]),
        const SizedBox(height: 8),
        ...alivePlayers.map((p) => GestureDetector(
          onTap: () async {
            setState(() => _actionDone = true);
            await widget.service.witchAction(widget.roomCode, poisonTarget: p['uid'] as String);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3))),
            child: Row(children: [
              _avatar(p['name'] ?? ''),
              const SizedBox(width: 12),
              Expanded(child: Text(p['name'] ?? '',
                  style: TextStyle(fontSize: 14, color: AppColors.textMain))),
              Icon(Icons.dangerous, color: Colors.red.shade400, size: 20),
            ]),
          ),
        )),
        const SizedBox(height: 8),
      ],

      GestureDetector(
        onTap: () async {
          setState(() => _actionDone = true);
          await widget.service.witchAction(widget.roomCode);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border)),
          child: Text('Tidak menggunakan kemampuan malam ini',
              style: TextStyle(color: AppColors.textDim, fontSize: 12)),
        ),
      ),
    ]);
  }

  Widget _potionBadge(IconData icon, String label, bool available, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
        color: available ? color.withValues(alpha: 0.12) : AppColors.border,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: available ? color.withValues(alpha: 0.3) : Colors.transparent)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: available ? color : AppColors.textDim),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.bold,
          color: available ? color : AppColors.textDim)),
    ]),
  );

  Widget _witchActionBtn(IconData icon, String label, Color color) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 14),
    alignment: Alignment.center,
    decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4))),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
    ]),
  );

  String? _cupidFirst;
  Widget _buildCupidPanel(List<Map<String, dynamic>> alivePlayers) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: const Color(0xFF0F0C29),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.pink.withValues(alpha: 0.4))),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.pink.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.favorite, color: Colors.pink.shade300, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Pilih Pasangan Kekasih',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(_cupidFirst == null
                ? 'Pilih pemain pertama (1/2)'
                : 'Pilih pemain kedua (2/2)',
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ])),
        ]),
      ),
      const SizedBox(height: 16),
      ...alivePlayers.map((p) {
        final isSelected = _cupidFirst == p['uid'];
        return GestureDetector(
          onTap: () async {
            if (_cupidFirst == null) {
              setState(() => _cupidFirst = p['uid'] as String);
            } else if (_cupidFirst != p['uid']) {
              setState(() => _actionDone = true);
              await widget.service.cupidChooseLovers(
                  widget.roomCode, _cupidFirst!, p['uid'] as String);
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: isSelected ? Colors.pink.withValues(alpha: 0.15) : AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: isSelected ? Colors.pink.withValues(alpha: 0.5) : AppColors.border)),
            child: Row(children: [
              _avatar(p['name'] ?? ''),
              const SizedBox(width: 12),
              Expanded(child: Text(p['name'] ?? '',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                      color: AppColors.textMain))),
              if (isSelected) Icon(Icons.favorite, color: Colors.pink.shade400, size: 20),
            ]),
          ),
        );
      }),
    ]);
  }

  Widget _skipRolePanel(IconData icon, Color color, String title, String message) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: const Color(0xFF0F0C29),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
    child: Column(children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 28),
      ),
      const SizedBox(height: 10),
      Text(title, style: const TextStyle(color: Colors.white,
          fontSize: 15, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      Text(message, textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.5)),
      const SizedBox(height: 16),
      const SizedBox(width: 20, height: 20,
          child: CircularProgressIndicator(color: Colors.white38, strokeWidth: 2)),
    ]),
  );

  Widget _waitingActionDone() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15), shape: BoxShape.circle),
          child: const Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
        ),
        const SizedBox(height: 16),
        Text('Aksi malam selesai!',
            style: TextStyle(color: AppColors.textMain, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Menunggu pemain lain...', style: TextStyle(color: AppColors.textDim)),
      ]),
    ),
  );

  // ── Night Result ──────────────────────────────────────────────────────────

  Widget _buildNightResult(List<String> gameLog, bool isHost) {
    final nightLogs = gameLog.where((l) => l.startsWith('MALAM:') || l.startsWith('MULAI:')).toList();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: const Icon(Icons.wb_twilight, color: Colors.amber, size: 44),
          ),
          const SizedBox(height: 16),
          Text('Fajar Tiba', style: TextStyle(
              color: AppColors.textMain, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
          ...nightLogs.map((l) => _logEntry(l)),
          if (isHost) ...[
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => widget.service.advanceToDay(widget.roomCode),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFf7971e), Color(0xFFffd200)]),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.wb_sunny, color: Colors.black87, size: 16),
                  const SizedBox(width: 8),
                  const Text('MULAI SIANG',
                      style: TextStyle(color: Colors.black87,
                          fontWeight: FontWeight.w900, letterSpacing: 1)),
                ]),
              ),
            ),
          ] else
            Text('Menunggu host...', style: TextStyle(color: AppColors.textDim)),
        ]),
      ),
    );
  }

  // ── Day ───────────────────────────────────────────────────────────────────

  Widget _buildDay(List<Map<String, dynamic>> players, Map<String, dynamic> me,
      bool isHost, Map<String, dynamic> data) {
    final alivePlayers = players.where((p) => p['isAlive'] == true).toList();
    return ListView(padding: const EdgeInsets.all(20), children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.3))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.wb_sunny, color: Colors.amber.shade400, size: 18),
          const SizedBox(width: 10),
          const Expanded(child: Text(
            'Diskusikan bersama siapa yang paling mencurigakan. '
            'Gunakan informasi dari semalam untuk mengungkap Werewolf!',
            style: TextStyle(color: Colors.amber, fontSize: 13, height: 1.5),
          )),
        ]),
      ),
      const SizedBox(height: 16),
      Text('PEMAIN MASIH HIDUP (${alivePlayers.length})',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
              letterSpacing: 2, color: AppColors.textDim)),
      const SizedBox(height: 10),
      ...alivePlayers.map((p) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border)),
        child: Row(children: [
          _avatar(p['name'] ?? ''),
          const SizedBox(width: 12),
          Expanded(child: Text(p['name'] ?? '',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                  color: AppColors.textMain))),
          if (p['uid'] == widget.myUid)
            _badge('KAMU', AppColors.primary.withValues(alpha: 0.15), AppColors.accent),
          if (p['isLovers'] == true)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Icon(Icons.favorite, color: Colors.pink.shade400, size: 14),
            ),
        ]),
      )),
      const SizedBox(height: 16),
      if (isHost)
        GestureDetector(
          onTap: () => widget.service.startVoting(widget.roomCode),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFe53935), Color(0xFFe35d5b)]),
                borderRadius: BorderRadius.circular(16)),
            alignment: Alignment.center,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.how_to_vote, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              const Text('MULAI VOTING',
                  style: TextStyle(color: Colors.white,
                      fontWeight: FontWeight.bold, letterSpacing: 2)),
            ]),
          ),
        )
      else
        _waitingHost(),
    ]);
  }

  // ── Voting ────────────────────────────────────────────────────────────────

  Widget _buildVoting(List<Map<String, dynamic>> players, Map<String, dynamic> me,
      String myRole, bool amAlive, Map<String, dynamic> data) {
    final alivePlayers = players.where((p) => p['isAlive'] == true).toList();
    final votes = Map<String, dynamic>.from(data['votes'] as Map? ?? {});
    final myVote = votes[widget.myUid] as String?;
    final hasVoted = myVote != null;

    if (!amAlive) return _deadPlayerView('Kamu sudah gugur. Tidak bisa vote.');

    return ListView(padding: const EdgeInsets.all(20), children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withValues(alpha: 0.3))),
        child: Row(children: [
          Icon(Icons.how_to_vote, color: Colors.red.shade400, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(
            hasVoted
                ? 'Kamu sudah vote. Menunggu yang lain... (${votes.length}/${alivePlayers.length})'
                : 'Pilih 1 pemain yang paling mencurigakan!',
            style: TextStyle(
                color: hasVoted ? AppColors.textDim : Colors.red.shade300, fontSize: 13),
          )),
        ]),
      ),
      const SizedBox(height: 16),
      ...alivePlayers.where((p) => p['uid'] != widget.myUid).map((p) {
        final voteCount = votes.values.where((v) => v == p['uid']).length;
        final isMyTarget = myVote == p['uid'];
        return GestureDetector(
          onTap: hasVoted ? null : () => widget.service.castVote(widget.roomCode, p['uid'] as String),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: isMyTarget ? Colors.red.withValues(alpha: 0.1) : AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: isMyTarget ? Colors.red.withValues(alpha: 0.5) : AppColors.border,
                    width: isMyTarget ? 1.5 : 1)),
            child: Row(children: [
              _avatar(p['name'] ?? ''),
              const SizedBox(width: 12),
              Expanded(child: Text(p['name'] ?? '',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                      color: AppColors.textMain))),
              if (voteCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.how_to_vote, size: 11, color: Colors.red.shade400),
                    const SizedBox(width: 4),
                    Text('$voteCount',
                        style: const TextStyle(color: Colors.red,
                            fontWeight: FontWeight.bold, fontSize: 12)),
                  ]),
                ),
              if (isMyTarget) ...[
                const SizedBox(width: 6),
                Icon(Icons.check_circle, color: Colors.red.shade400, size: 18),
              ],
            ]),
          ),
        );
      }),
    ]);
  }

  // ── Vote Result ───────────────────────────────────────────────────────────

  Widget _buildVoteResult(List<String> gameLog, List<Map<String, dynamic>> players,
      bool isHost, Map<String, dynamic> data) {
    final voteLogs = gameLog.where((l) => l.startsWith('VOTING:')).toList();
    final deadPlayers = players.where((p) => p['isAlive'] == false).toList();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: const Icon(Icons.balance, color: Colors.deepPurple, size: 44),
          ),
          const SizedBox(height: 16),
          Text('Hasil Voting', style: TextStyle(
              color: AppColors.textMain, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          ...voteLogs.map((l) => _logEntry(l)),
          if (deadPlayers.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Sudah gugur:', style: TextStyle(
                color: AppColors.textDim, fontSize: 11, letterSpacing: 1)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: deadPlayers.map((p) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.border,
                  borderRadius: BorderRadius.circular(20)),
              child: Text('${p['name']} (${WRole.label(p['role'])})',
                  style: TextStyle(fontSize: 11, color: AppColors.textDim,
                      decoration: TextDecoration.lineThrough)),
            )).toList()),
          ],
          if (isHost) ...[
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => widget.service.advanceToNight(widget.roomCode),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF0F0C29), Color(0xFF302B63)]),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.nightlight_round, color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  const Text('LANJUT KE MALAM',
                      style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.bold, letterSpacing: 1)),
                ]),
              ),
            ),
          ] else
            Text('Menunggu host...', style: TextStyle(color: AppColors.textDim)),
        ]),
      ),
    );
  }

  // ── Hunter Revenge ────────────────────────────────────────────────────────

  Widget _buildHunterRevenge(List<Map<String, dynamic>> players,
      Map<String, dynamic> me, String myRole, bool amAlive,
      Map<String, dynamic> data) {
    final pendingHunter = data['pendingHunterRevenge'] as String? ?? '';
    final isHunter = widget.myUid == pendingHunter;
    final alivePlayers = players.where((p) => p['isAlive'] == true && p['uid'] != widget.myUid).toList();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(Icons.gps_fixed, color: Colors.orange.shade400, size: 44),
          ),
          const SizedBox(height: 16),
          Text('Hunter Balas Dendam!', style: TextStyle(
              color: AppColors.textMain, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(isHunter
              ? 'Kamu adalah Hunter! Pilih 1 pemain untuk kamu tembak.'
              : 'Hunter sedang memilih target balas dendam...',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textDim, fontSize: 13)),
          if (isHunter) ...[
            const SizedBox(height: 20),
            ...alivePlayers.map((p) => GestureDetector(
              onTap: () => widget.service.hunterShoot(widget.roomCode, p['uid'] as String),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3))),
                child: Row(children: [
                  _avatar(p['name'] ?? ''),
                  const SizedBox(width: 12),
                  Expanded(child: Text(p['name'] ?? '',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                          color: AppColors.textMain))),
                  Icon(Icons.gps_fixed, color: Colors.orange.shade400, size: 20),
                ]),
              ),
            )),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
        ]),
      ),
    );
  }

  // ── Finished ──────────────────────────────────────────────────────────────

  Widget _buildFinished(Map<String, dynamic> data, List<Map<String, dynamic>> players, bool isHost) {
    final winner = data['winner'] as String? ?? '';
    final isVillageWin = winner == 'village';
    final gameLog = List<String>.from(data['gameLog'] as List? ?? []);

    return ListView(padding: const EdgeInsets.all(24), children: [
      Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: isVillageWin
              ? [const Color(0xFF134E5E), const Color(0xFF71B280)]
              : [const Color(0xFF7C0000), const Color(0xFFDC2626)]),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(
              color: (isVillageWin ? Colors.green : Colors.red).withValues(alpha: 0.3),
              blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Icon(isVillageWin ? Icons.home : Icons.pets,
                color: Colors.white, size: 44),
          ),
          const SizedBox(height: 12),
          Text(isVillageWin ? 'DESA MENANG!' : 'WEREWOLF MENANG!',
              style: const TextStyle(color: Colors.white, fontSize: 24,
                  fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 8),
          Text(isVillageWin ? 'Semua werewolf telah dibasmi!' : 'Werewolf menguasai desa!',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 20),
          if (isHost)
            GestureDetector(
              onTap: () => widget.service.restartGame(widget.roomCode),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.replay, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('MAIN LAGI', style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
                ]),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 20),
      Text('ROLE SEMUA PEMAIN', style: TextStyle(fontSize: 10,
          fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.textDim)),
      const SizedBox(height: 10),
      ...players.map((p) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border)),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: _roleColor(p['role'] ?? '').withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(_roleIconData(p['role'] ?? ''),
                color: _roleColor(p['role'] ?? ''), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(p['name'] ?? '', style: TextStyle(fontSize: 14,
                  fontWeight: FontWeight.w600, color: AppColors.textMain,
                  decoration: p['isAlive'] != true ? TextDecoration.lineThrough : null)),
              if (p['uid'] == widget.myUid) ...[
                const SizedBox(width: 6),
                _badge('KAMU', AppColors.primary.withValues(alpha: 0.15), AppColors.accent),
              ],
            ]),
            Text(WRole.label(p['role'] ?? ''),
                style: TextStyle(fontSize: 11, color: _roleColor(p['role'] ?? ''))),
          ])),
          Icon(p['isAlive'] == true ? Icons.favorite : Icons.heart_broken,
              color: p['isAlive'] == true ? Colors.green : Colors.red, size: 16),
        ]),
      )),
      const SizedBox(height: 20),
      Text('LOG PERMAINAN', style: TextStyle(fontSize: 10,
          fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.textDim)),
      const SizedBox(height: 10),
      ...gameLog.reversed.take(15).map((l) => _logEntry(l)),
    ]);
  }

  // ── Log Strip ─────────────────────────────────────────────────────────────

  Widget _buildLogStrip(List<String> gameLog) {
    final latest = gameLog.last;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Container(
        key: ValueKey(latest),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: AppColors.card,
        child: Row(children: [
          Icon(_logIconData(latest), size: 14, color: _logColor(latest)),
          const SizedBox(width: 8),
          Expanded(child: Text(
            latest.replaceAll(RegExp(r'^[A-Z_]+: ?'), ''),
            style: TextStyle(fontSize: 12, color: AppColors.textDim),
            maxLines: 2, overflow: TextOverflow.ellipsis,
          )),
        ]),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _logEntry(String text) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
        color: AppColors.card, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _logColor(text).withValues(alpha: 0.25))),
    child: Row(children: [
      Icon(_logIconData(text), size: 14, color: _logColor(text)),
      const SizedBox(width: 8),
      Expanded(child: Text(
        text.replaceAll(RegExp(r'^[A-Z_]+: ?'), ''),
        style: TextStyle(fontSize: 12, color: AppColors.textDim, height: 1.4),
      )),
    ]),
  );

  IconData _logIconData(String text) {
    if (text.startsWith('MALAM:')) return Icons.nightlight_round;
    if (text.startsWith('SIANG:')) return Icons.wb_sunny;
    if (text.startsWith('VOTING:')) return Icons.how_to_vote;
    if (text.startsWith('MENANG:')) return Icons.emoji_events;
    if (text.startsWith('HUNTER:')) return Icons.gps_fixed;
    if (text.startsWith('RESTART:')) return Icons.replay;
    if (text.startsWith('MULAI:')) return Icons.play_circle_outline;
    return Icons.info_outline;
  }

  Color _logColor(String text) {
    if (text.startsWith('MENANG:')) return Colors.amber;
    if (text.startsWith('MALAM:')) return Colors.indigo.shade300;
    if (text.startsWith('SIANG:')) return Colors.orange;
    if (text.startsWith('VOTING:')) return Colors.red;
    if (text.startsWith('HUNTER:')) return Colors.orange.shade400;
    return AppColors.textDim;
  }

  Widget _deadPlayerView(String msg) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.person_off, color: Colors.grey, size: 44),
        ),
        const SizedBox(height: 16),
        Text(msg, textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textDim, fontSize: 14)),
      ]),
    ),
  );

  Widget _waitingHost() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border)),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      const SizedBox(width: 16, height: 16,
          child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
      const SizedBox(width: 12),
      Text('Menunggu host...', style: TextStyle(color: AppColors.textDim, fontSize: 13)),
    ]),
  );

  Widget _roomGone() => Scaffold(
    backgroundColor: AppColors.bg,
    body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.meeting_room_outlined, size: 56, color: Colors.white24),
      const SizedBox(height: 16),
      Text('Room tidak ditemukan atau sudah ditutup.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textDim)),
      const SizedBox(height: 16),
      TextButton(onPressed: widget.onLeave,
          child: Text('Kembali', style: TextStyle(color: AppColors.accent))),
    ])),
  );

  void _confirmLeave() {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Keluar Room', style: TextStyle(fontWeight: FontWeight.w900)),
      content: Text('Yakin ingin keluar?', style: TextStyle(color: AppColors.textDim)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: AppColors.textDim))),
        TextButton(
          onPressed: () { Navigator.pop(context); widget.onLeave(); },
          child: const Text('Keluar',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ),
      ],
    ));
  }

  Widget _avatar(String name) => Container(
    width: 36, height: 36,
    decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6B21A8), Color(0xFFD946EF)]),
        borderRadius: BorderRadius.circular(10)),
    child: Center(child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
    )),
  );

  Widget _badge(String label, Color bg, Color textColor) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
    child: Text(label, style: TextStyle(fontSize: 8,
        fontWeight: FontWeight.bold, color: textColor)),
  );

  Color _roleColor(String role) {
    if (WRole.isWolf(role)) return Colors.red.shade400;
    if (role == WRole.seer) return Colors.purple.shade300;
    if (role == WRole.doctor) return Colors.green.shade400;
    if (role == WRole.hunter) return Colors.orange.shade400;
    if (role == WRole.witch) return Colors.teal.shade300;
    if (role == WRole.bodyguard) return Colors.blue.shade400;
    if (role == WRole.mayor) return Colors.amber.shade400;
    if (role == WRole.cupid) return Colors.pink.shade400;
    if (role == WRole.jester) return Colors.lime.shade400;
    return AppColors.textDim;
  }
}