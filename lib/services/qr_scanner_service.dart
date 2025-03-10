import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/material.dart';

class QRScannerService {
  static String? extractUpiIdFromQR(String qrData) {
    try {
      Uri uri = Uri.parse(qrData);
      if (uri.scheme != 'upi') return null;

      // Extract UPI ID from the pa (payment address) parameter
      String? upiId = uri.queryParameters['pa'];
      return upiId?.split('@').first; // Remove the @provider part
    } catch (e) {
      return null;
    }
  }
}
