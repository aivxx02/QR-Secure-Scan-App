import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {

  final _emailController = TextEditingController();

  @override
  void dipose() {
    _emailController.dispose();
    super.dispose();
  }

  Future passwordReset() async {
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailController.text.trim());

      showDialog(
        context: context,
        builder: (context) {
          // yes button
          Widget yesButton = TextButton(
            child: const Text("OK"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          );

          return AlertDialog(
            title: const Text(''),
            content: const Text(
              'If you have registered an account, the email will be sent to your email.\n\nCheck your Inbox !',
              textAlign: TextAlign.center,
            ),
            actions: [
              yesButton,
            ],
          );

        },
      );

    } on FirebaseAuthException catch (e) {
      print(e);
      showDialog(
        context: context,
        builder: (context) {
          return const AlertDialog(
            content: Text(
                'Check your Email Address!',
                textAlign: TextAlign.center,
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.deepPurpleAccent,
          elevation: 0,
        ),

        body: Column (
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 25.0),
              child: Text (
                'Enter your Email and we will send you a password reset link :)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(height: 10),

            //email textfield
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.deepPurple),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'Email',
                  fillColor: Colors.grey[200],
                  filled: true,
                ),
              ),
            ),
            const SizedBox(height: 10),

            //resetpassword
            MaterialButton(
              onPressed: passwordReset,
              color: Colors.deepPurpleAccent,
              child: const Text(
                  'Reset Password',
                  style: TextStyle(
                    color: Colors.white
                  ),
              ),
            )

          ],
        )
    );
  }
}