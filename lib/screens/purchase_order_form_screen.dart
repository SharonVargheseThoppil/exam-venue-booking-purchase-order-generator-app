import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:evb/screens/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseOrderFormScreen extends StatefulWidget {
  const PurchaseOrderFormScreen({Key? key}) : super(key: key);

  @override
  _PurchaseOrderFormScreenState createState() =>
      _PurchaseOrderFormScreenState();
}

class _PurchaseOrderFormScreenState extends State<PurchaseOrderFormScreen> {
  bool isLoading = false;
  List<dynamic> venues = [];
  DateTime? selectedDate;
  String? selectedExam;
  int invigilatorCount = 0;

  final TextEditingController dateController = TextEditingController();

  int morningSeats = 0;
  int afternoonSeats = 0;
  int noOfITAdmins = 0;
  int noOfSecurityGuards = 0;
  int noOfElectricians = 0;
  int noOfNetworkAdmins = 0;
  double totalExpenses = 0;

  final Map<String, double> rates = {
    'morning_seat': 50,
    'afternoon_seat': 60,
    'it_admin': 200,
    'security_guard': 150,
    'electrician': 250,
    'invigilator': 300,
    'network_admin': 220,
  };

  Future<void> fetchBookedVenues() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http
          .get(Uri.parse('http://192.168.39.81:5001/purchase_order/api/booked_venues'));

      if (response.statusCode == 200) {
        setState(() {
          venues = json.decode(response.body);
        });
      } else {
        showSnackBar('Error fetching venues');
      }
    } catch (e) {
      showSnackBar('Error: $e');
    }

    setState(() {
      isLoading = false;
    });
  }

  void calculateTotalExpenses() {
    setState(() {
      invigilatorCount = ((morningSeats + afternoonSeats) / 40).ceil();
      totalExpenses = (morningSeats * rates['morning_seat']!) +
          (afternoonSeats * rates['afternoon_seat']!) +
          (noOfITAdmins * rates['it_admin']!) +
          (noOfSecurityGuards * rates['security_guard']!) +
          (noOfElectricians * rates['electrician']!) +
          (noOfNetworkAdmins * rates['network_admin']!) +
          (invigilatorCount * rates['invigilator']!);
    });
  }

 
Future<void> submitForm(String venueName) async {
  if (selectedDate == null || selectedExam == null) {
    showSnackBar('Please complete all required fields.');
    return;
  }

  setState(() {
    isLoading = true;
  });

  final data = {
    'username': username, // Add the username here
    'exam_date': selectedDate?.toIso8601String(),
    'exam_name': selectedExam,
    'venue_name': venueName,
    'morning_seats': morningSeats,
    'afternoon_seats': afternoonSeats,
    'no_of_it_admins': noOfITAdmins,
    'no_of_security_guards': noOfSecurityGuards,
    'no_of_electricians': noOfElectricians,
    'no_of_network_admins': noOfNetworkAdmins,
    'invigilator_count': invigilatorCount,
    'total_expenses': totalExpenses,
    
  };

  try {
    final response = await http.post(
      Uri.parse('http://192.168.39.81:5001/purchase_order/api/submit_po_form'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );

    setState(() {
      isLoading = false;
    });

    if (response.statusCode == 200) {
      showSnackBar('Form submitted successfully!');
    } else {
      final error = json.decode(response.body);
      showSnackBar('Error: ${error['message']}');
    }
  } catch (e) {
    setState(() {
      isLoading = false;
    });
    showSnackBar('Submission failed: $e');
  }
}

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
String? username = ''; // Variable to store username
String email = '';

@override
void initState() {
  super.initState();
  _checkAuthentication();
  fetchBookedVenues();
}

Future<void> _checkAuthentication() async {
  bool isAuthenticated = await AuthService.isAuthenticated();
  if (!isAuthenticated) {
    Navigator.pushReplacementNamed(context, '/login');
  } else {
    _getUsername();
  }
}

Future<void> _getUsername() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  setState(() {
    username = prefs.getString('username') ?? 'Guest'; // Default to 'Guest' if no username is found
    email = prefs.getString('email') ?? 'guest@example.com'; 
  });
}

  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        dateController.text = "${selectedDate?.toLocal()}".split(' ')[0];
        calculateTotalExpenses();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Order Form'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
  decoration: BoxDecoration(
    color: Colors.blue,
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
     children: [
            Text(
              'Welcome, $username', // Display the username dynamically
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              '$email', // Display email dynamically
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),

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
                Navigator.pushNamed(context, '/send_po_pdf');
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('Logout'),
              onTap: () {
                // Removed user session clearing code
                Navigator.pushNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  ...venues.map((venue) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: ListTile(
                        title: Text(venue['venue_name']),
                        subtitle: Text('Location: ${venue['location']}'),
                        trailing: ElevatedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Create PO'),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        GestureDetector(
                                          onTap: () => _selectDate(context),
                                          child: AbsorbPointer(
                                            child: TextField(
                                              controller: dateController,
                                              decoration: const InputDecoration(
                                                labelText: 'Exam Date',
                                                hintText: 'YYYY-MM-DD',
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        TextField(
                                          decoration: const InputDecoration(
                                            labelText: 'Exam Name',
                                          ),
                                          onChanged: (value) {
                                            setState(() {
                                              selectedExam = value;
                                            });
                                          },
                                        ),
                                        const SizedBox(height: 10),
                                        TextField(
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: 'Morning Seats',
                                          ),
                                          onChanged: (value) {
                                            setState(() {
                                              morningSeats =
                                                  int.tryParse(value) ?? 0;
                                              calculateTotalExpenses();
                                            });
                                          },
                                        ),
                                        const SizedBox(height: 10),
                                        TextField(
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: 'Afternoon Seats',
                                          ),
                                          onChanged: (value) {
                                            setState(() {
                                              afternoonSeats =
                                                  int.tryParse(value) ?? 0;
                                              calculateTotalExpenses();
                                            });
                                          },
                                        ),
                                        const SizedBox(height: 10),
                                        TextField(
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: 'IT Admins',
                                          ),
                                          onChanged: (value) {
                                            setState(() {
                                              noOfITAdmins =
                                                  int.tryParse(value) ?? 0;
                                              calculateTotalExpenses();
                                            });
                                          },
                                        ),
                                        const SizedBox(height: 10),
                                        TextField(
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: 'Security Guards',
                                          ),
                                          onChanged: (value) {
                                            setState(() {
                                              noOfSecurityGuards =
                                                  int.tryParse(value) ?? 0;
                                              calculateTotalExpenses();
                                            });
                                          },
                                        ),
                                        const SizedBox(height: 10),
                                        TextField(
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: 'Electricians',
                                          ),
                                          onChanged: (value) {
                                            setState(() {
                                              noOfElectricians =
                                                  int.tryParse(value) ?? 0;
                                              calculateTotalExpenses();
                                            });
                                          },
                                        ),
                                        const SizedBox(height: 10),
                                        TextField(
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: 'Network Admins',
                                          ),
                                          onChanged: (value) {
                                            setState(() {
                                              noOfNetworkAdmins =
                                                  int.tryParse(value) ?? 0;
                                              calculateTotalExpenses();
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        submitForm(venue['venue_name']);
                                      },
                                      child: const Text('Submit'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: const Text('Create PO'),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
    );
  }
}
