import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:qr_secure_scan/pages/admin/admin_homepage.dart';
import 'fetch_report_count.dart';

class TotalMaliciousReport extends StatefulWidget {
  const TotalMaliciousReport({super.key});

  @override
  State<TotalMaliciousReport> createState() => _TotalMaliciousReportState();
}

class _TotalMaliciousReportState extends State<TotalMaliciousReport> {
  final user = FirebaseAuth.instance.currentUser!; // Get current user UID
  final FetchReportCount fetchReportCount = FetchReportCount(); // Create instance of FetchReportCount
  String _selectedFilter = 'all'; // Default filter
  int verifiedByAdmin = 0; // Count of malicious reports by verified by admin
  int addedByAdmin = 0;  // Count of malicious reports added by admin

  @override
  void initState() {
    super.initState();
    _loadCount(); // Fetch unverified report count when the widget initializes
  }

  // Function to load unverified report count using FetchReportCount class
  Future<void> _loadCount() async {
    // Fetch the counts
    int verified = await fetchReportCount.fetchMaliciousCount();
    int added = await fetchReportCount.fetchAddedbyAdmin();

    // Update the state
    setState(() {
      verifiedByAdmin = verified;
      addedByAdmin = added;
    });
  }

  // Method to get filtered reports from Firestore based on verification status
  Stream<QuerySnapshot> _getFilteredReports(String filter) {
    final collection = FirebaseFirestore.instance.collection('maliciousURL');

    if (filter == 'all') {
      // Return reports with total malicious report status
      return collection.where('verification', isEqualTo: 'verified').snapshots();
    } else if (filter == 'addedByAdmin') {
      // Return reports with added by 'Admin reports
      return collection
          .where('verification', isEqualTo: 'verified')
          .where('userEmail', isEqualTo: 'Added by Admin')
          .snapshots();
    } else if (filter == 'verifiedByAdmin') {
      // Return reports with verified by 'Admin
      return collection
          .where('verification', isEqualTo: 'verified')
          .where('userEmail', isNotEqualTo: 'Added by Admin')
          .snapshots();
    }
    else {
      return collection.where('verification', isEqualTo: filter).snapshots();
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
              _buildFilterOption('Added by Admin', 'addedByAdmin'),
              _buildFilterOption('Verified by Admin', 'verifiedByAdmin'),
              // _buildFilterOption('None', 'none'),
              // 'In Progress' option would be handled separately, for now removed
            ],
          ),
        );
      },
    );
  }

  // Helper widget to build the filter options in the dialog
  Widget _buildFilterOption(String title, String value) {
    return RadioListTile<String>(
      title: Text(title),
      value: value,
      groupValue: _selectedFilter,
      onChanged: (value) {
        setState(() {
          _selectedFilter = value!; // Update filter value
        });
        Navigator.of(context).pop(); // Close dialog
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white,  // Change the back button color to white
        ),
        backgroundColor: Colors.deepPurpleAccent,
        toolbarHeight: 65,
        title: Text(
          'Malicious Reports',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w200,
            fontSize: 30,
          ),
        ),
      ),
      backgroundColor: Colors.grey[300],

      /// body
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
                      'Added by Admin/Verified Report',
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
                  'Added By Admin',
                  addedByAdmin,
                  Colors.red,
                  'addedByAdmin',
                ),
                _buildOverviewCard(
                  'Verified By Admin',
                  verifiedByAdmin,
                  Colors.green,
                  'verifiedByAdmin',
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
                      color: userEmail == 'Added by Admin'
                          ? Colors.deepPurple[50]
                          : verification == 'verified'
                          ? Colors.deepPurple[50]
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
                            if (userEmail == 'Added by Admin')
                              Center(
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(color: Colors.black),
                                    children: [
                                      TextSpan(
                                        text: userEmail,
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Colors.redAccent),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
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


                            if (userEmail != 'Added by Admin')
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