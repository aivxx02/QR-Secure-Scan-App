import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../../custom_database.dart';// Import for URL launching

class ImageDisplayPage extends StatefulWidget {
  final File selectedImage;
  final VoidCallback onCancel;

  const ImageDisplayPage({
    Key? key,
    required this.selectedImage,
    required this.onCancel,
  }) : super(key: key);

  @override
  _ImageDisplayPageState createState() => _ImageDisplayPageState();
}

class _ImageDisplayPageState extends State<ImageDisplayPage> {

  String threatLevel = 'Unknown';
  String _qrCodeResult = '';
  String _scannedUrl = '';
  bool _isProcessing = true; // Track processing state
  bool _isLoading = false; // Track loading state for scanning
  String _scanResult = ''; // Result of the URL scan

  final CustomDatabase customDatabase = CustomDatabase();

  @override
  void initState() {
    super.initState();
    _extractQrCodeFromImage();
  }

  Future<void> fetchThreatLevel(String url) async {
    try {
      // Query the Firestore collection to find the document where 'url' matches _scannedUrl
      final querySnapshot = await FirebaseFirestore.instance
          .collection('maliciousURL')
          .where('uRl', isEqualTo: url)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Document found, retrieve the threat level
        final document = querySnapshot.docs.first;
        final threatLevel = document['threatLevel']; // Assuming 'threatLevel' is the field name

        setState(() {
          this.threatLevel = threatLevel ?? 'Unknown'; // Assign the threat level or 'Unknown' if not available
        });
      } else {
        setState(() {
          this.threatLevel = 'Not Available'; // No matching document found
        });
      }
    } catch (e) {
      setState(() {
        this.threatLevel = 'Error fetching data'; // Handle error
      });
      print('Error fetching threat level: $e');
    }
  }


  Future<void> _extractQrCodeFromImage() async {
    final inputImage = InputImage.fromFile(widget.selectedImage);
    final barcodeScanner = GoogleMlKit.vision.barcodeScanner();

    try {
      // Use a timeout for processing
      await Future.any([
        barcodeScanner.processImage(inputImage),
        Future.delayed(const Duration(seconds: 5)), // Set timeout duration
      ]).then((value) async {
        if (value is List<Barcode> && value.isNotEmpty) {
          setState(() {
            _qrCodeResult = value.first.rawValue ?? 'QR code data not found';
            _scannedUrl = _qrCodeResult;
            _isProcessing = false;
            _isLoading = true;
          });

          // Fetch the threat level from Firestore
          await fetchThreatLevel(_scannedUrl);

          // Check the URL in the custom database
          bool isMaliciousInCustomDB = await customDatabase.isMaliciousUrl(_scannedUrl);
          if (isMaliciousInCustomDB) {
            setState(() {
              _scanResult = 'Malicious.';
              _isLoading = false;
            });
          } else {
            await _scanUrl(_scannedUrl); // Scan the URL using VirusTotal
          }
        } else {
          setState(() {
            _qrCodeResult = 'QR code not found';
            _scanResult = 'QR code not found';
            _isProcessing = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _qrCodeResult = 'Error: $e';
        _isProcessing = false;
      });
    } finally {
      await barcodeScanner.close();
    }
  }

  Future<void> _scanUrl(String url) async {
    const apiKey = ''; // insert Virus Total API key
    const apiUrl = 'https://www.virustotal.com/vtapi/v2/url/scan';
    const reportUrl = 'https://www.virustotal.com/vtapi/v2/url/report';

    setState(() {
      _isLoading = true;
      _scanResult = ''; // Reset scan result to display new scan
    });

    try {
      // Send scan request to VirusTotal
      final scanResponse = await http.post(
        Uri.parse(apiUrl),
        body: {'apikey': apiKey, 'url': url},
      );

      if (scanResponse.statusCode == 200) {
        final scanData = json.decode(scanResponse.body);
        final scanId = scanData['scan_id'];

        // Polling mechanism for the scan report
        for (int i = 0; i < 20; i++) {
          await Future.delayed(const Duration(seconds: 3));

          // Get the scan report
          final reportResponse = await http.get(
            Uri.parse('$reportUrl?apikey=$apiKey&resource=$scanId'),
          );

          if (reportResponse.statusCode == 200) {
            final reportData = json.decode(reportResponse.body);
            if (reportData['response_code'] == 1) {
              final positives = reportData['positives'];
              setState(() {
                _scanResult = positives > 0 ? 'Malicious' : 'Safe';
                _isLoading = false;
              });
              return; // Exit if the scan result is available
            }
          } else {
            setState(() {
              _scanResult = 'Failed to get report';
              _isLoading = false;
            });
            return;
          }
        }
        setState(() {
          _scanResult = 'Scan timed out. Please try again.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _scanResult = 'Failed to scan URL';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _scanResult = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  void _clearInput() {
    setState(() {
      _scanResult = '';
      _scannedUrl = '';
      _isLoading = false;
    });
  }

  Future<void> _showConfirmationDialog(String url) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Warning'),
          content: const Text(
              'This link is malware detected. Are you sure you want to access the page?'),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Proceed',
                style: TextStyle(color: Colors.redAccent),
              ),
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog first

                final Uri url0 = Uri.parse(url);
                if (await canLaunchUrl(url0)) {
                  await launchUrl(url0, mode: LaunchMode.externalApplication);
                } else {
                  throw 'Could not launch $url0';
                }
              },
            ),
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop(); // Just close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white, //change your color here
        ),
        automaticallyImplyLeading: true, // hide back button
        backgroundColor: Colors.deepPurpleAccent,
        toolbarHeight: 65,
        title: Text(
          'Scan QR Image',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w300,
            fontSize: 25,
          ),
        ),
      ),
      backgroundColor: Colors.grey[300],
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// Image Display Section
                  if (widget.selectedImage != null)
                    Container(
                      height: 300,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey[300], // Add a background color for better visibility
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: FittedBox(
                          fit: BoxFit.contain, // Adjusts image size while maintaining aspect ratio
                          child: Image.file(widget.selectedImage),
                        ),
                      ),
                    ),

                  const SizedBox(height: 22),

                  /// Scan Result Section
                  Row(
                    children: [
                      // "Scan Result:" Text
                      const Text(
                        'Scan Result :',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6), // Add spacing between label and result

                      // The Scan Result value with color depending on its value
                      Text(
                        _scanResult,
                        style: TextStyle(
                          fontSize: 22,
                          color: _scanResult == 'Safe' ? Colors.green : Colors.red,
                        ),
                      ),

                      // Add a loading indicator if _isLoading is true
                      if (_isLoading)
                        const SizedBox(
                          height: 20.0,
                          width: 20.0,
                          child: CircularProgressIndicator(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  /// URL Section
                  Row(
                    children: [
                      // "URL:" Text
                      const Text(
                        'URL :',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6), // Add spacing between label and URL

                      // Wrap the URL in an Expanded widget to allow wrapping
                      Expanded(
                        child: Tooltip(
                          message: _scannedUrl, // Full URL to show in the tooltip
                          child: InkWell(
                            onTap: () => _launchURL(_scannedUrl),
                            child: Text(
                              _scannedUrl,
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 20,
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                              overflow: TextOverflow.ellipsis, // Optionally add ellipsis for overflow
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  /// threat level
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black),
                      children: [
                        const TextSpan(
                          text: 'Threat Level: ',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                        ),
                        TextSpan(
                          text: threatLevel == 'Not Available' ? '' : threatLevel,
                          style: TextStyle(
                            fontSize: 20,
                            color: threatLevel == 'high'
                                ? Colors.red
                                : threatLevel == 'medium'
                                ? Colors.orange
                                : threatLevel == 'low'
                                ? Colors.green
                                : Colors.black, // Default color for other cases
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (threatLevel == 'Not Available' || threatLevel == '')
                          const TextSpan(
                            text: ' (Not Available)',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                              fontSize: 15,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  /// Detected By
                  Row(
                    children: [
                      // "Detected By:" Text
                      const Text(
                        'Detected By :',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6), // Spacing between label and result

                      // The source of detection based on _scanResult
                      Text(
                        _scanResult == 'Safe' || _scanResult == 'Malicious'
                            ? 'Virus Total Scan'
                            : _scanResult == 'Malicious.'
                            ? 'QR Secure Scan'
                            : '',
                        style: const TextStyle(
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),



                ],
              ),
            ),
          ),

          // Loading spinner with blur effect
          if (_isLoading)
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
                const Center(
                  child: CircularProgressIndicator(),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    // Check if the URL has a scheme (http:// or https://), if not, prepend 'https://'
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    final Uri url0 = Uri.parse(url);
    print('Attempting to launch URL: $url0');

    try {
      if (_scanResult == 'Malicious' || _scanResult == 'Malicious.') {
        await _showConfirmationDialog(url);
      } else {
        if (await canLaunchUrl(url0)) {
          await launchUrl(url0, mode: LaunchMode.externalApplication);
          print('Launched URL: $url0');
        } else {
          print('Could not launch $url0');
          throw 'Could not launch $url0';
        }
      }
    } catch (e) {
      print('Exception occurred: $e');
    }
  }



}
