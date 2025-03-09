import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'vendor_menu_screen.dart';

class ScanQRScreen extends StatefulWidget {
  const ScanQRScreen({super.key});

  @override
  State<ScanQRScreen> createState() => _ScanQRScreenState();
}

class _ScanQRScreenState extends State<ScanQRScreen> {
  bool _isPermissionGranted = false;
  bool _isProcessing = false;
  MobileScannerController? _controller;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _isPermissionGranted = status.isGranted;
      if (_isPermissionGranted) {
        _controller = MobileScannerController();
      }
    });
  }

  void _processQRCode(String? code) {
    if (_isProcessing || code == null) return;
    setState(() => _isProcessing = true);

    try {
      if (code.contains('upi://')) {
        final upiData = _parseUPICode(code);
        if (upiData != null) {
          _controller?.stop();
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => VendorMenuScreen(
                  upiId: upiData['pa'] ?? '',
                  vendorName: upiData['pn'] ?? 'Vendor',
                ),
              ),
            );
          }
        } else {
          _showError('Invalid QR code');
          setState(() => _isProcessing = false);
        }
      } else {
        _showError('Please scan a valid UPI QR code');
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      _showError('Error processing QR code');
      setState(() => _isProcessing = false);
    }
  }

  Map<String, String>? _parseUPICode(String code) {
    try {
      final uri = Uri.parse(code);
      if (uri.scheme == 'upi') {
        return uri.queryParameters;
      }
    } catch (e) {
      print('Error parsing UPI code: $e');
    }
    return null;
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPermissionGranted) {
      return Scaffold(
        appBar: AppBar(title: const Text('Scan QR Code')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Camera permission is required'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _requestCameraPermission,
                child: const Text('Grant Permission'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                _processQRCode(barcode.rawValue);
              }
            },
            overlay: QRScannerOverlay(
              overlayColor: Colors.black.withOpacity(0.5),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          const Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Scan vendor\'s UPI QR code',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom overlay widget
class QRScannerOverlay extends StatelessWidget {
  const QRScannerOverlay({
    super.key,
    this.overlayColor = Colors.black54,
  });

  final Color overlayColor;

  @override
  Widget build(BuildContext context) {
    double scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 200.0
        : 330.0;

    return Stack(
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            overlayColor,
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.red,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  height: scanArea,
                  width: scanArea,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: CustomPaint(
            foregroundPainter: BorderPainter(),
            child: SizedBox(
              width: scanArea + 25,
              height: scanArea + 25,
            ),
          ),
        ),
      ],
    );
  }
}

// Custom border painter
class BorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const width = 4.0;
    const radius = 20.0;
    const tRadius = 3 * radius;
    final rect = Rect.fromLTWH(
      width,
      width,
      size.width - 2 * width,
      size.height - 2 * width,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(radius));
    const clippingRect0 = Rect.fromLTWH(
      0,
      0,
      tRadius,
      tRadius,
    );
    final clippingRect1 = Rect.fromLTWH(
      size.width - tRadius,
      0,
      tRadius,
      tRadius,
    );
    final clippingRect2 = Rect.fromLTWH(
      0,
      size.height - tRadius,
      tRadius,
      tRadius,
    );
    final clippingRect3 = Rect.fromLTWH(
      size.width - tRadius,
      size.height - tRadius,
      tRadius,
      tRadius,
    );

    final path = Path()
      ..addRect(clippingRect0)
      ..addRect(clippingRect1)
      ..addRect(clippingRect2)
      ..addRect(clippingRect3);

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
