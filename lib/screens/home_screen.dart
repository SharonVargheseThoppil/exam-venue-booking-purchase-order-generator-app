import 'package:flutter/material.dart';
import 'package:evb/screens/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import the shared_preferences package

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String username = '';  // Variable to store the username
  String email = '';     // Variable to store the email

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    _loadUserData();  // Load user data when the screen is initialized
  }

  // Check if the user is authenticated
  void _checkAuthentication() async {
    bool isAuthenticated = await AuthService.isAuthenticated(); 
    if (!isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // Load username and email from SharedPreferences
  void _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedUsername = prefs.getString('username');  // Retrieve saved username
    String? savedEmail = prefs.getString('email');        // Retrieve saved email

    setState(() {
      username = savedUsername ?? 'Guest';  // If no data is found, set a default value
      email = savedEmail ?? 'No Email Provided';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard"),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Drawer Header
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Displaying dynamic username and email
                  Text(
                    'Welcome, $username',  // Dynamic username
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    email,  // Dynamic email
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            // Menu Items
            ListTile(
              leading: Icon(Icons.location_city),
              title: Text('Venue Booking'),
              onTap: () {
                Navigator.pushNamed(context, '/venue_booking');
              },
            ),
           
            ListTile(
              leading: Icon(Icons.description),
              title: Text('Create Purchase Order'),
              onTap: () {
                Navigator.pushNamed(context, '/purchase_order');
              },
            ),
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Edit Purchase Order'),
              onTap: () {
                Navigator.pushNamed(context, '/po');
              },
            ),
            ListTile(
              leading: Icon(Icons.picture_as_pdf),
              title: Text('Generate PO PDF'),
              onTap: () {
                Navigator.pushNamed(context, '/po_pdf');
              },
            ),
            
         
            ListTile(
              leading: Icon(Icons.send),
              title: Text('Send PO via Gmail'),
              onTap: () {
                Navigator.pushNamed(context, '/sendPOGmail');
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
            // Log out functionality
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('Logout'),
              onTap: () async {
                Navigator.pushNamed(context, '/login'); // Redirect to login screen without clearing session
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Text("Welcome to the Dashboard!"),
      ),
    );
  }
}
