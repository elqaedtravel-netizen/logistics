import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/constants/app_colors.dart';
import '../providers/orders_provider.dart';
import 'driver_order_action_screen.dart';

class DriverScannerScreen extends ConsumerStatefulWidget {
  const DriverScannerScreen({super.key});

  @override
  ConsumerState<DriverScannerScreen> createState() => _DriverScannerScreenState();
}

class _DriverScannerScreenState extends ConsumerState<DriverScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.isNotEmpty) {
        setState(() => _isProcessing = true);
        _handleScannedWaybill(rawValue);
        break;
      }
    }
  }

  void _handleScannedWaybill(String rawData) async {
    // Parse waybill order number
    String orderNumber = rawData.trim();
    if (orderNumber.startsWith('WAYBILL:')) {
      final parts = orderNumber.split('|');
      orderNumber = parts[0].replaceFirst('WAYBILL:', '').trim();
    }

    try {
      final order = await ref.read(orderRepositoryProvider).getOrderByNumber(orderNumber);
      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => DriverOrderActionScreen(order: order),
        ),
      ).then((_) {
        setState(() => _isProcessing = false);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order "$orderNumber" not found on server.'),
          backgroundColor: AppColors.statusCanceled,
        ),
      );
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Native Mobile Camera Scanner
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),

          // Viewfinder Overlay
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
            ),
            child: Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primaryLight, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          // Header Instruction
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Align Package Waybill QR Code within the box to scan',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          // Flashlight & Camera Controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filled(
                  icon: const Icon(Icons.flash_on, color: Colors.white),
                  style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () => _scannerController.toggleTorch(),
                ),
                const SizedBox(width: 24),
                IconButton.filled(
                  icon: const Icon(Icons.flip_camera_android, color: Colors.white),
                  style: IconButton.styleFrom(backgroundColor: AppColors.sidebarActive),
                  onPressed: () => _scannerController.switchCamera(),
                ),
              ],
            ),
          ),

          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Looking up Waybill...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
