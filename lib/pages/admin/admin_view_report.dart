import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:qr_secure_scan/pages/admin/admin_homepage.dart';

import 'fetch_report_count.dart';

class AdminViewReportPage extends StatefulWidget {
  const AdminViewReportPage({super.key});

  @override
  State<AdminViewReportPage> createState() => _AdminViewReportPageState();
}

class _AdminViewReportPageState extends State<AdminViewReportPage> {

  final user = FirebaseAuth.instance.currentUser!; // Get current user UID

  final FetchReportCount fetchReportCount = FetchReportCount(); // Create instance of FetchReportCount

  String _selectedFilter = 'all'; // Default filter
  int maliciousCount = 0; // Count of malicious reports
  int rejectedCount = 0;  // Count of rejected reports

  @override
  void initState() {
    super.initState();
    _loadCount(); // Fetch unverified report count when the widget initializes
  }

  // Function to load unverified report count using FetchReportCount class
  Future<void> _loadCount() async {
    // Fetch the counts
    int malicious = await fetchReportCount.fetchMaliciousCount();
    int rejected = await fetchReportCount.fetchRejectedCount();

    // Update the state
    setState(() {
      maliciousCount = malicious;
      rejectedCount = rejected;
    });
  }

  // Method to get filtered reports from Firestore based on verification status
  Stream<QuerySnapshot> _getFilteredReports(String filter) {
    final collection = FirebaseFirestore.instance.collection('maliciousURL');

    if (filter == 'all') {
      // Return reports with 'verified' or 'rejected' statuses, and where 'approvedBy' is not 'Admin'
      return collection
          .where('userEmail', isNotEqualTo: 'Added by Admin')
          .where('verification', whereIn: ['verified', 'rejected'])
          .snapshots();
    } else if (filter == 'none') {
      // Return reports with 'none' verification status
      return collection.where('verification', isEqualTo: 'none').snapshots();
    } else {
      // Return reports based on the selected filter, and ensure 'approvedBy' is not 'Admin'
      return collection
          .where('userEmail', isNotEqualTo: 'Added by Admin')
          .where('verification', isEqualTo: filter)
          .snapshots();
    }
  }

  // Method to show filter dialog for report statuses
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter By'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterOption('All', 'all'),
              _buildFilterOption('Malicious URL', 'verified'),
              _buildFilterOption('Safe URL', 'rejected'),
              // Replace 'In Progress' option with a Text widget
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black),
                    children: [
                      const TextSpan(
                        text: 'For unverified report please visit ',
                      ),
                      TextSpan(
                        text: 'Unverified Report',
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.deepPurpleAccent,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.of(context).pop(); // Close the dialog
                            // Navigate to the AdminHomepage and select the Report Management tab
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdminHomepage(initialIndex: 1),
                              ),
                                  (Route<dynamic> route) => false, // Remove previous routes
                            );
                          },
                      ),
                      const TextSpan(
                        text: ' page.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper widget to build the filter options in the dialog
  Widget _buildFilterOption(String title, String value) {
    return RadioListTile(
      title: Text(title),
      value: value,
      groupValue: _selectedFilter,
      onChanged: (value) {
        setState(() {
          _selectedFilter = value!;
        });
        Navigator.of(context).pop(); // Close dialog
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      /// body
      backgroundColor: Colors.grey[300],
      body: Column(
        children: [
          PreferredSize(
            preferredSize: const Size.fromHeight(50.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
              decoration: BoxDecoration(color: Colors.grey[300], boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ]),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'Verified Reports By Admin',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.filter_list, color: Colors.black, size: 22),
                    onPressed: _showFilterDialog, // Open the filter dialog
                  ),
                ],
              ),
            ),
          ),

          // Malicious and Rejected Report Cards
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOverviewCard(
                  'Verified as (Malicious URL)',
                  maliciousCount,
                  Colors.red,
                  'verified',
                ),
                _buildOverviewCard(
                  'Rejected as  (Safe URL)',
                  rejectedCount,
                  Colors.green,
                  'rejected',
                ),
              ],
            ),
          ),

          // List of reports
          Expanded(
            child: StreamBuilder(
              stream: _getFilteredReports(_selectedFilter),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading reports'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No reports found'));
                }

                final reports = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    final url = report['uRl'] ?? 'No URL provided';
                    final Timestamp? reportedAtTimestamp = report['reportedAt'];
                    final DateTime? reportedAt = reportedAtTimestamp?.toDate();
                    final String reportedAtFormatted = reportedAt != null
                        ? DateFormat('dd-MM-yyyy').format(reportedAt)
                        : 'No date provided';
                    final userEmail = report['userEmail'] ?? 'No details provided';
                    final details = report['details'] ?? 'No details provided';
                    final verification = report['verification'] ?? 'none';
                    final approvedBy = report['approvedBy'] ?? 'No details provided';
                    final adminReason = report['adminReason'] ?? 'No Rejection Reason provided';
                    final threatLevel = report['threatLevel'] ?? 'No Threat Level provided';

                    return Card(
                      color: verification == 'rejected'
                          ? Colors.greenAccent[100]
                          : verification == 'verified'
                          ? Colors.red[200]
                          : Colors.deepPurple[50],
                      margin: const EdgeInsets.all(8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // URL
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(color: Colors.black),
                                children: [
                                  const TextSpan(
                                    text: '',
                                  ),
                                  TextSpan(
                                    text: url,
                                    style: const TextStyle(
                                        fontSize: 20, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            // user email
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(color: Colors.black),
                                children: [
                                  const TextSpan(
                                    text: 'User Email: ',
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                  ),
                                  TextSpan(
                                    text: userEmail,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Description
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(color: Colors.black),
                                children: [
                                  const TextSpan(
                                    text: 'User Description: ',
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                  ),
                                  TextSpan(
                                    text: details,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Malware status
                            Row(
                              children: [
                                const Text(
                                  'Malware Status: ',
                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                                ),
                                if (verification == 'verified')
                                  Row(
                                    children: const [
                                      Icon(Icons.cancel, color: Colors.red, size: 20),
                                      Text(' Malicious', style: TextStyle(fontSize: 17)),
                                    ],
                                  ),
                                if (verification == 'rejected')
                                  Row(
                                    children: const [
                                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                                      Text(' Safe', style: TextStyle(fontSize: 17)),
                                    ],
                                  ),
                                if (verification == '')
                                  Row(
                                    children: const [
                                      Text('(Pending)', style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey,
                                        fontSize: 15,
                                      ),),
                                    ],
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Threat Level
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(color: Colors.black),
                                children: [
                                  const TextSpan(
                                    text: 'Threat Level: ',
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                  ),
                                  TextSpan(
                                    text: verification == 'verified' ? threatLevel : '',
                                    style: const TextStyle(fontSize: 16),
                                    children: verification != 'verified'
                                        ? [
                                      TextSpan(
                                        text: ' None',
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ]
                                        : [],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Rejected Reason
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(color: Colors.black),
                                children: [
                                  const TextSpan(
                                    text: 'Admin Explanation: ',
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                  ),
                                  if (verification == 'rejected')
                                    TextSpan(
                                      text: adminReason,
                                      style: const TextStyle(fontSize: 16),
                                    )
                                  else if (verification == 'verified')
                                    TextSpan(
                                      text: adminReason,
                                      style: const TextStyle(fontSize: 16),
                                    )
                                  else
                                    TextSpan(
                                      text: ' (Not Available)',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Approved By
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(color: Colors.black),
                                children: [
                                  const TextSpan(
                                    text: 'Approved by: ',
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                  ),
                                  TextSpan(
                                    text: approvedBy,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Reported Date
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(color: Colors.black),
                                children: [
                                  const TextSpan(
                                    text: 'Reported At: ',
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                  ),
                                  TextSpan(
                                    text: reportedAtFormatted,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),


                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget to build the overview cards with onTap functionality
  Widget _buildOverviewCard(String title, int count, Color color, String filter) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter; // Update the selected filter
        });
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          width: 150,
          height: 120,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                count.toString(),
                style: TextStyle(fontSize: 24, color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

