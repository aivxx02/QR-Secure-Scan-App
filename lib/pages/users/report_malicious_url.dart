import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../custom_database.dart';
import '../../SMTPEmail.dart';

class ReportMaliciousUrlPage extends StatefulWidget {
  const ReportMaliciousUrlPage({super.key});

  @override
  _ReportMaliciousUrlPageState createState() => _ReportMaliciousUrlPageState();
}

class _ReportMaliciousUrlPageState extends State<ReportMaliciousUrlPage> {
  final TextEditingController userEmailController = TextEditingController();
  final TextEditingController urlController = TextEditingController();
  final TextEditingController detailsController = TextEditingController();
  XFile? imageFile;

  final ImagePicker picker = ImagePicker();
  final CustomDatabase customDatabase = CustomDatabase();

  // Flag to track if an image has been uploaded
  bool isImageUploaded = false;

  // loading circle
  bool _isLoading = false;

  // TextEditingController check
  bool _isFormValid = false; // Track if the form is valid


  Future<void> pickImage() async {
    if (userEmailController.text.isNotEmpty && urlController.text.isNotEmpty && detailsController.text.isNotEmpty) {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          imageFile = pickedFile;
          isImageUploaded =
              true; // Set the flag to true when an image is uploaded
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: const Text('Please fill in the URL and details first'),
            backgroundColor: (Colors.deepPurple[500]),
            action: SnackBarAction(
              label: 'Dismiss',
              onPressed: () {},
            ),
        ),
      );
    }
  }

  void removeImage() {
    setState(() {
      imageFile = null; // Reset the image file
      isImageUploaded = false; // Reset the flag when the image is removed
    });
  }

  Future<void> submitReport() async {
    // Validate that all fields are filled
    if (userEmailController.text.isEmpty ||
        urlController.text.isEmpty ||
        detailsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in all fields before submitting.'),
          backgroundColor: (Colors.deepPurple[500]),
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () {},
          ),
        ),
      );
      return; // Exit the function if validation fails
    }

    setState(() {
      _isLoading = true; // Start the loading indicator
    });

    try {
      String url = urlController.text;

      // Check if the URL is already reported as malicious
      bool isMalicious = await customDatabase.isMaliciousUrlUserReport(url);
      if (isMalicious) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('This URL is already reported as malicious.'),
            backgroundColor: (Colors.deepPurple[500]),
            action: SnackBarAction(
              label: 'Dismiss',
              onPressed: () {},
            ),
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      String? imageUrl;
      if (imageFile != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('reports/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await storageRef.putFile(File(imageFile!.path));
        imageUrl = await storageRef.getDownloadURL();
      }

      // Add the report to the database
      await customDatabase.add_isMaliciousUrl(
        userEmailController.text,
        url,
        detailsController.text,
        imageUrl,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Report has been submitted successfully'),
          backgroundColor: (Colors.deepPurple[500]),
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () {},
          ),
        ),
      );

      // Send Report Details to User by Email
      await sendReportReviewMail(userEmailController.text, url, detailsController.text);

      // Reset form fields
      userEmailController.clear();
      urlController.clear();
      detailsController.clear();
      setState(() {
        imageFile = null;
        isImageUploaded = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      // Stop the loading indicator
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    // Add listeners to the text controllers
    userEmailController.addListener(_validateForm);
    urlController.addListener(_validateForm);
    detailsController.addListener(_validateForm);
  }

  @override
  void dispose() {
    // Remove listeners when the widget is disposed
    userEmailController.removeListener(_validateForm);
    urlController.removeListener(_validateForm);
    detailsController.removeListener(_validateForm);
    userEmailController.dispose();
    urlController.dispose();
    detailsController.dispose();
    super.dispose();
  }

  /// validate email
  bool _isValidEmail(String email) {
    final RegExp emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegExp.hasMatch(email);
  }

  void _validateForm() {
    // Validate if all fields are filled and if email is valid
    bool isValid = userEmailController.text.isNotEmpty &&
        urlController.text.isNotEmpty &&
        detailsController.text.isNotEmpty &&
        _isValidEmail(userEmailController.text);
        // &&
        // _isValidUrl(urlController.text);

    // Update the form validation state
    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                // title
                const Text(
                  'Report Malicious URL',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 32,
                  ),
                ),
                const SizedBox(height: 50),

                Padding(
                  padding: const EdgeInsets.only(left: 18, right: 18),
                  child: Container(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: Column(
                      children: [

                        /// enter user email
                        TextField(
                          controller: userEmailController,
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.white),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  const BorderSide(color: Colors.deepPurple),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            hintText: 'Enter User Email',
                            fillColor: Colors.grey[200],
                            filled: true,
                          ),
                        ),
                        const SizedBox(height: 16),

                        /// enter complete URL field
                        TextField(
                          controller: urlController,
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.white),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  const BorderSide(color: Colors.deepPurple),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            hintText: 'Enter Valid URL',
                            fillColor: Colors.grey[200],
                            filled: true,
                          ),
                        ),
                        const SizedBox(height: 16),

                        /// Description
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            TextField(
                              controller: detailsController,
                              maxLength: 50, // Optional: Set a character limit
                              decoration: InputDecoration(
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Colors.white),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Colors.deepPurple),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                hintText: 'Describe Why Is It Malicious?',
                                fillColor: Colors.grey[200],
                                filled: true,
                                counterText: '', // Hide default counter text
                              ),
                              maxLines: 3,
                              onChanged: (text) {
                                setState(() {}); // Update the UI for the character count
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 12, bottom: 8),
                              child: Text(
                                '${detailsController.text.length}/50',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        /// upload additional proof
                        if (imageFile != null)
                          Column(
                            children: [
                              Text(
                                'Uploaded Image: ${imageFile!.name}',
                                // Display the image file name
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                label: const Text('Remove Picture',
                                    style: TextStyle(color: Colors.red)),
                                onPressed: removeImage,
                              ),
                            ],
                          ),
                        // const SizedBox(height: 5),

                        // Show the upload button only if no image is uploaded
                        if (!isImageUploaded)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 8.0),
                            child: TextButton.icon(
                              icon: const Icon(Icons.add_a_photo),
                              label: const Text(
                                  'Upload additional proof',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16
                                ),
                              ),
                              onPressed: pickImage,
                            ),
                          ),
                        const SizedBox(height: 30),

                        /// submit report button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: _isLoading
                              ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.deepPurpleAccent,
                            ),
                          )
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Use Expanded to make the button flexible
                              Expanded(
                                child: GestureDetector(
                                  onTap: _isFormValid ? submitReport : null, // Disable if form is not valid
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: _isFormValid
                                          ? Colors.deepPurpleAccent
                                          : Colors.grey, // Change color if disabled
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'Submit Report',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w300,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Tooltip Icon with Flexible size
                              if (!_isFormValid)
                                Flexible(
                                  child: Tooltip(
                                    message: 'Click for more info',
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.info_outline,
                                        color: Colors.redAccent,
                                      ),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: const Text('Submit Button Disable?'),
                                              content: const Text(
                                                'If the submit button is disabled, please check the following:\n\n'
                                                    '- Ensure your email is valid & no space between.\n\n'
                                                    '- Fill in the valid URL. e.g: example.com, www.example.org, https://example.com\n\n'
                                                    '- Provide a description with maximum 50 characters.\n\n'
                                                    '- Upload Image is **OPTIONAL',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: const Text('Close'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
