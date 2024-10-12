import 'package:claimsafe/pages/document_status.dart';
import 'package:claimsafe/pages/history.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);

    if (image != null) {
      setState(() {
        _image = image;
      });
    } else {
      // Handle the case when the user cancels the image picker
      Get.snackbar('No Image Selected', 'You didn\'t select any image.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }

  final user = FirebaseAuth.instance.currentUser;
  signout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 10, 16, 31),
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(left: 50.0),
          child: Text(
            'ClaimSafe',
            style: GoogleFonts.shareTechMono(
              textStyle: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 10, 16, 31),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.history_toggle_off_outlined,
              color: Colors.white,
            ),
            onPressed: () {
              Get.to(() => const HistoryPage());
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
            ),
            onPressed: () => signout(),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.05), // Responsive padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                'Upload a clear image of the document.',
                style: GoogleFonts.poppins(
                  textStyle:
                  const TextStyle(fontSize: 16.0, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            SizedBox(
              width: double.infinity,
              height: screenHeight * 0.35, // Responsive height for image preview
              child: _image != null
                  ? Image.file(
                File(_image!.path),
                fit: BoxFit.contain,
              )
                  : Center(
                child: Text(
                  'Image preview will appear here!',
                  style: GoogleFonts.urbanist(
                      textStyle: const TextStyle(
                          fontSize: 16.0, color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(height: 18.0),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                        const Color(0xFF35383F)), // Background color
                    foregroundColor:
                    MaterialStateProperty.all(Colors.white), // Text color
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate),
                      SizedBox(width: 10.0),
                      Text('Select File'),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () => _pickImage(ImageSource.camera),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                        const Color(0xFF35383F)), // Background color
                    foregroundColor:
                    MaterialStateProperty.all(Colors.white), // Text color
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt),
                      SizedBox(width: 10.0),
                      Text('Open Camera & Take Photo'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 75.0),
            ElevatedButton(
              onPressed: _image != null
                  ? () {
                Get.to(() => DocumentStatusPage(image: _image!));
              }
                  : null,
              style: ButtonStyle(
                backgroundColor:
                MaterialStateProperty.all(Colors.blue), // Background color
                foregroundColor:
                MaterialStateProperty.all(Colors.white), // Text color
              ),
              child: Text('Continue',
                  style: GoogleFonts.urbanist(
                      textStyle: const TextStyle(fontWeight: FontWeight.bold))),
            )
          ],
        ),
      ),
    );
  }
}
