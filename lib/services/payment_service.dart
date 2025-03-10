import 'package:url_launcher/url_launcher.dart';

class PaymentService {
  Future<bool> initiateUpiPayment(double amount, String orderId) async {
    try {
      final upiUrl = _buildUpiUrl(amount, orderId);
      final uri = Uri.parse(upiUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        throw 'Could not launch UPI payment';
      }
    } catch (e) {
      throw 'Payment failed: $e';
    }
  }

  String _buildUpiUrl(double amount, String orderId) {
    // Replace with actual UPI ID and merchant name
    const merchantUpiId = 'merchant@upi';
    const merchantName = 'Store Name';

    return 'upi://pay?pa=$merchantUpiId'
        '&pn=$merchantName'
        '&am=$amount'
        '&tr=$orderId'
        '&cu=INR';
  }
}
