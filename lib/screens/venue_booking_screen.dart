import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:evb/screens/auth_service.dart'; 

class VenueBookingScreen extends StatefulWidget {
  @override
  _VenueBookingScreenState createState() => _VenueBookingScreenState();
}

class _VenueBookingScreenState extends State<VenueBookingScreen> {
  List<Map<String, dynamic>> venues = [];
  List<Map<String, dynamic>> bookedVenues = [];
  String? username; // Variable to hold the username

  @override
  void initState() {
    super.initState();
    fetchVenues();
    _checkAuthentication();
    _loadUser(); // Load username during initialization
  }

  // Load the username from SharedPreferences (logged-in user)
  void _loadUser() async {
    String? user = await AuthService.getUsername();
    if (user != null) {
      setState(() {
        username = user;
      });
    } else {
      print("Failed to load username.");
    }
  }

  // Check if the user is authenticated
  void _checkAuthentication() async {
    bool isAuthenticated = await AuthService.isAuthenticated();
    if (!isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/login'); // Navigate to login if not authenticated
    }
  }

  // Fetch venues from the backend
  Future<void> fetchVenues() async {
    var response = await http.get(Uri.parse('http://192.168.39.81:5001/venue_booking/api/venues'));
    var responseData = json.decode(response.body);
    setState(() {
      venues = List<Map<String, dynamic>>.from(responseData);
    });
  }

  // Toggle booking selection
  void toggleBooking(Map<String, dynamic> venue) async {
    if (username == null) {
      print('Username not loaded yet');
      return;
    }

    setState(() {
      if (bookedVenues.contains(venue)) {
        bookedVenues.remove(venue);
        removeVenueFromBookings(venue, username!); // Remove from database when unselected
      } else {
        bookedVenues.add(venue);
      }
    });
  }

  // Remove a venue from bookings in the database
  Future<void> removeVenueFromBookings(Map<String, dynamic> venue, String username) async {
    var response = await http.post(
      Uri.parse('http://192.168.39.81:5001/venue_booking/api/remove_booked_venue'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'venue_name': venue['venue_name'],
        'location': venue['location'],
        'address': venue['address'],
        'username': username, // Send the username
      }),
    );

    var responseData = json.decode(response.body);
    if (response.statusCode != 200) {
      print('Error: ${responseData['message']}');
    }
  }

  // Confirm booking and store in database
  Future<void> confirmBooking(List<Map<String, dynamic>> bookedVenues) async {
    final prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString('username'); // Get username from SharedPreferences

    if (username == null) {
      print('User is not logged in.');
      return;
    }

    final url = Uri.parse('http://192.168.39.81:5001/venue_booking/api/confirm_bookings');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username, // Send username explicitly
        'booked_venues': bookedVenues.map((venue) => venue.cast<String, dynamic>()).toList(), // Ensure correct types
      }),
    );

    if (response.statusCode == 200) {
      print('Booking confirmed successfully');
      Navigator.pushNamed(context, '/purchase_order'); // Navigate to purchase order form
    } else {
      print('Failed to confirm booking: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Venue Booking'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: showAddVenueDialog, // Open the Add Venue dialog
                  child: Text('Add Venue'),
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: venues.isEmpty
                  ? Center(child: CircularProgressIndicator()) // Show loading indicator
                  : ListView.builder(
                      itemCount: venues.length,
                      itemBuilder: (context, index) {
                        var venue = venues[index];
                        bool isBooked = bookedVenues.contains(venue);

                        return Card(
                          color: isBooked ? Colors.green[100] : Colors.white,
                          child: ListTile(
                            title: Text(
                              venue['venue_name'],
                              style: TextStyle(
                                color: isBooked ? Colors.black : Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              '${venue['location']} - ${venue['address']}',
                              style: TextStyle(
                                color: isBooked ? Colors.black : Colors.black,
                              ),
                            ),
                            trailing: ElevatedButton(
                              onPressed: () => toggleBooking(venue),
                              child: Text(isBooked ? 'Unselect' : 'Book Venue'),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (bookedVenues.isNotEmpty)
              ElevatedButton(
                onPressed: () => confirmBooking(bookedVenues),
                child: Text('Confirm Bookings'),
              ),
          ],
        ),
      ),
    );
  }

  // Show dialog to add a new venue
  void showAddVenueDialog() {
    final TextEditingController venueNameController = TextEditingController();
    final TextEditingController locationController = TextEditingController();
    final TextEditingController addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add New Venue'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: venueNameController,
                decoration: InputDecoration(labelText: 'Venue Name'),
              ),
              TextField(
                controller: locationController,
                decoration: InputDecoration(labelText: 'Location'),
              ),
              TextField(
                controller: addressController,
                decoration: InputDecoration(labelText: 'Address'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Map<String, String> newVenue = {
                  'venue_name': venueNameController.text,
                  'location': locationController.text,
                  'address': addressController.text,
                };
                addVenue(newVenue);
                Navigator.pop(context);
              },
              child: Text('Add Venue'),
            ),
          ],
        );
      },
    );
  }

  // Add a new venue
  Future<void> addVenue(Map<String, String> venueDetails) async {
  try {
    var response = await http.post(
      Uri.parse('http://192.168.39.81:5001/venue_booking/api/venues'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(venueDetails),
    );

    var responseData = json.decode(response.body);

    if (response.statusCode == 201) { // ✅ Correct status code
      print("Venue added successfully: ${responseData['message']}");
      fetchVenues(); // Refresh venue list
    } else {
      print("Error: ${responseData['message']}");
    }
  } catch (e) {
    print("Failed to add venue: $e");
  }
}

}
