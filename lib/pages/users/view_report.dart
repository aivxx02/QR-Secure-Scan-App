import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ViewReportPage extends StatefulWidget {
  const ViewReportPage({super.key});

  @override
  State<ViewReportPage> createState() => _ViewReportPageState();
}

class _ViewReportPageState extends State<ViewReportPage> {
  // Stream: Fetch only "verified" reports
  Stream<QuerySnapshot> _getVerifiedReports() {
    return FirebaseFirestore.instance
        .collection('maliciousURL')
        .where('verification', isEqualTo: 'verified')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// AppBar
      appBar: AppBar(
        backgroundColor: Colors.deepPurpleAccent,
        toolbarHeight: 65,
        title: const Center(
          child: Text(
            'QR Secure Scan',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w200,
              fontSize: 30,
            ),
          ),
        ),
      ),
      backgroundColor: Colors.grey[300],

      /// Body
      body: Column(
        children: [
          // Header
          PreferredSize(
            preferredSize: const Size.fromHeight(50.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'Malicious URL Database',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 26,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Report List Section
          Expanded(
            child: StreamBuilder(
              stream: _getVerifiedReports(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading reports'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No verified reports found'));
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
                    final adminReason = report['adminReason'] ?? 'No details provided';
                    final threatLevel = report['threatLevel'] ?? 'No details provided';
                    final approvedBy = report['approvedBy'] ?? 'No details provided';

                    return Card(
                      color: Colors.deepPurple[50],
                      margin: const EdgeInsets.all(8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// URL
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
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            /// Admin Explanation "Why" url is suspicious?
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(color: Colors.black),
                                children: [
                                  const TextSpan(
                                    text: 'Admin Reason: ',
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                  ),
                                  TextSpan(
                                    text: adminReason,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            /// Malware Status
                            Row(
                              children: [
                                const Text(
                                  'Malware Status: ',
                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                                ),
                                // const Icon(Icons.cancel, color: Colors.red, size: 20),
                                // const SizedBox(width: 4),
                                const Text(
                                  'Malicious',
                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.red),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            /// Threat Level
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(color: Colors.black),
                                children: [
                                  const TextSpan(
                                    text: 'Threat Level: ',
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                  ),
                                  TextSpan(
                                    text: threatLevel,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: threatLevel == 'high'
                                          ? Colors.red
                                          : threatLevel == 'medium'
                                          ? Colors.orange
                                          : Colors.green,
                                      fontWeight: FontWeight.w800
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),


                            /// Approved By
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

                            /// Added On
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(color: Colors.black),
                                children: [
                                  const TextSpan(
                                    text: 'Added on : ',
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
}
