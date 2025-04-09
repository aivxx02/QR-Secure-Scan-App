import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../custom_database.dart';

class AddReport extends StatefulWidget {
  const AddReport({super.key});

  @override
  _AddReportState createState() => _AddReportState();
}

class _AddReportState extends State<AddReport> {
  final user = FirebaseAuth.instance.currentUser!;
  final TextEditingController urlController = TextEditingController();
  final TextEditingController detailsController = TextEditingController();

  final CustomDatabase customDatabase = CustomDatabase();


  // New variable to store the selected threatlvl
  String? threatlvl = 'low'; // Default value is 'Low'

  // loading circle
  bool _isLoading = false;

  // TextEditingController check
  bool _isFormValid = false; // Track if the form is valid


  Future<void> submitReport() async {
    // Validate that all fields are filled
    if (urlController.text.isEmpty || detailsController.text.isEmpty) {
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

      // Add the report to the database
      await customDatabase.add_isMaliciousUrlAdmin(
        url,
        detailsController.text,
        threatlvl,  // Pass the selected threatlvl to the database
        user.email!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Report has been added to Database successfully'),
          backgroundColor: (Colors.deepPurple[500]),
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () {},
          ),
        ),
      );

      // Reset form fields
      urlController.clear();
      detailsController.clear();
      setState(() {
        threatlvl = 'low'; // Reset threatlvl to default
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
    urlController.addListener(_validateForm);
    detailsController.addListener(_validateForm);
  }

  @override
  void dispose() {
    // Remove listeners when the widget is disposed
    urlController.removeListener(_validateForm);
    detailsController.removeListener(_validateForm);
    urlController.dispose();
    detailsController.dispose();
    super.dispose();
  }

  void _validateForm() {
    // Validate if all fields are filled and if email is valid
    bool isValid = urlController.text.isNotEmpty &&
        detailsController.text.isNotEmpty;

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
        iconTheme: IconThemeData(
          color: Colors.white,  // Change the back button color to white
        ),
        backgroundColor: Colors.deepPurpleAccent,
        toolbarHeight: 65,
        title: Text(
          'Add Malicious URL',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w200,
            fontSize: 30,
          ),
        ),
      ),
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                      /// Enter complete URL field
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

                      // Radio buttons for Priority
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const Text(
                            'Threat Level: ',
                            style: TextStyle(fontSize: 16),
                          ),

                          /// low
                          Radio<String>(
                            value: 'low',
                            groupValue: threatlvl,
                            onChanged: (value) {
                              setState(() {
                                threatlvl = value;
                              });
                            },
                          ),
                          const Text('low'),

                          /// medium
                          Radio<String>(
                            value: 'medium',
                            groupValue: threatlvl,
                            onChanged: (value) {
                              setState(() {
                                threatlvl = value;
                              });
                            },
                          ),
                          const Text('medium'),

                          /// high
                          Radio<String>(
                            value: 'high',
                            groupValue: threatlvl,
                            onChanged: (value) {
                              setState(() {
                                threatlvl = value;
                              });
                            },
                          ),
                          const Text('high'),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Description
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
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 20),

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
    );
  }
}

