import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'image_select.dart';
import '../../../custom_database.dart';

class QRScanPage extends StatefulWidget {
  const QRScanPage({super.key});

  @override
  State<QRScanPage> createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {

  final CustomDatabase customDatabase = CustomDatabase();
  File? _selectedImage; // Store the selected image file
  final ImagePicker _picker = ImagePicker(); // Image picker instance
  String threatLevel = 'Unknown';


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

  /// Function to pick image from gallery
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });

      // Navigate to the ImageDisplayPage after image is selected
      if (_selectedImage != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageDisplayPage(
              selectedImage: _selectedImage!,
              onCancel: _clearSelectedImage, // Clear image on cancel
            ),
          ),
        );
      }
    } else {
      print('No image selected.');
    }
  }

  void _clearSelectedImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? _controller;
  String _scanResult = '';
  String _scannedUrl = '';
  bool _isLoading = false;
  bool _isScanning = false; // Set to false initially, scanner only starts after button press

  Future<void> scanUrl(String url) async {
    setState(() {
      _isLoading = true;
      _isScanning = false;
      _scannedUrl = url;
    });

    try {
      /// Fetch the threat level from Firestore
      await fetchThreatLevel(_scannedUrl);

      /// Check the custom database first
      bool isMaliciousInCustomDB = await customDatabase.isMaliciousUrl(url);

      if (isMaliciousInCustomDB) {
        setState(() {
          _scanResult = 'Malicious.';
          _isLoading = false;
        });
        return; // Skip the VirusTotal API scan
      }

      /// Proceed with VirusTotal API scan if not found in custom database
      const apiKey = ''; // insert Virus Total API key
      const apiUrl = 'https://www.virustotal.com/vtapi/v2/url/scan';
      const reportUrl = 'https://www.virustotal.com/vtapi/v2/url/report';

      // Scan URL
      final scanResponse = await http.post(
        Uri.parse(apiUrl),
        body: {'apikey': apiKey, 'url': url},
      );

      if (scanResponse.statusCode == 200) {
        final scanData = json.decode(scanResponse.body);
        final scanId = scanData['scan_id'];

        // Polling mechanism to check the scan report
        for (int i = 0; i < 20; i++) {
          await Future.delayed(const Duration(seconds: 3));

          // Get report
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
              return;
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
          _scanResult = 'Try Again in Few Min';
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

  void _onQRViewCreated(QRViewController controller) {
    _controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null && _isScanning) {
        setState(() {
          _isScanning = false;
        });
        _controller?.stopCamera();
        scanUrl(scanData.code!);
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _startScanning() {
    setState(() {
      _isScanning = true;
      _scanResult = '';
      _scannedUrl = '';
    });
    _controller?.resumeCamera();
  }

  void _exitScanner() {
    setState(() {
      _isScanning = false;
      _scanResult = '';
      _scannedUrl = '';
    });
    _controller?.stopCamera();
  }

  // Method to show confirmation dialog
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
                Navigator.of(context).pop();
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
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
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



  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!_isScanning) ...[
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 350,
                    ), // QR code icon
                    color: Colors.deepPurple,
                    onPressed: _startScanning,
                  ),
                  const Text(
                    "TAP TO SCAN",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24, // Adjust font size as needed
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 0), // Add some space between icon and button

              // Hide the ElevatedButton if there's a scan result
              if (_scanResult.isEmpty)
                ElevatedButton(
                  onPressed: _pickImage,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo),
                      const SizedBox(width: 5), // Add spacing between icon and text
                      const Text(
                        'Select QR Image',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
            ],

            if (_isScanning)
              SizedBox(
                height: 350, // Adjust height as needed
                width: 350,
                child: Stack(
                  children: [
                    QRView(
                      key: qrKey,
                      onQRViewCreated: _onQRViewCreated,
                    ),
                    Center(
                      child: Container(
                        width: 350,
                        height: 350,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.deepPurple,
                            width: 4,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.center,
                              child: AnimatedTextKit(
                                animatedTexts: [
                                  FadeAnimatedText(
                                    'Scanning . . .',
                                    textStyle: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.deepPurpleAccent,
                                    ),
                                    duration: const Duration(milliseconds: 1000),
                                  ),
                                ],
                                repeatForever: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10, // Adjust position as needed
                      left: 120, // Adjust position as needed
                      right: 120, // Adjust position as needed
                      child: ElevatedButton(
                        onPressed: _exitScanner,
                        child: const Text(
                          'Exit',
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (!_isScanning && (_scannedUrl.isNotEmpty || _scanResult.isNotEmpty))
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // Center the content vertically
                    crossAxisAlignment: CrossAxisAlignment.center, // Center the content horizontally
                    children: [

                      /// scan result
                      Row(
                        // mainAxisAlignment: MainAxisAlignment.center, // Center both texts horizontally
                        children: [
                          const Text(
                            'Scan Result:',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 22,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          const SizedBox(width: 10), // Add some space between the texts
                          Text(
                            _scanResult,
                            style: TextStyle(
                              color: _scanResult == 'Safe' ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w400,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(width: 10), // Space between scan result and loading indicator
                          if (_isLoading)
                            SizedBox(
                              child: CircularProgressIndicator(),
                              height: 20.0,
                              width: 20.0,
                            ),
                        ],
                      ),

                      /// Display URL
                      Row(
                        // mainAxisAlignment: MainAxisAlignment.center, // Center both texts horizontally
                        children: [
                          const Text(
                            'URL:',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 22,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          const SizedBox(width: 10), // Add some space between the texts

                          Expanded(
                            child: Tooltip(
                              message: _scannedUrl, // Full URL to show in the tooltip
                              child: InkWell(
                                onTap: () => _launchURL(_scannedUrl), // Launch the URL when tapped
                                child: Text(
                                  _scannedUrl, // Display the URL (stored in _scannedUrl)
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic, // Italic text style
                                    fontSize: 20, // Font size of the text
                                    color: Colors.blue, // Blue text color to indicate it's a link
                                    decoration: TextDecoration.underline, // Underlining the text to resemble a hyperlink
                                  ),
                                  overflow: TextOverflow.ellipsis, // Add ellipsis for overflow
                                ),
                              ),
                            ),
                          )
                        ],
                      ),

                      /// threat level
                      Row(
                        children: [
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(color: Colors.black),
                              children: [
                                const TextSpan(
                                  text: 'Threat Level: ',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                                TextSpan(
                                  text: threatLevel == 'Not Available' ? '' : threatLevel,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: threatLevel == 'high'
                                        ? Colors.red
                                        : threatLevel == 'medium'
                                        ? Colors.orange
                                        : threatLevel == 'low'
                                        ? Colors.green
                                        : Colors.black, // Default color for other cases
                                    fontWeight: FontWeight.w500,
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
                        ],
                      ),

                      /// Detected By
                      Row(
                        // mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Detected by:',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 22,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          const SizedBox(width: 10),

                          Text(
                            // Determine the displayed text based on the value of _scanResult
                            _scanResult == 'Safe' || _scanResult == 'Malicious'
                                ? 'Virus Total Scan'
                                : _scanResult == 'Malicious.'
                                ? 'QR Secure Scan'
                                : '',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(width: 10), // Space between scan result and loading indicator
                          if (_isLoading)
                            SizedBox(
                              child: CircularProgressIndicator(),
                              height: 20.0,
                              width: 20.0,
                            ),

                        ],
                      ),

                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

}