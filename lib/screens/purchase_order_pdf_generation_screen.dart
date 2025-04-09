import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:evb/screens/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class PurchaseOrderPDFGenerationScreen extends StatefulWidget {
  @override
  _PurchaseOrderPDFGenerationScreenState createState() =>
      _PurchaseOrderPDFGenerationScreenState();
}

class _PurchaseOrderPDFGenerationScreenState
    extends State<PurchaseOrderPDFGenerationScreen> {
  List<Map<String, String>> venues = [];
  List<bool> isVisible = [];
  String? username;
  bool isLoading = true;
  final String baseUrl = 'http://192.168.39.81:5001'; // Base URL definition

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  void _checkAuthentication() async {
    bool isAuthenticated = await AuthService.isAuthenticated();
    if (!isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      await _getUsername();
      fetchVenues();
    }
  }

  Future<void> _getUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username');
    });
  }

  Future<void> fetchVenues() async {
    if (username == null) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/po_pdf/fetch_venues?username=$username'),
        headers: {"Accept": "application/json"},
      );

      print("Venues Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data.containsKey('venues')) {
          List<dynamic> venuesData = data['venues'];
          setState(() {
            venues = venuesData
                .map((venue) => {
                      'venue_name': venue['venue_name'].toString(),
                      'exam_date': venue['exam_date'].toString(),
                    })
                .toList();
            isVisible = List<bool>.filled(venues.length, true);
            isLoading = false;
          });
        } else {
          throw Exception("Invalid API response format.");
        }
      } else {
        throw Exception("Failed to load venues: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  Future<void> generatePDF(String venueName, String examDate, int index) async {
    if (username == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User not logged in")),
      );
      return;
    }

    try {
      DateTime parsedDate;
      try {
        parsedDate = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'").parse(examDate);
      } catch (e) {
        parsedDate = DateTime.parse(examDate);
      }

      String formattedDate = "${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}";

      final response = await http.post(
        Uri.parse('$baseUrl/po_pdf/generate_po_pdf'),
        headers: {"Content-Type": "application/json", "Accept": "application/json"},
        body: json.encode({
          'venue_name': venueName,
          'exam_date': formattedDate,
          'username': username,
        }),
      );

      print("Server Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData.containsKey('pdf_url')) {
          String pdfUrl = responseData['pdf_url'];
          // Ensure the PDF URL is absolute
          if (!pdfUrl.startsWith('http')) {
            pdfUrl = '$baseUrl$pdfUrl';
          }
          setState(() {
            for (int i = 0; i < isVisible.length; i++) {
              isVisible[i] = i == index;
            }
          });
          _showGeneratedPDF(pdfUrl, venueName);
        } else {
          throw Exception("Invalid API response format.");
        }
      } else {
        throw Exception("Failed to generate PDF: ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  Future<void> requestStoragePermission() async {
    PermissionStatus permissionStatus;

    if (Platform.isAndroid && (await Permission.storage.isPermanentlyDenied)) {
      permissionStatus = await Permission.manageExternalStorage.request();
    } else {
      permissionStatus = await Permission.storage.request();
    }

    if (!permissionStatus.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Storage permission denied")),
      );
    }
  }

  Future<void> downloadPDF(String pdfUrl, String venueName) async {
    try {
      await requestStoragePermission();

      print("Downloading PDF from: $pdfUrl");

      // Ensure the URL is properly formatted
      Uri uri = Uri.parse(pdfUrl);
      if (!uri.hasScheme) {
        uri = Uri.parse('$baseUrl$pdfUrl');
      }

      final response = await http.get(uri);

      print("Download Response: ${response.statusCode} - ${response.body.length} bytes");

      if (response.statusCode == 200) {
        Directory? directory = await getExternalStorageDirectory();
        if (directory == null) throw Exception("Unable to access storage.");

        String downloadsPath = "/storage/emulated/0/Download";
        String filePath = "$downloadsPath/$venueName.pdf";

        File file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        await OpenFile.open(filePath);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("PDF saved in Downloads as $venueName.pdf")),
        );
      } else {
        throw Exception("Failed to download PDF: ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  void _showGeneratedPDF(String pdfUrl, String venueName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("PDF Generated"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Your PO PDF is ready."),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                downloadPDF(pdfUrl, venueName);
                setState(() {
                  venues.removeWhere((venue) => venue['venue_name'] == venueName);
                });
                Navigator.pop(context);
              },
              child: Text("Download PDF"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Generate Purchase Order PDFs"),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/home');
          },
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isLoading
              ? Center(child: CircularProgressIndicator())
              : venues.isEmpty
                  ? Center(
                      child: Text(
                        "No venues available",
                        style: TextStyle(fontSize: 18, color: const Color.fromARGB(255, 26, 25, 25)),
                      ),
                    )
                  : ListView.builder(
                      itemCount: venues.length,
                      itemBuilder: (context, index) {
                        final venue = venues[index]['venue_name'] ?? 'Unknown Venue';
                        final examDate = venues[index]['exam_date'] ?? 'Unknown Date';

                        return Visibility(
                          visible: isVisible[index],
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            elevation: 6,
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Venue: $venue",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Exam Date: $examDate",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      generatePDF(venue, examDate, index);
                                    },
                                    icon: Icon(Icons.file_download, color: Colors.white),
                                    label: Text("Generate PO"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12.0),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}