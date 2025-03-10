import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/firebase_service.dart';

class QRScannerScreen extends StatelessWidget {
  const QRScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Vendor QR')),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final String code = barcodes.first.rawValue ?? '';
            if (code.startsWith('upi://')) {
              final upiId = _extractUpiId(code);
              _handleUpiScan(context, upiId);
            }
          }
        },
      ),
    );
  }

  String _extractUpiId(String upiUrl) {
    // Extract UPI ID from UPI URL
    final uri = Uri.parse(upiUrl);
    return uri.queryParameters['pa'] ?? '';
  }

  Future<void> _handleUpiScan(BuildContext context, String upiId) async {
    try {
      final vendor = await FirebaseService().getVendorByUpiId(upiId);
      if (vendor != null && context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VendorMenuScreen(vendor: vendor),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vendor not found')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
