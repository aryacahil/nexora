import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../services/feedback_service.dart';
import '../services/user_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _msgController = TextEditingController();
  final FeedbackService _feedbackService = FeedbackService();
  final UserService _userService = UserService();
  bool _isAnonymous = false;
  bool _isLoading = false;
  String _myName = '';

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  Future<void> _loadName() async {
    final profile = await _userService.getMyProfile();
    if (mounted) {
      setState(() => _myName = profile?['name'] ?? 'Anggota');
    }
  }

  Future<void> _submit() async {
    if (_msgController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await _feedbackService.sendFeedback(
        message: _msgController.text.trim(),
        senderName: _myName,
        isAnonymous: _isAnonymous,
      );
      if (mounted) {
        _msgController.clear();
        setState(() => _isAnonymous = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Saran berhasil dikirim! Terima kasih.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon:
              Icon(Icons.chevron_left, color: AppColors.accent, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Saran & Masukan',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.primary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header banner ────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.lightbulb_outline,
                        color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Suaramu Penting!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Bantu kami berkembang dengan saran dan masukan kamu.',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Label ────────────────────────────────────
            Text(
              'PESAN KAMU',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: AppColors.textDim,
              ),
            ),
            const SizedBox(height: 12),

            // ── Text field ───────────────────────────────
            TextField(
              controller: _msgController,
              maxLines: 6,
              maxLength: 500,
              decoration: InputDecoration(
                hintText:
                    'Tulis saran, masukan, atau kritik kamu di sini...',
                hintStyle:
                    TextStyle(color: AppColors.textDim, fontSize: 13),
                filled: true,
                fillColor: AppColors.card,
                contentPadding: const EdgeInsets.all(20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide:
                      BorderSide(color: AppColors.accent, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Toggle anonim ─────────────────────────────
            GestureDetector(
              onTap: () =>
                  setState(() => _isAnonymous = !_isAnonymous),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isAnonymous
                        ? AppColors.accent
                        : AppColors.border,
                    width: _isAnonymous ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isAnonymous
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _isAnonymous
                            ? Icons.visibility_off
                            : Icons.person_outline,
                        size: 18,
                        color: _isAnonymous
                            ? AppColors.primary
                            : AppColors.textDim,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kirim secara anonim',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMain,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isAnonymous
                                ? 'Namamu tidak akan ditampilkan ke admin'
                                : 'Namamu akan terlihat oleh admin',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textDim),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isAnonymous,
                      onChanged: (val) =>
                          setState(() => _isAnonymous = val),
                      activeTrackColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Tombol kirim ─────────────────────────────
            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary))
                : GestureDetector(
                    onTap: _submit,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'KIRIM SARAN',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
            const SizedBox(height: 24),

            // ── Info box ─────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.blue.shade400, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Saran kamu akan langsung diterima oleh tim admin. Kami membaca setiap masukan dengan serius.',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textDim,
                          height: 1.5),
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
}