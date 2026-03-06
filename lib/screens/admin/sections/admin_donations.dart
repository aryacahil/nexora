import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../../core/colors.dart';
import '../../../services/admin_service.dart';

class AdminDonations extends StatelessWidget {
  const AdminDonations({super.key});

  @override
  Widget build(BuildContext context) {
    final adminService = AdminService();

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
          'Kelola Donasi',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.primary),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showFormDialog(context, adminService),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('donations')
            .orderBy('createdAt', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.volunteer_activism_outlined,
                      size: 56, color: Colors.purple.shade100),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada donasi.\nTambahkan dengan tombol +',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textDim, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final d = docs[index].data() as Map<String, dynamic>;
              final id = docs[index].id;
              final imageBase64 = d['imageBase64'] ?? '';
              final link = d['link'] ?? '';
              final noRek = d['noRek'] ?? '';
              final bank = d['bank'] ?? '';
              final atasNama = d['atasNama'] ?? '';

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.volunteer_activism,
                              color: Colors.green.shade600, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d['title'] ?? '',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textMain,
                                ),
                              ),
                              if ((d['description'] ?? '').isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  d['description'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textDim),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.edit_outlined,
                              color: AppColors.accent, size: 20),
                          onPressed: () => _showFormDialog(
                            context,
                            adminService,
                            id: id,
                            title: d['title'],
                            description: d['description'],
                            noRek: noRek,
                            bank: bank,
                            atasNama: atasNama,
                            existingImageBase64: imageBase64,
                            existingLink: link,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red, size: 20),
                          onPressed: () => _confirmDelete(
                              context, id, d['title'] ?? ''),
                        ),
                      ],
                    ),

                    // Info rekening
                    if (noRek.isNotEmpty || bank.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            if (bank.isNotEmpty)
                              _buildInfoRow(
                                  Icons.account_balance, 'Bank', bank),
                            if (noRek.isNotEmpty) ...[
                              if (bank.isNotEmpty)
                                Divider(
                                    color: Colors.green.withValues(alpha: 0.2),
                                    height: 16),
                              _buildInfoRow(
                                  Icons.credit_card, 'No. Rek', noRek),
                            ],
                            if (atasNama.isNotEmpty) ...[
                              Divider(
                                  color: Colors.green.withValues(alpha: 0.2),
                                  height: 16),
                              _buildInfoRow(
                                  Icons.person, 'Atas Nama', atasNama),
                            ],
                          ],
                        ),
                      ),
                    ],

                    // Gambar
                    if (imageBase64.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          base64Decode(imageBase64),
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],

                    // Link
                    if (link.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.link, size: 14, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              link,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.accent),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.green.shade600),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
              fontSize: 11,
              color: AppColors.textDim,
              fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
                fontSize: 11,
                color: AppColors.textMain,
                fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  void _showFormDialog(
    BuildContext context,
    AdminService adminService, {
    String? id,
    String? title,
    String? description,
    String? noRek,
    String? bank,
    String? atasNama,
    String? existingImageBase64,
    String? existingLink,
  }) {
    showDialog(
      context: context,
      builder: (_) => _DonationFormDialog(
        id: id,
        initialTitle: title,
        initialDescription: description,
        initialNoRek: noRek,
        initialBank: bank,
        initialAtasNama: atasNama,
        existingImageBase64: existingImageBase64,
        existingLink: existingLink,
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, String title) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Donasi',
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text(
          'Hapus "$title"? Data tidak bisa dikembalikan.',
          style: TextStyle(color: AppColors.textDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal',
                style: TextStyle(color: AppColors.textDim)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance
                  .collection('donations')
                  .doc(id)
                  .delete();
            },
            child: const Text('Hapus',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Form Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _DonationFormDialog extends StatefulWidget {
  final String? id;
  final String? initialTitle;
  final String? initialDescription;
  final String? initialNoRek;
  final String? initialBank;
  final String? initialAtasNama;
  final String? existingImageBase64;
  final String? existingLink;

  const _DonationFormDialog({
    this.id,
    this.initialTitle,
    this.initialDescription,
    this.initialNoRek,
    this.initialBank,
    this.initialAtasNama,
    this.existingImageBase64,
    this.existingLink,
  });

  @override
  State<_DonationFormDialog> createState() => _DonationFormDialogState();
}

class _DonationFormDialogState extends State<_DonationFormDialog> {
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _noRekCtrl;
  late TextEditingController _bankCtrl;
  late TextEditingController _atasNamaCtrl;
  late TextEditingController _linkCtrl;
  String? _currentImageBase64;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl =
        TextEditingController(text: widget.initialTitle ?? '');
    _descCtrl =
        TextEditingController(text: widget.initialDescription ?? '');
    _noRekCtrl =
        TextEditingController(text: widget.initialNoRek ?? '');
    _bankCtrl =
        TextEditingController(text: widget.initialBank ?? '');
    _atasNamaCtrl =
        TextEditingController(text: widget.initialAtasNama ?? '');
    _linkCtrl =
        TextEditingController(text: widget.existingLink ?? '');
    _currentImageBase64 = widget.existingImageBase64;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _noRekCtrl.dispose();
    _bankCtrl.dispose();
    _atasNamaCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
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
      _currentImageBase64 = base64Encode(compressed);
    });
  }

  void _removeImage() {
    setState(() => _currentImageBase64 = '');
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);

    final isEdit = widget.id != null;
    final data = {
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'noRek': _noRekCtrl.text.trim(),
      'bank': _bankCtrl.text.trim(),
      'atasNama': _atasNamaCtrl.text.trim(),
      'link': _linkCtrl.text.trim(),
      'imageBase64': _currentImageBase64 ?? '',
    };

    Navigator.pop(context);

    if (isEdit) {
      await FirebaseFirestore.instance
          .collection('donations')
          .doc(widget.id)
          .update(data);
    } else {
      await FirebaseFirestore.instance.collection('donations').add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.id != null;

    return AlertDialog(
      backgroundColor: AppColors.card,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        isEdit ? 'Edit Donasi' : 'Tambah Donasi',
        style: TextStyle(
            fontWeight: FontWeight.w900, color: AppColors.primary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildField(_titleCtrl, 'Judul donasi'),
            const SizedBox(height: 12),
            _buildField(_descCtrl, 'Deskripsi...', maxLines: 3),
            const SizedBox(height: 12),

            // Label rekening
            Text(
              'INFO REKENING',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: AppColors.textDim,
              ),
            ),
            const SizedBox(height: 8),
            _buildField(_bankCtrl, 'Nama Bank (misal: BCA, BRI...)'),
            const SizedBox(height: 8),
            _buildField(_noRekCtrl, 'Nomor Rekening'),
            const SizedBox(height: 8),
            _buildField(_atasNamaCtrl, 'Atas Nama'),
            const SizedBox(height: 12),

            _buildField(_linkCtrl, 'Link donasi (opsional)'),
            const SizedBox(height: 12),

            // Foto
            Text(
              'FOTO',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: AppColors.textDim,
              ),
            ),
            const SizedBox(height: 8),

            if (_currentImageBase64 != null &&
                _currentImageBase64!.isNotEmpty) ...[
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      base64Decode(_currentImageBase64!),
                      width: double.infinity,
                      height: 140,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: _removeImage,
                      child: Container(
                        padding: const EdgeInsets.all(4),
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
                icon:
                    Icon(Icons.image, color: AppColors.accent, size: 16),
                label: Text('Ganti Foto',
                    style:
                        TextStyle(color: AppColors.accent, fontSize: 12)),
              ),
            ] else ...[
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          color: AppColors.textDim, size: 28),
                      const SizedBox(height: 6),
                      Text('Tambah Foto (opsional)',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textDim)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child:
              Text('Batal', style: TextStyle(color: AppColors.textDim)),
        ),
        TextButton(
          onPressed: _isLoading ? null : _submit,
          child: Text(
            isEdit ? 'Simpan' : 'Tambah',
            style: TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textDim, fontSize: 13),
        filled: true,
        fillColor: AppColors.bg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.accent, width: 2),
        ),
      ),
    );
  }
}