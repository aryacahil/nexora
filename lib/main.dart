import 'package:flutter/material.dart';
import 'core/colors.dart'; // Import konfigurasi warna
import 'screens/login_screen.dart'; // Import layar login sebagai start-up

void main() {
  // Fungsi utama untuk menjalankan aplikasi
  runApp(const MargaVoidApp());
}

class MargaVoidApp extends StatelessWidget {
  const MargaVoidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Judul aplikasi (terlihat di task manager)
      title: 'Marga Void',
      
      // Menghilangkan tulisan "DEBUG" di aplikasi
      debugShowCheckedModeBanner: false,
      
      // Konfigurasi Tema Global
      theme: ThemeData(
        // Menggunakan warna latar belakang dari AppColors
        scaffoldBackgroundColor: AppColors.bg,
        
        // Warna utama aplikasi
        primaryColor: AppColors.primary,
        
        // Konfigurasi font (pastikan font ini terdaftar di pubspec.yaml jika pakai custom)
        fontFamily: 'Roboto', 
        
        // Mengaktifkan Material 3 untuk desain yang lebih modern
        useMaterial3: true,
      ),
      
      // Menentukan layar utama yang pertama kali dibuka
      home: const LoginScreen(),
    );
  }
}