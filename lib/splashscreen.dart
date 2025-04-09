import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_secure_scan/pages/users/scan/homepage.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    // Set a 4-second delay before transitioning to the Homepage with a fade transition
    Future.delayed(const Duration(milliseconds: 4500), () {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const Homepage(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(seconds: 1),
        ),
      );
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.purpleAccent],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lottie animation for the splash screen using 'qr.json'
            Lottie.asset(
              'assets/splashscreen.json',
              width: 200,
              height: 200,
              fit: BoxFit.fill,
            ),
            // const SizedBox(height: 10), // space between json and text
            const Text(
              'QR Secure Scan',
              style: TextStyle(
                fontFamily: 'fromcartoonblocks',
                color: Colors.white,
                fontSize: 50,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
