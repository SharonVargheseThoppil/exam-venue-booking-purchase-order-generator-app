import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:evb/screens/auth_service.dart';


class SendPOGmailScreen extends StatefulWidget {
  @override
  _SendPOGmailScreenState createState() => _SendPOGmailScreenState();
}

class _SendPOGmailScreenState extends State<SendPOGmailScreen> {
  List<Map<String, dynamic>> poPdfs = [];

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    fetchGeneratedPdfs();
  }

  void _checkAuthentication() async {
    bool isAuthenticated = await AuthService.isAuthenticated();
    if (!isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> fetchGeneratedPdfs() async {
    final response = await http.get(
      Uri.parse('http://192.168.39.81:5001/send_po_pdf/fetch_generated_pdfs'),
    );

    if (response.statusCode == 200) {
      setState(() {
        poPdfs = List<Map<String, dynamic>>.from(json.decode(response.body));
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch PDFs")),
      );
    }
  }
Future<void> sendViaGmail(String pdfUrl, String fileName) async {
  // Gmail deep link for app
  final Uri gmailUri = Uri.parse(
    "mailto:?subject=PO PDF ($fileName)&body=Please find the attached PO PDF.\n$pdfUrl"
  );

  if (await canLaunchUrl(gmailUri)) {
    await launchUrl(gmailUri);
    return;
  }

  // Fallback to browser Gmail
  final Uri webGmailUri = Uri.parse(
    "https://mail.google.com/mail/u/0/?view=cm&fs=1&tf=1&to=&su=PO PDF ($fileName)&body=Please find the attached PO PDF.\n$pdfUrl"
  );

  if (await launchUrl(webGmailUri, mode: LaunchMode.externalApplication)) {
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Unable to open Gmail.")),
  );
}

  @override
  Widget build(BuildContext context) {
    // Check screen width for responsiveness
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text("Send Purchase Order PDFs"),
        backgroundColor: const Color.fromARGB(255, 181, 241, 235),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/home'); // Navigate to home screen
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(screenWidth > 600 ? 32.0 : 16.0), // Larger padding for tablets and desktops
        child: poPdfs.isEmpty
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: poPdfs.length,
                itemBuilder: (context, index) {
                  final pdf = poPdfs[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 6,
                    child: Padding(
                      padding: EdgeInsets.all(screenWidth > 600 ? 24.0 : 16.0), // Adjust padding based on screen width
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Adjust column width on larger screens
                          Flexible(
                            flex: screenWidth > 600 ? 2 : 3, // More space for details on larger screens
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pdf['filename'],
                                  style: TextStyle(
                                    fontSize: screenWidth > 600 ? 18 : 16, // Larger text for larger screens
                                    fontWeight: FontWeight.bold,
                                    color: const Color.fromARGB(255, 6, 85, 77),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Generated on: ${pdf['generated_date']}",
                                  style: TextStyle(
                                    fontSize: screenWidth > 600 ? 16 : 14, // Larger text for larger screens
                                    color: const Color.fromARGB(255, 10, 10, 10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Button width adjustment based on screen size
                          Flexible(
                            flex: screenWidth > 600 ? 1 : 2,
                            child: ElevatedButton.icon(
                              onPressed: () => sendViaGmail(pdf['pdf_url'], pdf['filename']),
                              icon: Icon(Icons.email),
                              label: Text(
                                "Send via Gmail",
                                style: TextStyle(fontSize: screenWidth > 600 ? 16 : 14),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 227, 235, 228),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                padding: EdgeInsets.symmetric(
                                    vertical: screenWidth > 600 ? 12.0 : 8.0, horizontal: screenWidth > 600 ? 24.0 : 16.0),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}