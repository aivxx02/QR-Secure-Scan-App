import 'package:cloud_firestore/cloud_firestore.dart';

class FetchReportCount {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  /// Function to fetch Total verified report (Malicious and Safe URL)
  Future<int> fetchVerifiedCount() async {
    try {
      print("Fetching verified reports...");
      final querySnapshot = await FirebaseFirestore.instance
          .collection('maliciousURL')
          .where('verification', whereIn: ['verified', 'rejected']) // Filter verified reports
          .get();

      final approvedDocs = querySnapshot.docs.where((doc) => doc['userEmail'] != 'Added by Admin').toList();

      print("Fetched ${approvedDocs.length} verified by Admin malicious reports.");
      return approvedDocs.length; // Return the count
    } catch (e) {
      print('Error fetching malicious reports: $e');
      return 0; // Return 0 in case of an error
    }
  }

  /// Function to fetch unverified report count (Waiting list to get verified...)
  Future<int> fetchUnverifiedCount() async {
    try {
      print("Fetching unverified reports...");
      final querySnapshot = await FirebaseFirestore.instance
          .collection('maliciousURL')
          .where('verification', isEqualTo: 'none') // Filter unverified reports
          .get();

      print("Fetched ${querySnapshot.docs.length} unverified reports.");
      return querySnapshot.docs.length; // Return the count
    } catch (e) {
      print('Error fetching unverified reports: $e');
      return 0; // Return 0 in case of an error
    }
  }

  /// Function to fetch Total Verified (Malicious URL) report count after verified by Admin.
  Future<int> fetchMaliciousCount() async {
    try {
      print("Fetching malicious reports...");

      final querySnapshot = await FirebaseFirestore.instance
          .collection('maliciousURL')
          .where('verification', isEqualTo: 'verified') // Filter by verification
          .get();

      // Filter userEmail field manually after fetching
      final approvedDocs = querySnapshot.docs.where((doc) => doc['userEmail'] != 'Added by Admin').toList();

      print("Fetched ${approvedDocs.length} verified by Admin malicious reports.");
      return approvedDocs.length; // Return the count
    } catch (e) {
      print('Error fetching malicious reports: $e');
      return 0; // Return 0 in case of an error
    }
  }


  /// Function to fetch Total Rejected (Consider Safe) report after verified by Admin.
  Future<int> fetchRejectedCount() async {
    try {
      print("Fetching rejected reports...");
      final querySnapshot = await FirebaseFirestore.instance
          .collection('maliciousURL')
          .where('verification', isEqualTo: 'rejected') // Filter rejected reports
          .get();

      print("Fetched ${querySnapshot.docs.length} rejected reports (Consider Safe).");
      return querySnapshot.docs.length; // Return the count
    } catch (e) {
      print('Error fetching rejected reports: $e');
      return 0; // Return 0 in case of an error
    }
  }

  /// Function to fetch Total malicious report count include ||verified by admin|| and ||added by admin||
  Future<int> fetchTotalMaliciousCount() async {
    try {
      print("Fetching malicious reports...");
      final querySnapshot = await FirebaseFirestore.instance
          .collection('maliciousURL')
          .where('verification', isEqualTo: 'verified') // Filter malicious reports
          .get();

      print("Fetched ${querySnapshot.docs.length} malicious reports.");
      return querySnapshot.docs.length; // Return the count
    } catch (e) {
      print('Error fetching malicious reports: $e');
      return 0; // Return 0 in case of an error
    }
  }

  /// Function to fetch Total (Malicious URL) report added by Admin.
  Future<int> fetchAddedbyAdmin() async {
    try {
      print("Fetching malicious reports...");
      final querySnapshot = await FirebaseFirestore.instance
          .collection('maliciousURL')
          .where('verification', isEqualTo: 'verified') // Filter malicious reports
          .where('userEmail', isEqualTo: 'Added by Admin') //
          .get();

      print("Fetched ${querySnapshot.docs.length} added by Admin malicious reports.");
      return querySnapshot.docs.length; // Return the count
    } catch (e) {
      print('Error fetching malicious reports: $e');
      return 0; // Return 0 in case of an error
    }
  }

}


