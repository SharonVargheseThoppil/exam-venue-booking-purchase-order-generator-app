import 'package:flutter/material.dart';
import 'package:evb/screens/auth_service.dart'; // Ensure the correct path

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkAuthentication(), // Check authentication asynchronously
      builder: (context, snapshot) {
        // If the authentication check is still ongoing, show a loading spinner
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Settings'),
              backgroundColor: Colors.teal,
            ),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If the user is not authenticated, redirect to the login screen
        if (!snapshot.hasData || !snapshot.data!) {
          Future.microtask(() => Navigator.pushReplacementNamed(context, '/login'));
          return Scaffold(
            appBar: AppBar(
              title: Text('Settings'),
              backgroundColor: Colors.teal,
            ),
            body: Center(child: CircularProgressIndicator()), // Still showing a spinner during redirect
          );
        }

        // If authenticated, display the settings page
        return Scaffold(
          appBar: AppBar(
            title: Text('Settings'),
            backgroundColor: Colors.teal,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                _buildListTile(
                  context,
                  Icons.info,
                  'About the App',
                  AboutAppScreen(),
                ),
                _buildListTile(
                  context,
                  Icons.support,
                  'Contact Support',
                  ContactSupportScreen(),
                ),
                _buildListTile(
                  context,
                  Icons.privacy_tip,
                  'Terms and Privacy Policy',
                  TermsPrivacyScreen(),
                ),
                _buildListTile(
                  context,
                  Icons.logout,
                  'Logout',
                  null,
                  onTap: () {
                    AuthService.logOut(); // Call logout logic
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper function to build each ListTile with common styles
  Widget _buildListTile(BuildContext context, IconData icon, String title, Widget? nextScreen, {VoidCallback? onTap}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 6,
      child: ListTile(
        leading: Icon(icon, color: const Color.fromARGB(255, 27, 72, 156)),
        title: Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        onTap: onTap ?? () {
          if (nextScreen != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => nextScreen),
            );
          }
        },
      ),
    );
  }

  // Method to check authentication status
  Future<bool> _checkAuthentication() async {
    return await AuthService.isAuthenticated(); // Use AuthService to check if the user is authenticated
  }
}

// About the App Screen
class AboutAppScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('About the App'), backgroundColor: const Color.fromARGB(255, 0, 115, 150)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About the App',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            SizedBox(height: 16),
            Text(
              'This app is designed to manage Exam venue booking and purchase order generation for exam events. It allows users to efficiently book venues, generate purchase orders, and view related PDFs. With a user-friendly interface and modern design, it helps manage all tasks with ease.',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}

// Contact Support Screen
class ContactSupportScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Contact Support'), backgroundColor: Colors.teal),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Support',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            SizedBox(height: 16),
            Text(
              'For assistance or inquiries, please contact us using the following details:',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            SizedBox(height: 16),
            Text(
              'Email: support@evb.com\nPhone: +9234567890\nAddress: 1234 Venue St,Kalyan, India',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}

// Terms and Privacy Policy Screen
class TermsPrivacyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Terms and Privacy Policy'), backgroundColor: Colors.teal),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms and Conditions',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            SizedBox(height: 16),
            Text(
              '1. By using this app, you agree to the terms and conditions outlined herein.\n\n'
              '2. The app is provided "as is" without warranties of any kind.\n\n'
              '3. We reserve the right to modify the terms at any time.\n\n'
              'Privacy Policy:\n\n'
              'We value your privacy. Any data shared with the app is stored securely and will not be shared with third parties without your consent.',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
