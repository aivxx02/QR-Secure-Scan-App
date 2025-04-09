import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart'; // Add url_launcher

import '../../../SMTPEmail.dart';

class ReportDetailsPage extends StatefulWidget {
  final QueryDocumentSnapshot<Object?> report;

  const ReportDetailsPage({super.key, required this.report});

  @override
  _ReportDetailsPageState createState() => _ReportDetailsPageState();
}

class _ReportDetailsPageState extends State<ReportDetailsPage> {
  TextEditingController rejectionReasonController = TextEditingController();
  String adminReason = '';
  String threatLevel = ''; // To store the selected threat level
  bool isReasonValid = false;
  bool isThreatLevelValid = false; // To validate threat level selection
  bool isLoading = false; // State variable to manage loading spinner

  /// Get the current user's session ID (UID)
  final user = FirebaseAuth.instance.currentUser!;

  /// Update database after admin VERIFIED the report / Malicious URL
  Future<void> verifyReport(String docId, String userEmail, String url, String details, String threatLevel, String adminReason) async {
    setState(() => isLoading = true); // Start loading spinner

    try {
      await FirebaseFirestore.instance
          .collection('maliciousURL')
          .doc(docId)
          .update({
        'verification': 'verified',
        'adminReason': adminReason,
        'approvedBy': user.email!, // Adding the admin email to the document
        'threatLevel': threatLevel, // Adding threat level to the document
      });

      await reportVerificationMailVerified(userEmail, url, details, threatLevel, adminReason);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Report Verified as Malicious and URL Added Into Database'),
          backgroundColor: Colors.deepPurple[500],
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to verified the report: $e'),
          backgroundColor: Colors.redAccent,
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () {},
          ),
        ),
      );
    } finally {
      setState(() => isLoading = false); // Stop loading spinner
      Navigator.pop(context); // Go back to the previous screen
    }
  }

  /// Update database after admin REJECTED the report / Safe URL
  Future<void> rejectReport(String docId, String userEmail, String adminReason, String url, String details) async {
    setState(() => isLoading = true); // Start loading spinner

    try {
      await FirebaseFirestore.instance
          .collection('maliciousURL')
          .doc(docId)
          .update({
        'verification': 'rejected',
        'adminReason': adminReason,
        'approvedBy': user.email!, // Adding the admin email to the document
      });

      await reportVerificationMailRejected(userEmail, adminReason, url, details);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Report Rejected because of Safe URL'),
          backgroundColor: Colors.deepPurple[500],
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject the report: $e'),
          backgroundColor: Colors.redAccent,
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () {},
          ),
        ),
      );
    } finally {
      setState(() => isLoading = false); // Stop loading spinner
      Navigator.pop(context); // Go back to the previous screen
    }
  }

  /// Helper function to launch URL
  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  /// UI/UX
  @override
  Widget build(BuildContext context) {
    final userEmail = widget.report['userEmail'] ?? 'No Email provided';
    final url = widget.report['uRl'] ?? 'No URL provided';
    final details = widget.report['details'] ?? 'No details provided';
    final imageUrl = widget.report['imageUrl'];
    final docId = widget.report.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Report Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w300,
            fontSize: 24,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        backgroundColor: Colors.deepPurpleAccent,
        toolbarHeight: 65,
      ),
      backgroundColor: Colors.grey[300],
      body: Stack(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Section
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    Container(
                      height: 300,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // User email
                  Text(
                    'User Email',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    userEmail,
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),

                  // URL
                  Text(
                    'Reported URL',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onLongPress: () {
                      // Copy the URL to the clipboard
                      Clipboard.setData(ClipboardData(text: url)).then((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('URL copied to clipboard'),
                            backgroundColor: Colors.deepPurpleAccent,
                          ),
                        );
                      });
                    },
                    child: Text(
                      url,
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Details
                  Text(
                    'Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    details,
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),

                  // Verify URL, with Advanced URL Checker
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple[50],
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            blurRadius: 5,
                            spreadRadius: 2,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Verify URL, with Advanced URL Checker :',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),

                          const Text(
                            '** Copy the URL by long press on URL before clicking the link above.',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.redAccent,
                            ),
                          ),
                          const SizedBox(height: 8),

                          GestureDetector(
                            onTap: () => _launchURL('https://www.virustotal.com/gui/home/url'),
                            child: Text(
                              'Virus Total URL Checker',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 16,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _launchURL('https://opentip.kaspersky.com/?tab=lookup'),
                            child: Text(
                              'Kaspersky Threat Intelligence Portal',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 16,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _launchURL('https://nordvpn.com/link-checker/'),
                            child: Text(
                              'Nord VPN Link Checker',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 16,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _launchURL('https://www.urlvoid.com/'),
                            child: Text(
                              'URL Void',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 16,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),

                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Verify button / Malicious URL
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return StatefulBuilder(
                            builder: (BuildContext context, setDialogState) {
                              return AlertDialog(
                                title: const Text('Malicious Threat Level'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('Please select the threat level for this report:'),
                                    const SizedBox(height: 10),
                                    // Dropdown for selecting threat level
                                    DropdownButtonFormField<String>(
                                      value: threatLevel.isEmpty ? null : threatLevel,
                                      items: ['low', 'medium', 'high']
                                          .map((level) => DropdownMenuItem(
                                        value: level,
                                        child: Text(level),
                                      ))
                                          .toList(),
                                      onChanged: (value) {
                                        setDialogState(() {
                                          threatLevel = value!;
                                          isThreatLevelValid = true;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(),
                                        hintText: 'Select Threat Level',
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    // TextField for entering the reason
                                    TextField(
                                      controller: rejectionReasonController,
                                      maxLines: 3,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(),
                                        hintText: 'Enter reason for why malicious',
                                      ),
                                      onChanged: (value) {
                                        setDialogState(() {
                                          adminReason = value;
                                          isReasonValid = value.isNotEmpty;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(); // Close dialog
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: isThreatLevelValid && isReasonValid
                                        ? () async {
                                      Navigator.of(context).pop(); // Close dialog
                                      setState(() => isLoading = true); // Start loading
                                      await verifyReport(
                                        docId,
                                        userEmail,
                                        url,
                                        details,
                                        threatLevel,
                                        adminReason,
                                      );
                                      setState(() => isLoading = false); // Stop loading
                                    }
                                        : null,
                                    child: const Text('Submit'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                    child: const Text(
                      'URL is Malicious',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Reject button / Safe URL
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return StatefulBuilder(
                            builder: (BuildContext context, setDialogState) {
                              return AlertDialog(
                                title: const Text('Why URL Consider Safe'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Please provide a reason : \n'),
                                    TextField(
                                      onChanged: (value) {
                                        setDialogState(() {
                                          adminReason = value;
                                          isReasonValid = value.isNotEmpty;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        hintText: 'Explain',
                                        border: OutlineInputBorder(),
                                      ),
                                      maxLines: 3,
                                    ),
                                  ],
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(); // Close the dialog
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: isReasonValid
                                        ? () async {
                                      Navigator.of(context).pop(); // Close the dialog
                                      setState(() => isLoading = true); // Start loading
                                      await rejectReport(docId, userEmail, adminReason, url, details);
                                      setState(() => isLoading = false); // Stop loading
                                    }
                                        : null,
                                    child: const Text('Submit'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                    child: const Text(
                      'URL is Safe',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),


                ],
              ),
            ),
          ),

          // Loading spinner with blur effect
          if (isLoading)
            Stack(
              children: [
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                  child: Container(
                    color: Colors.black.withOpacity(0.3), // Semi-transparent overlay
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                Center(
                  child: CircularProgressIndicator(),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
