import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:qr_secure_scan/pages/users/report_malicious_url.dart';
import 'package:qr_secure_scan/pages/users/scan/scan_page.dart';
import 'package:qr_secure_scan/pages/users/view_report.dart';
import '../../admin/login/admin_login.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  // This is the default index, you can set it to any index you want.
  int _selectedIndex = 1;

  // Define the pages for each tab.
  final List<Widget> _pages = [
    const ViewReportPage(),
    const QRScanPage(),
    const ReportMaliciousUrlPage(),
    const AdminLoginPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      // Display the currently selected page based on the _selectedIndex.
      body: _pages[_selectedIndex],

      bottomNavigationBar: Container(
        color: Colors.deepPurpleAccent,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 15.0,
            vertical: 10,
          ),
          child: GNav(
            backgroundColor: Colors.deepPurpleAccent,
            color: Colors.white,
            tabBorder: Border.all(color: Colors.deepPurple, width: 1),
            activeColor: Colors.white,
            tabBackgroundColor: Colors.deepPurple.shade500,
            gap: 8,
            padding: const EdgeInsets.all(16),

            // Set the initial index
            selectedIndex: _selectedIndex,
            onTabChange: (index) {
              setState(() {
                _selectedIndex = index; // Update the selected index
              });
            },

            tabs: const [
              GButton(
                icon: Icons.assignment_rounded,
                text: 'View Report',
              ),
              GButton(
                icon: Icons.qr_code_scanner_rounded,
                text: 'Scan',
              ),
              GButton(
                icon: Icons.bug_report_rounded,
                text: 'Report Malicious URL',
              ),
              GButton(
                icon: Icons.admin_panel_settings,
                text: 'Admin Login',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
