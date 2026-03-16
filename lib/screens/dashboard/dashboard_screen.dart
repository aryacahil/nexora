import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../services/admin_service.dart';
import 'package:marga_void/screens/dashboard/tabs/home_tab.dart';
import 'package:marga_void/screens/dashboard/tabs/agenda_tab.dart';
import 'package:marga_void/screens/dashboard/tabs/profile_tab.dart';
import 'package:marga_void/screens/dashboard/tabs/feed_tab.dart';
import 'package:marga_void/screens/admin/admin_tab.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int activeTab = 0;
  final GlobalKey<HomeTabState> _homeTabKey = GlobalKey<HomeTabState>();
  final AdminService _adminService = AdminService();
  bool _isAdminOrOwner = false;
  bool _roleLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    await _adminService.loadRole();
    if (mounted) {
      setState(() {
        _isAdminOrOwner = _adminService.isAdminOrOwner;
        _roleLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_roleLoaded) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _buildActiveTab()),
          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(Icons.home_filled, 0),
                      _buildNavItem(Icons.photo_library_outlined, 1),
                      _buildNavItem(Icons.campaign, 2),
                      _buildNavItem(Icons.person, 3),
                      if (_isAdminOrOwner)
                        _buildNavItem(Icons.admin_panel_settings, 4),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isActive = activeTab == index;

    // Icon aktif untuk setiap tab
    IconData activeIcon = icon;
    switch (index) {
      case 0:
        activeIcon = Icons.home_filled;
        break;
      case 1:
        activeIcon = Icons.photo_library;
        break;
      case 2:
        activeIcon = Icons.campaign;
        break;
      case 3:
        activeIcon = Icons.person;
        break;
      case 4:
        activeIcon = Icons.admin_panel_settings;
        break;
    }

    return GestureDetector(
      onTap: () {
        setState(() => activeTab = index);
        if (index == 0 && _homeTabKey.currentState != null) {
          _homeTabKey.currentState!.resetToMain();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.purple.shade50
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          isActive ? activeIcon : icon,
          color: isActive ? AppColors.primary : AppColors.textDim,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildActiveTab() {
    switch (activeTab) {
      case 0:
        return HomeTab(key: _homeTabKey);
      case 1:
        return const FeedTab();
      case 2:
        return const AgendaTab();
      case 3:
        return const ProfileTab();
      case 4:
        return const AdminTab();
      default:
        return const SizedBox();
    }
  }
}