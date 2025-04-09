import 'package:cloud_firestore/cloud_firestore.dart';

class CustomDatabase {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  /// Check if URL is in the custom database (Qr Code from Gallery and Camera Scan)
  Future<bool> isMaliciousUrl(String url) async {
    final QuerySnapshot result = await firestore
        .collection('maliciousURL')
        .where('uRl', isEqualTo: url)
        .where('verification', isEqualTo: 'verified')
        .get();
    return result.docs.isNotEmpty;
  }

  /// Check if URL is in the custom database (User Report Scan)
  Future<bool> isMaliciousUrlUserReport(String url) async {
    final QuerySnapshot result = await firestore
        .collection('maliciousURL')
        .where('uRl', isEqualTo: url)
        .get();
    return result.docs.isNotEmpty;
  }

  /// Add a new malicious URL report to the database (user role)
  Future<void> add_isMaliciousUrl(String userEmail, String url, String details, String? imageUrl) async {
    await firestore.collection('maliciousURL').add({
      'userEmail':userEmail,
      'uRl': url,
      'details': details,
      'imageUrl': imageUrl,
      'reportedAt': Timestamp.now(),
      'threatLevel': '',
      'approvedBy': '',
      'adminReason': '',
      'verification': 'none', // default
    });
  }

  /// Add a new malicious URL report to the database (admin role)
  Future<void> add_isMaliciousUrlAdmin(String url, String details, String? threatlvl, String? approvedBy) async {
    await firestore.collection('maliciousURL').add({
      'userEmail':'Added by Admin',
      'uRl': url,
      'details': ' -',
      'imageUrl': '',
      'reportedAt': Timestamp.now(),
      'threatLevel': threatlvl,
      'approvedBy': approvedBy,
      'adminReason': details,
      'verification': 'verified', // default
    });
  }



}




