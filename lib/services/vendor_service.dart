import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vendor.dart';

class VendorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Vendor?> getVendorByUpiId(String upiId) async {
    try {
      final querySnapshot = await _firestore
          .collection('vendors')
          .where('upiId', isEqualTo: upiId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      return Vendor.fromMap(
        querySnapshot.docs.first.data(),
      );
    } catch (e) {
      print('Error fetching vendor: $e');
      return null;
    }
  }
}
