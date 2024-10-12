import 'package:claimsafe/pages/wrapper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController confirmPassword = TextEditingController(); // New Controller
  bool _obscureText = true; // Initial state to hide password
  bool _obscureConfirmText = true; // State to hide confirm password

  signup() async {
    // Check if password matches confirm password
    if (password.text != confirmPassword.text) {
      Get.snackbar("Error", "Passwords do not match!");
      return;
    }

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.text, password: password.text);
      Get.offAll(const Wrapper());
    } on FirebaseAuthException catch (e) {
      Get.snackbar("Error", e.code);
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 10, 16, 31),
      appBar: AppBar(
        title: const Text(
          "Signup",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 10, 16, 31),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Signup',
                  style: GoogleFonts.poppins(
                    textStyle: TextStyle(
                      fontSize: screenWidth * 0.06, // Responsive font size
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 50),
                _buildTextField(
                  controller: email,
                  labelText: 'Email',
                ),
                const SizedBox(height: 30),
                _buildPasswordField(),
                const SizedBox(height: 30),
                _buildConfirmPasswordField(),
                const SizedBox(height: 30),
                _buildSignupButton(screenWidth),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String labelText}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: TextFormField(
        cursorColor: Colors.white,
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: const TextStyle(color: Colors.white),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          border: const OutlineInputBorder(),
        ),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: TextFormField(
        cursorColor: Colors.white,
        controller: password,
        obscureText: _obscureText, // Toggle password visibility
        decoration: InputDecoration(
          labelText: 'Password',
          labelStyle: const TextStyle(color: Colors.white),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          suffixIcon: IconButton(
            onPressed: () {
              setState(() {
                _obscureText = !_obscureText; // Toggle visibility
              });
            },
            icon: Icon(
              _obscureText ? Icons.visibility : Icons.visibility_off,
              color: Colors.white,
            ),
          ),
        ),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: TextFormField(
        cursorColor: Colors.white,
        controller: confirmPassword,
        obscureText: _obscureConfirmText, // Toggle confirm password visibility
        decoration: InputDecoration(
          labelText: 'Confirm Password',
          labelStyle: const TextStyle(color: Colors.white),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          suffixIcon: IconButton(
            onPressed: () {
              setState(() {
                _obscureConfirmText = !_obscureConfirmText; // Toggle visibility
              });
            },
            icon: Icon(
              _obscureConfirmText ? Icons.visibility : Icons.visibility_off,
              color: Colors.white,
            ),
          ),
        ),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildSignupButton(double screenWidth) {
    return ElevatedButton(
      onPressed: () => signup(),
      style: ElevatedButton.styleFrom(
        minimumSize: Size(screenWidth * 0.6, 50), // Responsive button size
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: const Text(
        'Register',
        style: TextStyle(color: Colors.black),
      ),
    );
  }
}
