import 'package:claimsafe/pages/wrapper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Verify extends StatefulWidget {
  const Verify({super.key});

  @override
  State<Verify> createState() => _VerifyState();
}

class _VerifyState extends State<Verify> {
  @override
  void initState() {
    sendverifylink();
    super.initState();
  }

  sendverifylink() async {
    final user = FirebaseAuth.instance.currentUser!;
    await user.sendEmailVerification().then((value) => {
      Get.snackbar('Link sent', 'A link has been sent to your email',
          margin: const EdgeInsets.all(30),
          snackPosition: SnackPosition.BOTTOM)
    });
  }

  reload() async {
    await FirebaseAuth.instance.currentUser!
        .reload()
        .then((value) => {Get.offAll(const Wrapper())});
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 10, 16, 31),
      appBar: AppBar(
        title: const Text(
          'Verification',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 10, 16, 31),
      ),
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.05), // Responsive padding
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Open your mail and click on the link provided to verify your email. Reload this page after verifying.',
                  textAlign: TextAlign.center, // Center align text
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 20),
                Container(
                  width: screenWidth * 0.6, // Responsive container width
                  child: ElevatedButton(
                    onPressed: reload,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(screenWidth * 0.6, 50), // Responsive button size
                      backgroundColor: Colors.white, // Button background color
                    ),
                    child: const Text(
                      'Reload',
                      style: TextStyle(color: Colors.black), // Text color
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
