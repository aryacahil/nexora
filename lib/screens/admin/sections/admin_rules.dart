import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../../core/colors.dart';
import '../../../services/admin_service.dart';

class AdminRules extends StatelessWidget {
  const AdminRules({super.key});

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
          'Kelola Panduan',
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
      body: StreamBuilder(
        stream: adminService.getRules(),
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
                  Icon(Icons.inbox, size: 48, color: Colors.purple.shade100),
                  const SizedBox(height: 12),
                  Text(
                    'Belum ada panduan.\nTambahkan dengan tombol +',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textDim, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          final rules = snapshot.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
            itemCount: rules.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final r = rules[index].data() as Map<String, dynamic>;
              final id = rules[index].id;
              final imageBase64 = r['imageBase64'] ?? '';
              final link = r['link'] ?? '';

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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.menu_book,
                              color: Colors.blue.shade600, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            r['title'] ?? '',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textMain),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.edit_outlined,
                              color: AppColors.accent, size: 20),
                          onPressed: () => _showFormDialog(
                            context,
                            adminService,
                            id: id,
                            title: r['title'],
                            content: r['content'],
                            existingImageBase64: imageBase64,
                            existingLink: link,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red, size: 20),
                          onPressed: () => _confirmDelete(
                              context, adminService, id, r['title'] ?? ''),
                        ),
                      ],
                    ),
                    if ((r['content'] ?? '').isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Divider(color: AppColors.border, height: 1),
                      const SizedBox(height: 10),
                      Text(
                        r['content'] ?? '',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textDim,
                            height: 1.5),
                      ),
                    ],
                    if (imageBase64.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          base64Decode(imageBase64),
                          height: 80,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
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

  void _showFormDialog(
    BuildContext context,
    AdminService adminService, {
    String? id,
    String? title,
    String? content,
    String? existingImageBase64,
    String? existingLink,
  }) {
    showDialog(
      context: context,
      builder: (_) => _RuleFormDialog(
        adminService: adminService,
        id: id,
        initialTitle: title,
        initialContent: content,
        existingImageBase64: existingImageBase64,
        existingLink: existingLink,
      ),
    );
  }

  void _confirmDelete(BuildContext context, AdminService adminService,
      String id, String title) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Panduan',
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Hapus "$title"? Data tidak bisa dikembalikan.',
            style: TextStyle(color: AppColors.textDim)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Batal', style: TextStyle(color: AppColors.textDim)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await adminService.deleteRule(id);
            },
            child: const Text('Hapus',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Form Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _RuleFormDialog extends StatefulWidget {
  final AdminService adminService;
  final String? id;
  final String? initialTitle;
  final String? initialContent;
  final String? existingImageBase64;
  final String? existingLink;

  const _RuleFormDialog({
    required this.adminService,
    this.id,
    this.initialTitle,
    this.initialContent,
    this.existingImageBase64,
    this.existingLink,
  });

  @override
  State<_RuleFormDialog> createState() => _RuleFormDialogState();
}

class _RuleFormDialogState extends State<_RuleFormDialog> {
  late TextEditingController _titleCtrl;
  late TextEditingController _contentCtrl;
  late TextEditingController _linkCtrl;
  String? _currentImageBase64;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialTitle ?? '');
    _contentCtrl = TextEditingController(text: widget.initialContent ?? '');
    _linkCtrl = TextEditingController(text: widget.existingLink ?? '');
    _currentImageBase64 = widget.existingImageBase64;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
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
    setState(() {
      _currentImageBase64 = '';
    });
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);

    final titleText = _titleCtrl.text.trim();
    final contentText = _contentCtrl.text.trim();
    final linkText = _linkCtrl.text.trim();
    final isEdit = widget.id != null;

    Navigator.pop(context);

    if (isEdit) {
      await widget.adminService.updateRule(
        widget.id!,
        titleText,
        contentText,
        imageBase64: _currentImageBase64,
        link: linkText,
      );
    } else {
      await widget.adminService.createRule(
        titleText,
        contentText,
        imageBase64: _currentImageBase64,
        link: linkText,
      );
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
        isEdit ? 'Edit Panduan' : 'Tambah Panduan',
        style: TextStyle(
            fontWeight: FontWeight.w900, color: AppColors.primary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildField(_titleCtrl, 'Judul panduan'),
            const SizedBox(height: 12),
            _buildField(_contentCtrl, 'Isi konten...', maxLines: 5),
            const SizedBox(height: 12),
            _buildField(_linkCtrl, 'Link (opsional, misal: https://...)'),
            const SizedBox(height: 12),

            // Label Foto
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
                icon: Icon(Icons.image, color: AppColors.accent, size: 16),
                label: Text('Ganti Foto',
                    style: TextStyle(color: AppColors.accent, fontSize: 12)),
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
          child: Text('Batal', style: TextStyle(color: AppColors.textDim)),
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

  Widget _buildField(TextEditingController controller, String hint,
      {int maxLines = 1}) {
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