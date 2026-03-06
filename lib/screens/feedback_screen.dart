import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
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
  String _type = 'saran'; // 'saran' atau 'laporan'
  String? _imageBase64;

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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    final compressed = await FlutterImageCompress.compressWithFile(
      picked.path,
      quality: 50,
      minWidth: 800,
      minHeight: 600,
    );
    if (compressed == null) return;

    if (compressed.length > 900000) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto terlalu besar, pilih yang lebih kecil.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _imageBase64 = base64Encode(compressed);
    });
  }

  void _removeImage() {
    setState(() => _imageBase64 = null);
  }

  Future<void> _submit() async {
    if (_msgController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await _feedbackService.sendFeedback(
        message: _msgController.text.trim(),
        senderName: _myName,
        isAnonymous: _isAnonymous,
        type: _type,
        imageBase64: _imageBase64,
      );
      if (mounted) {
        _msgController.clear();
        setState(() {
          _isAnonymous = false;
          _imageBase64 = null;
          _type = 'saran';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_type == 'laporan'
                ? 'Laporan berhasil dikirim!'
                : 'Saran berhasil dikirim! Terima kasih.'),
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
          icon: Icon(Icons.chevron_left, color: AppColors.accent, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Saran & Laporan',
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
                gradient: LinearGradient(
                  colors: _type == 'laporan'
                      ? [const Color(0xFFDC2626), const Color(0xFFB91C1C)]
                      : [const Color(0xFF7C3AED), const Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: (_type == 'laporan' ? Colors.red : Colors.purple)
                        .withValues(alpha: 0.25),
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
                    child: Icon(
                      _type == 'laporan'
                          ? Icons.report_outlined
                          : Icons.lightbulb_outline,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _type == 'laporan'
                              ? 'Laporkan Masalah!'
                              : 'Suaramu Penting!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _type == 'laporan'
                              ? 'Laporkan masalah atau pelanggaran yang terjadi.'
                              : 'Bantu kami berkembang dengan saran dan masukan kamu.',
                          style: const TextStyle(
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
            const SizedBox(height: 24),

            // ── Pilih Tipe ───────────────────────────────
            Text(
              'JENIS KIRIMAN',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: AppColors.textDim,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _type = 'saran'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _type == 'saran'
                            ? AppColors.primary
                            : AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _type == 'saran'
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 16,
                            color: _type == 'saran'
                                ? Colors.white
                                : AppColors.textDim,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Saran',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _type == 'saran'
                                  ? Colors.white
                                  : AppColors.textDim,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _type = 'laporan'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _type == 'laporan'
                            ? Colors.red.shade600
                            : AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _type == 'laporan'
                              ? Colors.red.shade600
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.report_outlined,
                            size: 16,
                            color: _type == 'laporan'
                                ? Colors.white
                                : AppColors.textDim,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Laporan',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _type == 'laporan'
                                  ? Colors.white
                                  : AppColors.textDim,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Label ────────────────────────────────────
            Text(
              _type == 'laporan' ? 'DETAIL LAPORAN' : 'PESAN KAMU',
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
                hintText: _type == 'laporan'
                    ? 'Jelaskan masalah atau pelanggaran yang terjadi...'
                    : 'Tulis saran, masukan, atau kritik kamu di sini...',
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

            // ── Foto ─────────────────────────────────────
            Text(
              'FOTO BUKTI (OPSIONAL)',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: AppColors.textDim,
              ),
            ),
            const SizedBox(height: 12),

            if (_imageBase64 != null) ...[
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      base64Decode(_imageBase64!),
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _removeImage,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _pickImage,
                icon: Icon(Icons.image, color: AppColors.accent, size: 16),
                label: Text(
                  'Ganti Foto',
                  style: TextStyle(color: AppColors.accent, fontSize: 12),
                ),
              ),
            ] else ...[
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.border,
                        style: BorderStyle.solid),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          color: AppColors.textDim, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'Tambah Foto',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textDim),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
                        gradient: LinearGradient(
                          colors: _type == 'laporan'
                              ? [
                                  Colors.red.shade600,
                                  Colors.red.shade800
                                ]
                              : [
                                  const Color(0xFF7C3AED),
                                  const Color(0xFF4F46E5)
                                ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (_type == 'laporan'
                                    ? Colors.red
                                    : Colors.purple)
                                .withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _type == 'laporan' ? 'KIRIM LAPORAN' : 'KIRIM SARAN',
                        style: const TextStyle(
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
                color: _type == 'laporan'
                    ? Colors.red.shade50
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _type == 'laporan'
                      ? Colors.red.shade100
                      : Colors.blue.shade100,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: _type == 'laporan'
                        ? Colors.red.shade400
                        : Colors.blue.shade400,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _type == 'laporan'
                          ? 'Laporan kamu akan ditangani oleh admin secara serius. Sertakan bukti foto jika ada.'
                          : 'Saran kamu akan langsung diterima oleh tim admin. Kami membaca setiap masukan dengan serius.',
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