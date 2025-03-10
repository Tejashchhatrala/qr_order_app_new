import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'screens/auth/phone_auth_screen.dart';
import 'screens/customer/customer_home_screen.dart';
import 'screens/vendor/dashboard/vendor_dashboard.dart';
import 'models/user_type.dart';
import 'services/notification_service.dart';
import 'services/navigation_service.dart';
import 'services/connectivity_service.dart';
import 'services/background_service.dart';
import 'providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService().initialize();
  await BackgroundService.initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return MaterialApp(
            navigatorKey: NavigationService.navigatorKey,
            title: 'QR Order App',
            themeMode: settings.settings.themeMode,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              scaffoldBackgroundColor: Colors.white,
            ),
            darkTheme: ThemeData.dark().copyWith(
              primaryColor: Colors.blue,
            ),
            routes: {
              '/home': (context) => const CustomerHomeScreen(),
              '/vendor': (context) => const VendorDashboard(),
              '/scan': (context) => const QRScannerScreen(),
              '/cart': (context) => const CartScreen(),
            },
            home: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasData) {
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(snapshot.data!.uid)
                        .get(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final userType = userSnapshot.data?['userType'] ?? '';
                      if (userType == UserType.vendor.toString()) {
                        return const VendorDashboard();
                      } else {
                        return const CustomerHomeScreen();
                      }
                    },
                  );
                }

                return const PhoneAuthScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
