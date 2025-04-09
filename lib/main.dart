import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/venue_booking_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/purchase_order_form_screen.dart';
import 'screens/purchase_order_edit_screen.dart';
import 'screens/purchase_order_pdf_generation_screen.dart';
import 'screens/send_po_gmail_screen.dart';
import 'screens/auth_service.dart'; // Import auth_service.dart

void main() {
  WidgetsFlutterBinding.ensureInitialized(); 
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exam venue booking purchase order generator app',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => AuthGuard(HomeScreen()),
        '/venue_booking': (context) => AuthGuard(VenueBookingScreen()),
        '/settings': (context) => AuthGuard(SettingsScreen()),
        '/purchase_order': (context) => AuthGuard(PurchaseOrderFormScreen()),
        '/po': (context) => AuthGuard(PurchaseOrderEditScreen()),
        '/po_pdf': (context) => AuthGuard(PurchaseOrderPDFGenerationScreen()),
        '/sendPOGmail': (context) => AuthGuard(SendPOGmailScreen()),
      
      },
    );
  }
}

class AuthGuard extends StatelessWidget {
  final Widget page;
  AuthGuard(this.page);

  Future<bool> isAuthenticated() async {
    return await AuthService.isAuthenticated(); // Use AuthService to check if the user is authenticated
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isAuthenticated(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator()); // Show loading indicator while checking auth
        } else if (!snapshot.hasData || !snapshot.data!) {
          // If not authenticated, redirect to login screen
          Future.microtask(() => Navigator.pushReplacementNamed(context, '/login'));
          return Center(child: CircularProgressIndicator());
        }
        return page; // If authenticated, show the requested page
      },
    );
  }
}
