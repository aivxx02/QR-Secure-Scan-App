import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_secure_scan/pages/admin/report_management/report_management.dart';
import 'package:qr_secure_scan/pages/admin/total_malicious_report.dart';
import 'add_report.dart';
import 'admin_homepage.dart';
import 'admin_view_report.dart';
import 'fetch_report_count.dart'; // Import the FetchReportCount class

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  final user = FirebaseAuth.instance.currentUser!; // Get current user UID

  final FetchReportCount fetchReportCount = FetchReportCount(); // Create instance of FetchReportCount
  int verifiedCount = 0;
  int unverifiedCount = 0;
  int totalmaliciousreport = 0;

  @override
  void initState() {
    super.initState();
    _loadCount(); // Fetch unverified report count when the widget initializes
  }

  // Function to load report count using FetchReportCount class
  Future<void> _loadCount() async {
    int verified = await fetchReportCount.fetchVerifiedCount();
    int unverified = await fetchReportCount.fetchUnverifiedCount();
    int totalMalicious = await fetchReportCount.fetchTotalMaliciousCount();

    setState(() {
      verifiedCount = verified;
      unverifiedCount = unverified;
      totalmaliciousreport = totalMalicious;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: Column(
        children: [
          // Custom PreferredSize Widget as the AppBar
          PreferredSize(
            preferredSize: const Size.fromHeight(50.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
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
                    child: Center(
                      child: Text(
                        'Admin Panel / Report Management',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${user.email!}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Row with Verified and Unverified Report Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildOverviewCard(
                          'Verified Report',
                          verifiedCount,
                          Colors.green,
                              () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdminHomepage(initialIndex: 0),
                              ),
                                  (Route<dynamic> route) => false,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildOverviewCard(
                          'Unverified Report',
                          unverifiedCount,
                          Colors.orange,
                              () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdminHomepage(initialIndex: 1),
                              ),
                                  (Route<dynamic> route) => false,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Total Malicious Card
                  _buildTotalMaliciousReportCard(),
                  const SizedBox(height: 10),

                  // Add Report Card
                  _buildAddReportCard(),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widget for Overview Cards
  Widget _buildOverviewCard(String title, [int? count, Color? color, VoidCallback? onTap]) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          width: 150,
          height: 100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (count != null) ...[
                const SizedBox(height: 10),
                Text(
                  count.toString(),
                  style: TextStyle(fontSize: 24, color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widget for Add Malicious URL Card with Custom Text Style
  Widget _buildTotalMaliciousReportCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TotalMaliciousReport(),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          width: double.infinity,
          height: 120,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Total Malicious Report In Database',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                totalmaliciousreport.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent, // You can change the color if needed
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widget for Add Malicious URL Card with Custom Text Style
  Widget _buildAddReportCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddReport(),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          width: double.infinity,
          height: 120,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Add Malicious URL to Database',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Click here to add a new malicious URL to the database.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



}
