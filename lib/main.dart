import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/auth/phone_auth_screen.dart';
import 'screens/customer/customer_home_screen.dart';
import 'screens/vendor/dashboard/vendor_dashboard.dart';
import 'models/user_type.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/notification_service.dart'; // Add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService().initialize(); // This should work now
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Order App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const PhoneAuthScreen();
          }

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(snapshot.data!.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                return const PhoneAuthScreen();
              }

              final userData =
                  userSnapshot.data!.data() as Map<String, dynamic>;
              final userType =
                  userData['userType'] == UserType.vendor.toString()
                      ? UserType.vendor
                      : UserType.customer;

              return userType == UserType.vendor
                  ? const VendorDashboard()
                  : const CustomerHomeScreen();
            },
          );
        },
      ),
    );
  }
}
