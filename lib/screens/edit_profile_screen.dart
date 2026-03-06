import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/colors.dart';
import '../services/user_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profileData;
  const EditProfileScreen({super.key, required this.profileData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _hobiController;
  late TextEditingController _asalController;
  late TextEditingController _instagramController;
  late TextEditingController _tiktokController;
  final UserService _userService = UserService();
  File? _pickedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profileData['name'] ?? '');
    _bioController = TextEditingController(text: widget.profileData['bio'] ?? '');
    _hobiController = TextEditingController(text: widget.profileData['hobi'] ?? '');
    _asalController = TextEditingController(text: widget.profileData['asal'] ?? '');
    _instagramController = TextEditingController(text: widget.profileData['instagram'] ?? '');
    _tiktokController = TextEditingController(text: widget.profileData['tiktok'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _hobiController.dispose();
    _asalController.dispose();
    _instagramController.dispose();
    _tiktokController.dispose();
    super.dispose();
  }

  Future<void> _pickAndCropImage() async {
    PermissionStatus status;
    if (Platform.isAndroid) {
      status = await Permission.photos.request();
      if (status.isDenied) status = await Permission.storage.request();
    } else {
      status = await Permission.photos.request();
    }

    if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Izin galeri diperlukan.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Buka Pengaturan',
              textColor: Colors.white,
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Foto Profil',
          toolbarColor: const Color(0xFF6D28D9),
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: const Color(0xFF8B5CF6),
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
      ],
    );

    if (cropped != null) setState(() => _pickedImage = File(cropped.path));
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama tidak boleh kosong.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_pickedImage != null) await _userService.uploadPhotoBase64(_pickedImage!);
      await _userService.updateProfile(
        name: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        hobi: _hobiController.text.trim(),
        asal: _asalController.text.trim(),
        instagram: _instagramController.text.trim().replaceAll('@', ''),
        tiktok: _tiktokController.text.trim().replaceAll('@', ''),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentBase64 = widget.profileData['photoBase64'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: AppColors.accent, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Profil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar Picker
            GestureDetector(
              onTap: _pickAndCropImage,
              child: Stack(
                children: [
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)]),
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: const [BoxShadow(color: Color(0x33A855F7), blurRadius: 20, offset: Offset(0, 10))],
                    ),
                    padding: const EdgeInsets.all(3),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(37),
                      child: _pickedImage != null
                          ? Image.file(_pickedImage!, fit: BoxFit.cover)
                          : currentBase64.isNotEmpty
                              ? Image.memory(base64Decode(currentBase64), fit: BoxFit.cover)
                              : Container(
                                  color: Colors.purple.shade100,
                                  child: const Icon(Icons.person, size: 60, color: Colors.purple),
                                ),
                    ),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text('Ketuk foto untuk mengganti', style: TextStyle(fontSize: 11, color: AppColors.textDim)),
            const SizedBox(height: 32),

            // Nama
            _buildLabel('NAMA / USERNAME'),
            const SizedBox(height: 8),
            _buildTextField(_nameController, 'Masukkan nama kamu'),
            const SizedBox(height: 20),

            // Bio
            _buildLabel('BIO'),
            const SizedBox(height: 8),
            _buildTextField(_bioController, 'Ceritakan sedikit tentang kamu...', maxLines: 3),
            const SizedBox(height: 20),

            // Hobi
            _buildLabel('HOBI'),
            const SizedBox(height: 8),
            _buildTextField(_hobiController, 'Contoh: Gaming, Musik, Coding...'),
            const SizedBox(height: 20),

            // Asal
            _buildLabel('ASAL'),
            const SizedBox(height: 8),
            _buildTextField(_asalController, 'Kota atau daerah asal kamu'),
            const SizedBox(height: 20),

            // Sosmed
            _buildLabel('SOSIAL MEDIA'),
            const SizedBox(height: 8),
            _buildSosmedField(
              controller: _instagramController,
              hint: 'Username Instagram (tanpa @)',
              icon: Icons.camera_alt_outlined,
              color: Colors.pink,
            ),
            const SizedBox(height: 12),
            _buildSosmedField(
              controller: _tiktokController,
              hint: 'Username TikTok (tanpa @)',
              icon: Icons.music_note,
              color: Colors.black87,
            ),
            const SizedBox(height: 48),

            // Tombol Simpan
            _isLoading
                ? Column(
                    children: [
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 12),
                      Text('Menyimpan...', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                    ],
                  )
                : GestureDetector(
                    onTap: _saveProfile,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)]),
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        boxShadow: [BoxShadow(color: Color(0x4DA855F7), blurRadius: 15, offset: Offset(0, 5))],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'SIMPAN PERUBAHAN',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.textDim),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textDim, fontSize: 14),
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.accent, width: 2)),
      ),
    );
  }

  Widget _buildSosmedField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color color,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textDim, fontSize: 14),
        prefixIcon: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.accent, width: 2)),
      ),
    );
  }
}