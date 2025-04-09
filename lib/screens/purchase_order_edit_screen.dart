import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:evb/screens/auth_service.dart';

class PurchaseOrderEditScreen extends StatefulWidget {
  @override
  _PurchaseOrderEditScreenState createState() =>
      _PurchaseOrderEditScreenState();
}

class _PurchaseOrderEditScreenState extends State<PurchaseOrderEditScreen> {
  List<dynamic> purchaseOrders = [];
  Map<String, dynamic> selectedPO = {};
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Rates for the services
  final Map<String, int> rates = {
    'morning_seat': 50,
    'afternoon_seat': 60,
    'it_admin': 200,
    'security_guard': 150,
    'electrician': 250,
    'invigilator': 300,
    'network_admin': 220,
  };

  double totalExpenses = 0.0;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    fetchPurchaseOrders();
  }

  void _checkAuthentication() async {
    bool isAuthenticated = await AuthService.isAuthenticated(); // Replace with your actual authentication logic
    if (!isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/login'); // Replace with the path to your login screen
    }
  }

  Future<String?> _getUsername() async {
    // Get the logged-in username from AuthService
    return await AuthService.getUsername();
  }

  Future<void> fetchPurchaseOrders() async {
    try {
      String? username = await _getUsername();
      if (username == null) {
        throw Exception('User is not logged in');
      }

      final response = await http.get(
        Uri.parse('http://192.168.39.81:5001/po/api/fetch_submit_po_form'),
        headers: {'X-Username': username}, // Send username in the header
      );

      if (response.statusCode == 200) {
        setState(() {
          purchaseOrders = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load purchase orders');
      }
    } catch (e) {
      print('Error fetching purchase orders: $e');
    }
  }

  // Recalculate total expenses and candidates
  void calculateTotalExpenses() {
    int morningSeats = selectedPO['seats_morning'] ?? 0;
    int afternoonSeats = selectedPO['seats_afternoon'] ?? 0;

    int totalCandidates = morningSeats + afternoonSeats;
    int invigilatorCount = (totalCandidates / 40).ceil();

    setState(() {
      selectedPO['total_candidates'] = totalCandidates;
      selectedPO['invigilators'] = invigilatorCount;

      totalExpenses = ((morningSeats * rates['morning_seat']!.toDouble()) +
    (afternoonSeats * rates['afternoon_seat']!.toDouble()) +
    ((selectedPO['it_admins'] ?? 0) * rates['it_admin']!.toDouble()) +
    ((selectedPO['security_guards'] ?? 0) * rates['security_guard']!.toDouble()) +
    ((selectedPO['electricians'] ?? 0) * rates['electrician']!.toDouble()) +
    ((selectedPO['network_admins'] ?? 0) * rates['network_admin']!.toDouble()) +
    (invigilatorCount * rates['invigilator']!.toDouble()));

     selectedPO['total_expenses'] = totalExpenses.toDouble();

    });
  }

  Future<void> saveEditedPO(int id) async {
    try {
      if (selectedPO['exam_date'] != null &&
          selectedPO['exam_date'].isNotEmpty) {
        final DateTime parsedDate = DateFormat('EEE, dd MMM yyyy HH:mm:ss z')
            .parse(selectedPO['exam_date']);
        selectedPO['exam_date'] = DateFormat('yyyy-MM-dd').format(parsedDate);
      }

      selectedPO['total_expenses'] = totalExpenses;
      String? username = await _getUsername();
      if (username == null) {
        throw Exception('User is not logged in');
      }

      final response = await http.put(
        Uri.parse('http://192.168.39.81:5001/po/api/update_submit_po_form/$id'),
        headers: {
          'Content-Type': 'application/json',
          'X-Username': username, // Send username in the header
        },
        body: json.encode(selectedPO),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase Order updated successfully!')),
        );
        fetchPurchaseOrders();
        Navigator.pop(context); // Close the editing dialog
      } else {
        print('Error: ${response.body}');
        throw Exception('Failed to update purchase order');
      }
    } catch (e) {
      print('Error saving purchase order: $e');
    }
  }

  void editPurchaseOrder(Map<String, dynamic> po) {
    setState(() {
      selectedPO = Map.from(po);
      calculateTotalExpenses();
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Purchase Order'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    initialValue: selectedPO['username'],
                    decoration: InputDecoration(labelText: 'Username'),
                    onChanged: (value) => selectedPO['username'] = value,
                  ),
                  TextFormField(
                    initialValue: selectedPO['exam_date'],
                    decoration: InputDecoration(labelText: 'Exam Date'),
                    onChanged: (value) => selectedPO['exam_date'] = value,
                  ),
                  TextFormField(
                    initialValue: selectedPO['exam_name'],
                    decoration: InputDecoration(labelText: 'Exam Name'),
                    onChanged: (value) => selectedPO['exam_name'] = value,
                  ),
                  TextFormField(
                    initialValue: selectedPO['venue_name'],
                    decoration: InputDecoration(labelText: 'Venue Name'),
                    onChanged: (value) => selectedPO['venue_name'] = value,
                  ),
                  TextFormField(
                    initialValue: selectedPO['seats_morning'].toString(),
                    decoration: InputDecoration(labelText: 'Seats (Morning)'),
                    onChanged: (value) {
                      selectedPO['seats_morning'] = int.tryParse(value);
                      calculateTotalExpenses();
                    },
                  ),
                  TextFormField(
                    initialValue: selectedPO['seats_afternoon'].toString(),
                    decoration: InputDecoration(labelText: 'Seats (Afternoon)'),
                    onChanged: (value) {
                      selectedPO['seats_afternoon'] = int.tryParse(value);
                      calculateTotalExpenses();
                    },
                  ),
                  TextFormField(
                    initialValue: selectedPO['total_candidates'].toString(),
                    decoration:
                        InputDecoration(labelText: 'Total Candidates'),
                    readOnly: true,
                  ),
                  TextFormField(
                    initialValue: selectedPO['invigilators'].toString(),
                    decoration: InputDecoration(labelText: 'Invigilators'),
                    readOnly: true,
                  ),
                  TextFormField(
                    initialValue: selectedPO['it_admins'].toString(),
                    decoration: InputDecoration(labelText: 'IT Admins'),
                    onChanged: (value) {
                      selectedPO['it_admins'] = int.tryParse(value);
                      calculateTotalExpenses();
                    },
                  ),
                  TextFormField(
                    initialValue: selectedPO['security_guards'].toString(),
                    decoration: InputDecoration(labelText: 'Security Guards'),
                    onChanged: (value) {
                      selectedPO['security_guards'] = int.tryParse(value);
                      calculateTotalExpenses();
                    },
                  ),
                  TextFormField(
                    initialValue: selectedPO['electricians'].toString(),
                    decoration: InputDecoration(labelText: 'Electricians'),
                    onChanged: (value) {
                      selectedPO['electricians'] = int.tryParse(value);
                      calculateTotalExpenses();
                    },
                  ),
                  TextFormField(
                    initialValue: selectedPO['network_admins'].toString(),
                    decoration: InputDecoration(labelText: 'Network Admins'),
                    onChanged: (value) {
                      selectedPO['network_admins'] = int.tryParse(value);
                      calculateTotalExpenses();
                    },
                  ),
                  SizedBox(height: 10),
                  Text('Total Expenses: \$${totalExpenses.toStringAsFixed(2)}'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            ElevatedButton(
              child: Text('Save'),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  saveEditedPO(selectedPO['id']);
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Purchase Orders'),
      ),
      body: ListView.builder(
        itemCount: purchaseOrders.length,
        itemBuilder: (context, index) {
          final po = purchaseOrders[index];
          return Card(
            margin: EdgeInsets.all(8.0),
            child: ListTile(
              title: Text('${po['venue_name']} - PO Form'),
              trailing: ElevatedButton(
                child: Text('Edit'),
                onPressed: () => editPurchaseOrder(po),
              ),
            ),
          );
        },
      ),
    );
  }
}
