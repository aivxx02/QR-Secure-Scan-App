import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_secure_scan/pages/admin/admin_view_report.dart';
import 'package:qr_secure_scan/pages/admin/report_management/report_management.dart';
import 'package:qr_secure_scan/pages/users/scan/homepage.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'admin_panel.dart';

class AdminHomepage extends StatefulWidget {
  final int initialIndex;

  const AdminHomepage({super.key, this.initialIndex = 2});

  @override
  State<AdminHomepage> createState() => _AdminHomepageState();
}

class _AdminHomepageState extends State<AdminHomepage> {
  final user = FirebaseAuth.instance.currentUser!;

  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex; // Set the initial index passed from constructor
  }

  // Define the pages for each tab.
  final List<Widget> _pages = [
    const AdminViewReportPage(),
    const ReportManagementPage(),
    const AdminPanelPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 65,
        backgroundColor: Colors.deepPurpleAccent,

        leading: Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: Tooltip(
            message: 'Profile', // Tooltip message
            child: IconButton(
              icon: const Icon(
                  Icons.person,
                  color: Colors.white,
              ), // Person icon
              onPressed: () {
                // Handle icon press
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Admin Profile'),
                    content: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black), // Default color for the entire text
                        children: [
                          const TextSpan(
                            text: 'Login as: ', // First part of the text
                            style: TextStyle(color: Colors.black), // Default color
                          ),
                          TextSpan(
                            text: user.email!, // Email text
                            style: const TextStyle(color: Colors.deepPurpleAccent), // Change color for the email
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close the dialog
                        },
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),


        centerTitle: true,
        title: const Text(
          'QR Secure Scan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w200, fontSize: 28),
        ),

        actions: [
          GestureDetector(
            onTap: () {
              // when user press sign out, alert dialog pops up and sign out from there!
              showDialog(
                context: context,
                builder: (context) {

                  // yes button
                  Widget yesButton = TextButton(
                    child: const Text("Yes"),
                    onPressed: () {
                      FirebaseAuth.instance.signOut();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const Homepage(),),
                            (Route<dynamic> route) => false,
                      );

                      // snackbar pop up when user pressed yes
                      final snackBar = SnackBar(
                        content: const Text('Signed Out !'),
                        backgroundColor: (Colors.deepPurple),
                        action: SnackBarAction(
                          label: 'Dismiss',
                          onPressed: () {
                          },
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);

                    },
                  );

                  // no button
                  Widget noButton = TextButton(
                    child: const Text("No"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  );

                  return AlertDialog(
                    title: const Text(''),
                    content: const Text(
                      'Are you want to sign out?',
                      textAlign: TextAlign.center,
                    ),
                    actions: [
                      noButton,
                      yesButton,
                    ],
                  );
                },
              );
            },
            child: const Padding(
              padding: EdgeInsets.only(right: 20.0),
              child: Icon(
                  Icons.logout,
                  color: Colors.white,
              ),
            ),
          ),
        ],
      ),

      body :_pages[_selectedIndex],

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
                icon: Icons.check_circle,
                iconColor: Colors.greenAccent,
                text: 'Verified Report',
              ),
              GButton(
                icon: Icons.warning_rounded,
                iconColor: Colors.orange,
                text: 'Unverified Report',
              ),
              GButton(
                icon: Icons.home,
                text: 'Admin Panel',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
