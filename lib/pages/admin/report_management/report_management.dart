import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_secure_scan/pages/admin/report_management/report_details_page.dart';

class ReportManagementPage extends StatefulWidget {
  const ReportManagementPage({super.key});

  @override
  State<ReportManagementPage> createState() => _ReportManagementPageState();
}

class _ReportManagementPageState extends State<ReportManagementPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      /// body
      backgroundColor: Colors.grey[300],
      body:
      Column(
        children: [
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
                    child: Text(
                      'Unverified Reports',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('maliciousURL')
              .where('verification', isEqualTo: 'none')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Error loading reports'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No unverified reports found'));
            }

            final reports = snapshot.data!.docs;

            return ListView.builder(
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                final url = report['uRl'] ?? 'No URL provided';
                final details = report['details'] ?? 'No details provided';
                final imageUrl = report['imageUrl'];
                final imageName = imageUrl != null && imageUrl.isNotEmpty
                    ? imageUrl.split('/').last
                    : 'No image has been added';
                final docId = report.id;

                return Card(
                  color: Colors.deepPurple[50],
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(url, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text('Description: $details', style: TextStyle(fontSize: 16),),
                        const SizedBox(height: 8),
                        // Text('Image Name: $imageName'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ReportDetailsPage(report: report),
                              ),
                            );
                          },
                          child: const Text('Show More Details'),
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
}
