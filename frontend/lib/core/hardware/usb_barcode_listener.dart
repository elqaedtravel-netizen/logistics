import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

typedef BarcodeScanCallback = void Function(String scannedBarcode);

class UsbBarcodeScannerListener {
  static final UsbBarcodeScannerListener _instance =
      UsbBarcodeScannerListener._internal();
  factory UsbBarcodeScannerListener() => _instance;

  UsbBarcodeScannerListener._internal();

  final StringBuffer _buffer = StringBuffer();
  DateTime? _lastKeystrokeTime;
  BarcodeScanCallback? _onScanCallback;
  bool _isListening = false;

  // Maximum milliseconds between keystrokes to be recognized as hardware scanner input
  static const int _hardwareScanThresholdMs = 80;

  void initialize(BarcodeScanCallback onScan) {
    _onScanCallback = onScan;
    if (!_isListening) {
      HardwareKeyboard.instance.addHandler(_handleKeyEvent);
      _isListening = true;
      debugPrint('🔌 USB Hardware Barcode Scanner listener activated for Windows.');
    }
  }

  void dispose() {
    if (_isListening) {
      HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
      _isListening = false;
      _buffer.clear();
      debugPrint('🛑 USB Barcode Scanner listener disposed.');
    }
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final now = DateTime.now();
    final key = event.logicalKey;

    // Check if user pressed Enter (which standard USB scanners append at the end of a scan)
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      if (_buffer.isNotEmpty) {
        final scannedData = _buffer.toString().trim();
        _buffer.clear();
        _lastKeystrokeTime = null;

        if (scannedData.length >= 3 && _onScanCallback != null) {
          debugPrint('⚡ Raw USB Scanner Captured: "$scannedData"');
          _onScanCallback!(scannedData);
          return true; // Consume event
        }
      }
      return false;
    }

    // Check keystroke timing to verify rapid hardware scan stream vs human typing
    if (_lastKeystrokeTime != null) {
      final elapsed = now.difference(_lastKeystrokeTime!).inMilliseconds;
      if (elapsed > _hardwareScanThresholdMs) {
        // If elapsed time is too long, reset buffer (likely human manual typing)
        _buffer.clear();
      }
    }

    _lastKeystrokeTime = now;

    // Capture printable characters
    final character = event.character;
    if (character != null && character.isNotEmpty) {
      _buffer.write(character);
    }

    return false;
  }
}
