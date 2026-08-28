import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/hardware/usb_barcode_listener.dart';
import '../providers/auth_provider.dart';
import 'dashboard/admin_dashboard_screen.dart';
import 'orders/admin_orders_screen.dart';
import 'drivers/admin_drivers_screen.dart';
import 'inventory/admin_inventory_screen.dart';

class AdminShellScreen extends ConsumerStatefulWidget {
  const AdminShellScreen({super.key});

  @override
  ConsumerState<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends ConsumerState<AdminShellScreen> {
  int _selectedIndex = 0;
  String _lastScannedBarcode = '';

  @override
  void initState() {
    super.initState();
    // تفعيل لاقط ماسح الباركود عبر منفذ USB لنظام ويندوز
    UsbBarcodeScannerListener().initialize((scannedData) {
      setState(() {
        _lastScannedBarcode = scannedData;
      });
      _handleHardwareScan(scannedData);
    });
  }

  @override
  void dispose() {
    UsbBarcodeScannerListener().dispose();
    super.dispose();
  }

  void _handleHardwareScan(String barcode) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        content: Row(
          children: [
            const Icon(Icons.qr_code_scanner, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '⚡ تم التقاط الباركود تلقائياً: $barcode',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    final pages = [
      const AdminDashboardScreen(),
      const AdminOrdersScreen(),
      const AdminDriversScreen(),
      const AdminInventoryScreen(),
    ];

    return Scaffold(
      body: Row(
        children: [
          // القائمة الجانبية في نظام ويندوز
          Container(
            width: 270,
            color: AppColors.sidebarBg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الهيدر واللوجو
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.local_shipping, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'أنتيجرافيتي',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                          Text(
                            'إدارة الشحن والعمليات',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.sidebarActive, height: 1),

                // عناصر القائمة
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    children: [
                      _buildNavItem(0, 'لوحة التحكم', Icons.dashboard_outlined, Icons.dashboard),
                      _buildNavItem(1, 'إدارة الأوردرات والتوزيع', Icons.receipt_long_outlined, Icons.receipt_long),
                      _buildNavItem(2, 'المناديب وتوريد العهدة', Icons.badge_outlined, Icons.badge),
                      _buildNavItem(3, 'المخزن وطباعة الباركود', Icons.inventory_2_outlined, Icons.inventory_2),
                    ],
                  ),
                ),

                // مؤشر ماسح الباركود
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.sidebarActive,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.statusDelivered,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'ماسح الباركود (USB) متصل',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (_lastScannedBarcode.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'آخر مسح: $_lastScannedBarcode',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // الملف الشخصي وزر تسجيل الخروج
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.black.withOpacity(0.2),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(
                          (authState.user?.fullName.isNotEmpty == true)
                              ? authState.user!.fullName[0].toUpperCase()
                              : 'م',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authState.user?.fullName ?? 'مدير النظام',
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text(
                              'مدير عام اللوجستيات',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: AppColors.textMuted, size: 20),
                        tooltip: 'تسجيل الخروج',
                        onPressed: () => ref.read(authProvider.notifier).logout(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // العرض الرئيسي
          Expanded(
            child: Container(
              color: AppColors.background,
              child: pages[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String title, IconData icon, IconData activeIcon) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected ? Colors.white : AppColors.textMuted,
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textMuted,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
