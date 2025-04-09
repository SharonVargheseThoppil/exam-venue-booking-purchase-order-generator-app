import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  static Future<bool> isAuthenticated() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('username') != null; // Check if username is saved
  }

  static Future<void> logIn(String username) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('username', username); // Save the username or token
  }

  static Future<void> logOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('username'); // Remove the username or token on logout
  } 

  // Method to fetch the saved username from SharedPreferences
  static Future<String?> getUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('username'); // Fetch the saved username
  }

  // Method to fetch the username from the database (API call)
  static Future<String?> getUsernameFromDb(String username) async {
    final response = await http.get(
      Uri.parse('http://192.168.150.91:5001/api/get_username_from_db?username=$username')
    );

    if (response.statusCode == 200) {
      var responseData = json.decode(response.body);
      return responseData['username'];  // Return the username from the response
    } else {
      print('Error fetching username from the database: ${response.body}');
      return null; // Return null if username is not found or error occurs
    }
  }
}
