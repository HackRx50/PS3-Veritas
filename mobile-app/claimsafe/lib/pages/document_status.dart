import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:claimsafe/pages/history.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

String getUserId(User user) {
  return user.email!.split('@')[0];
}

Future<String?> uploadImageToFirebase(XFile image) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final userId = getUserId(user);
    final storageRef =
        FirebaseStorage.instance.ref().child('images/$userId/${image.name}');
    final uploadTask = storageRef.putFile(File(image.path));
    final snapshot = await uploadTask;

    return await snapshot.ref.getDownloadURL();
  } catch (e) {
    return null;
  }
}

int userNo = 0;

Future<void> storeImageMetadata(String imageUrl, String imageName,
    String statusMessage, double confidenceScore, String outputImage) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final userId = getUserId(user);
    final databaseRef = FirebaseDatabase.instance.ref();
    final path = 'Output/$userId/$userNo';
    final dateTime = DateTime.now();

    await databaseRef.child(path).set({
      'imageUrl': imageUrl,
      'imageName': imageName,
      'statusMessage': statusMessage,
      'confidenceScore': confidenceScore * 100,
      'dateTime': dateTime.toIso8601String(),
      'outputImage': outputImage,
    });

    userNo++;
  }
}

class DocumentStatusPage extends StatefulWidget {
  final XFile? image;
  const DocumentStatusPage({super.key, this.image});

  @override
  State<DocumentStatusPage> createState() => _DocumentStatusPageState();
}

class _DocumentStatusPageState extends State<DocumentStatusPage> {
  String? statusMessage;
  double? confidenceScore;
  Uint8List? outputImageBytes;
  bool isLoading = false;
  bool isTrainerMode = false;
  final TextEditingController passwordController = TextEditingController();

  Future<File> compressImage(File file) async {
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      '${file.path}_compressed.jpg',
      quality: 85,
    );
    return result ?? file;
  }

  Future<void> detectForgery() async {
    if (widget.image == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      File compressedImage = await compressImage(File(widget.image!.path));

      final uri = Uri.parse('http://10.19.10.78:5000/detect-forgery');
      final request = http.MultipartRequest('POST', uri)
        ..files.add(
            await http.MultipartFile.fromPath('image', compressedImage.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = jsonDecode(responseBody);

        setState(() {
          statusMessage = data['forgery_detected'] ? 'Forged' : 'Authentic';
          confidenceScore = data['confidence'];

          if (data.containsKey('output_image') &&
              data['output_image'] != null) {
            outputImageBytes = base64Decode(data['output_image']);
          } else {
            statusMessage = 'Output image is not available';
          }
        });

        final imageUrl = await uploadImageToFirebase(widget.image!);
        if (imageUrl != null) {
          final outputImage = data['output_image'] ?? '';
          await storeImageMetadata(imageUrl, widget.image!.name, statusMessage!,
              confidenceScore!, outputImage);
        } else {
          throw Exception('Image upload failed');
        }
      } else {
        throw Exception('Failed to detect forgery');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        statusMessage = 'Error detecting forgery';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> showTrainerModeDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 10, 16, 31),
          title: Text(
            'Enter Trainer Mode',
            style: GoogleFonts.inter(
              textStyle: const TextStyle(
                color: Colors.white,
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Please enter your password to enable Trainer Mode.',
                style: GoogleFonts.inter(
                  textStyle: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20.0),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (passwordController.text == "123") {
                  Navigator.of(context).pop();
                } else {
                  passwordController.clear();
                  Get.snackbar(
                    'Error',
                    'Incorrect Password',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              },
              child: const Text('Submit', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  void toggleTrainerMode(bool value) {
    setState(() {
      isTrainerMode = value;
      if (isTrainerMode) {
        showTrainerModeDialog();
      }
    });
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
        iconTheme: const IconThemeData(color: Colors.white),
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
            onPressed: (() => signout()),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          children: [
            if (outputImageBytes != null)
              Image.memory(
                outputImageBytes!,
                fit: BoxFit.contain,
                width: double.infinity,
                height: screenHeight * 0.35,
              )
            else if (widget.image != null)
              Image.file(
                File(widget.image!.path),
                fit: BoxFit.contain,
                width: double.infinity,
                height: screenHeight * 0.35,
              ),
            const SizedBox(height: 30.0),
            if (isLoading)
              const CircularProgressIndicator()
            else if (statusMessage != null)
              Column(
                children: [
                  Text(
                    'Status: $statusMessage',
                    style: GoogleFonts.inter(
                        textStyle: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color:
                          statusMessage == 'Forged' ? Colors.red : Colors.green,
                    )),
                  ),
                  const SizedBox(height: 10),
                  if (confidenceScore != null)
                    Text(
                      'Confidence: ${(confidenceScore! * 100).toStringAsFixed(2)}%',
                      style: GoogleFonts.inter(
                          textStyle: const TextStyle(
                              fontSize: 16.0, color: Colors.white)),
                    ),
                ],
              )
            else
              const Text(
                'No result yet',
                style: TextStyle(fontSize: 16.0, color: Colors.white),
              ),
            const SizedBox(height: 30.0),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: detectForgery,
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(Colors.blue),
                    foregroundColor: WidgetStateProperty.all(Colors.white),
                  ),
                  child: Text('Submit for Forgery Detection',
                      style: GoogleFonts.urbanist(
                          textStyle:
                              const TextStyle(fontWeight: FontWeight.bold))),
                ),
                const SizedBox(height: 70.0),
                ElevatedButton(
                    onPressed: () {
                      Get.back();
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.blue),
                      foregroundColor: WidgetStateProperty.all(Colors.white),
                    ),
                    child: Text('Upload Another Image',
                        style: GoogleFonts.urbanist(
                            textStyle:
                                const TextStyle(fontWeight: FontWeight.bold)))),
                const SizedBox(height: 30.0),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Switch(
                      value: isTrainerMode,
                      onChanged: toggleTrainerMode,
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
