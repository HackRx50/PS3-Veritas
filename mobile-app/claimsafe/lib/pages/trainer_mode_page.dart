import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TrainerModePage extends StatelessWidget {
  final Uint8List? outputImageBytes;
  final File? previewImageFile;
  final VoidCallback onSubmit;
  final VoidCallback onToggle; // Add this callback for toggling

  const TrainerModePage({
    Key? key,
    this.outputImageBytes,
    this.previewImageFile,
    required this.onSubmit,
    required this.onToggle, // Include the new callback in the constructor
  }) : super(key: key);

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
            'Trainer Mode',
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
      ),
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          children: [
            if (previewImageFile != null)
              Column(
                children: [
                  Text(
                    'Preview Image:',
                    style: GoogleFonts.inter(
                      textStyle: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Image.file(
                    previewImageFile!,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: screenHeight * 0.40,
                  ),
                ],
              ),
            const SizedBox(height: 20.0),
            // if (outputImageBytes != null)
            //   Column(
            //     children: [
            //       Text(
            //         'Output Image:',
            //         style: GoogleFonts.inter(
            //           textStyle: const TextStyle(
            //             fontSize: 18.0,
            //             fontWeight: FontWeight.bold,
            //             color: Colors.white,
            //           ),
            //         ),
            //       ),
            //       const SizedBox(height: 10.0),
            //       Image.memory(
            //         outputImageBytes!,
            //         fit: BoxFit.contain,
            //         width: double.infinity,
            //         height: screenHeight * 0.25,
            //       ),
            //     ],
            //   ),
            const SizedBox(height: 30.0),
            ElevatedButton(
              onPressed: onSubmit,
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.blue),
                foregroundColor: MaterialStateProperty.all(Colors.white),
              ),
              child: Text(
                'Submit',
                style: GoogleFonts.urbanist(
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 30.0),
            Switch(
              value: true, // Trainer mode is on
              onChanged: (bool value) {
                // When toggled off, call onToggle
                if (!value) {
                  onToggle(); // Navigate back to Document Status Page
                }
              },
              activeColor: Colors.green,
              activeTrackColor: Colors.greenAccent,
              inactiveThumbColor: Colors.red[100],
              inactiveTrackColor: Colors.red,
            ),
            Text(
              'Trainer Mode',
              style: GoogleFonts.inter(
                textStyle: const TextStyle(
                  fontSize: 16.0,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
