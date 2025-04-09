import 'package:flutter/material.dart';
import 'login_screen.dart'; // Replace with the actual path to the login screen

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    double logoSize = screenWidth * 0.3;
    double titleFontSize = screenWidth > 600 ? 32.0 : 28.0;
    double subtitleFontSize = screenWidth > 600 ? 18.0 : 16.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logopo.png',
                height: logoSize,
                width: logoSize,
              ),
              SizedBox(height: screenHeight * 0.05),
              Text(
                'Exam Venue Booking Purchase Order Generator',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 33, 65, 121),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.02),
              Text(
                'Your Trusted Partner in Exam Venue Bookings and Purchase Orders generation',
                style: TextStyle(
                  fontSize: subtitleFontSize,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.05),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                child: Text('Get Started', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
