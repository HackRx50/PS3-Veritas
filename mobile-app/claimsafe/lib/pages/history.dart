import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:get/get.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final databaseRef = FirebaseDatabase.instance.ref('Output');
  List<Map<String, dynamic>> imageHistory = [];
  bool _isLoading = true;

  String getUserId(User user) {
    return user.email!.split('@')[0];
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final userId = getUserId(user);

    try {
      final snapshot = await databaseRef.child(userId).get();
      if (snapshot.exists) {
        final data = snapshot.value;
        imageHistory = _parseData(data);

        // Sort the list by date in descending order
        imageHistory.sort((a, b) {
          DateTime dateA = _parseDate(a['dateTime']);
          DateTime dateB = _parseDate(b['dateTime']);
          return dateB.compareTo(dateA);
        });
      }
    } catch (e) {
      Get.snackbar('Error', '$e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  DateTime _parseDate(dynamic dateTime) {
    if (dateTime is int) {
      return DateTime.fromMillisecondsSinceEpoch(dateTime);
    } else if (dateTime is String) {
      return DateTime.parse(dateTime);
    }
    return DateTime(1970, 1, 1);
  }

  List<Map<String, dynamic>> _parseData(dynamic data) {
    List<Map<String, dynamic>> result = [];
    if (data is Map) {
      data.forEach((key, value) {
        if (value is Map) {
          result.add(Map<String, dynamic>.from(value));
        }
      });
    } else if (data is List) {
      for (var item in data) {
        if (item is Map) {
          result.add(Map<String, dynamic>.from(item));
        }
      }
    }
    return result;
  }

  Future<void> _downloadExcel() async {
    if (await _requestPermission()) {
      try {
        final excel = Excel.createExcel();
        final sheet = excel['Sheet1'];
        sheet.appendRow(['file_name', 'is_forged', 'confidence']);

        for (var item in imageHistory) {
          bool isForged = item['statusMessage'] == 'Forged';
          sheet.appendRow([
            item['imageName'] ?? 'No name',
            isForged ? 'True' : 'False',
            (item['confidenceScore'] as num?)?.toStringAsFixed(2) ?? 'N/A',
          ]);
        }

        String path;
        if (Platform.isAndroid) {
          path = '/storage/emulated/0/Download/History_${DateTime.now().millisecondsSinceEpoch}.xlsx';
        } else {
          final directory = await getDownloadsDirectory();
          path = '${directory!.path}/History_${DateTime.now().millisecondsSinceEpoch}.xlsx';
        }

        final excelFile = File(path);
        await excelFile.writeAsBytes(excel.encode()!);

        _showDownloadDialog(excelFile.path);
      } catch (e) {
        Get.snackbar('Error', 'Failed to download history: $e');
      }
    } else {
      Get.snackbar('Permission Denied', 'Storage permission is required.');
    }
  }

  Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      var status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        status = await Permission.manageExternalStorage.request();
      }
      return status.isGranted;
    }
    return true;
  }

  Future<void> _openFile(String filePath) async {
    final result = await OpenFile.open(filePath);
    if (result.type != ResultType.done) {
      Get.snackbar('Error', 'Failed to open file.');
    }
  }

  void _showDownloadDialog(String filePath) {
    Get.defaultDialog(
      title: 'Download Complete',
      middleText: 'The history file has been downloaded successfully.',
      actions: [
        TextButton(
          onPressed: () {
            Get.back();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Get.back();
            _openFile(filePath);
          },
          child: const Text('Open'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery for responsive design
    final screenSize = MediaQuery.of(context).size;
    final isLargeScreen = screenSize.width > 600; // Adjust threshold as needed
    final cardMargin = isLargeScreen ? EdgeInsets.symmetric(vertical: 16, horizontal: 32) : EdgeInsets.symmetric(vertical: 8, horizontal: 16);
    final titleFontSize = isLargeScreen ? 24.0 : 20.0;
    final subtitleFontSize = isLargeScreen ? 16.0 : 14.0;

    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(left: 70.0),
          child: Text(
            'History',
            style: GoogleFonts.urbanist(
              textStyle: TextStyle(
                fontSize: titleFontSize,
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
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadHistory,
            tooltip: 'Refresh History',
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: _downloadExcel,
            tooltip: 'Download History',
          ),
        ],
      ),
      backgroundColor: const Color.fromARGB(255, 10, 16, 31),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : imageHistory.isEmpty
          ? const Center(
        child: Text(
          'No history found',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      )
          : ListView.builder(
        itemCount: imageHistory.length,
        itemBuilder: (context, index) {
          final item = imageHistory[index];
          return Card(
            margin: cardMargin,
            color: const Color.fromARGB(255, 20, 30, 50),
            child: ListTile(
              leading: item['imageUrl'] != null
                  ? Image.network(
                item['imageUrl'],
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              )
                  : const Icon(
                Icons.image_not_supported,
                color: Colors.grey,
                size: 50,
              ),
              title: Text(
                'Status: ${item['statusMessage'] ?? 'Unknown'}',
                style: GoogleFonts.urbanist(
                    textStyle: TextStyle(
                      color: item['statusMessage'] == 'Forged'
                          ? Colors.red
                          : Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: titleFontSize,
                    )),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Confidence: ${(item['confidenceScore'] as num?)?.toStringAsFixed(2) ?? 'N/A'}%',
                    style: GoogleFonts.urbanist(
                        textStyle: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: subtitleFontSize,
                        )),
                  ),
                  Text(
                    'Image Name: ${item['imageName'] ?? 'No name'}',
                    style: GoogleFonts.urbanist(
                        textStyle: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: subtitleFontSize,
                        )),
                  ),
                  Text(
                    'Date: ${_formatDate(item['dateTime'])}',
                    style: GoogleFonts.urbanist(
                        textStyle: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: subtitleFontSize)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(dynamic dateTime) {
    if (dateTime == null) return 'No date';
    try {
      DateTime parsedDate;
      if (dateTime is int) {
        parsedDate = DateTime.fromMillisecondsSinceEpoch(dateTime);
      } else if (dateTime is String) {
        parsedDate = DateTime.parse(dateTime);
      } else {
        return 'Invalid date';
      }
      return DateFormat('MMM d, y - h:mm a').format(parsedDate);
    } catch (e) {
      return 'Invalid date';
    }
  }
}
