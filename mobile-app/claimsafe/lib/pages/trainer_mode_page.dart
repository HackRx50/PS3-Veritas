import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BoundingBoxPainter extends CustomPainter {
  final List<Rect> boundingBoxes;
  final int? selectedBoxIndex;

  BoundingBoxPainter({required this.boundingBoxes, this.selectedBoxIndex});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 0; i < boundingBoxes.length; i++) {
      if (selectedBoxIndex == i) {
        paint.color = Colors.blue;
        paint.strokeWidth = 3.0;
      } else {
        paint.color = Colors.red;
        paint.strokeWidth = 2.0;
      }
      canvas.drawRect(boundingBoxes[i], paint);

      if (selectedBoxIndex == i) {
        drawResizeHandles(canvas, boundingBoxes[i]);
      }
    }
  }

  void drawResizeHandles(Canvas canvas, Rect box) {
    const double handleSize = 10.0;
    final Paint handlePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    canvas.drawRect(
        Rect.fromLTWH(box.left - handleSize / 2, box.top - handleSize / 2,
            handleSize, handleSize),
        handlePaint);
    canvas.drawRect(
        Rect.fromLTWH(box.right - handleSize / 2, box.top - handleSize / 2,
            handleSize, handleSize),
        handlePaint);
    canvas.drawRect(
        Rect.fromLTWH(box.left - handleSize / 2, box.bottom - handleSize / 2,
            handleSize, handleSize),
        handlePaint);
    canvas.drawRect(
        Rect.fromLTWH(box.right - handleSize / 2, box.bottom - handleSize / 2,
            handleSize, handleSize),
        handlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class TrainerModePage extends StatefulWidget {
  final Uint8List? outputImageBytes;
  final File? previewImageFile;
  final VoidCallback onSubmit;
  final VoidCallback onToggle;

  const TrainerModePage({
    Key? key,
    this.outputImageBytes,
    this.previewImageFile,
    required this.onSubmit,
    required this.onToggle,
  }) : super(key: key);

  @override
  _TrainerModePageState createState() => _TrainerModePageState();
}

class _TrainerModePageState extends State<TrainerModePage> {
  final List<Rect> boundingBoxes = [];
  bool isDrawing = false;
  Offset startPoint = Offset.zero;
  Offset endPoint = Offset.zero;
  int? selectedBoxIndex;
  bool isResizing = false;
  int? resizeHandleIndex;
  List<String> yoloCoordinates = [];

  void startDrawing(Offset point) {
    setState(() {
      isDrawing = true;
      startPoint = point;
      endPoint = point;
    });
  }

  void updateDrawing(Offset point) {
    if (isDrawing) {
      setState(() {
        endPoint = point;
      });
    }
  }

  void stopDrawing() {
    if (isDrawing) {
      setState(() {
        isDrawing = false;
        boundingBoxes.add(Rect.fromPoints(startPoint, endPoint));
      });
    }
  }

  void selectBoundingBox(Offset point) {
    for (int i = 0; i < boundingBoxes.length; i++) {
      if (boundingBoxes[i].contains(point)) {
        setState(() {
          selectedBoxIndex = i;
        });
        return;
      }
    }
    setState(() {
      selectedBoxIndex = null;
    });
  }

  void removeSelectedBoundingBox() {
    if (selectedBoxIndex != null) {
      setState(() {
        boundingBoxes.removeAt(selectedBoxIndex!);
        selectedBoxIndex = null;
      });
    }
  }

  void startResizing(Offset point) {
    if (selectedBoxIndex != null) {
      Rect box = boundingBoxes[selectedBoxIndex!];
      if (point.dx < box.left + 10 && point.dy < box.top + 10) {
        resizeHandleIndex = 0;
      } else if (point.dx > box.right - 10 && point.dy < box.top + 10) {
        resizeHandleIndex = 1;
      } else if (point.dx < box.left + 10 && point.dy > box.bottom - 10) {
        resizeHandleIndex = 2;
      } else if (point.dx > box.right - 10 && point.dy > box.bottom - 10) {
        resizeHandleIndex = 3;
      }
      setState(() {
        isResizing = resizeHandleIndex != null;
      });
    }
  }

  void updateResizing(Offset point) {
    if (isResizing && selectedBoxIndex != null && resizeHandleIndex != null) {
      setState(() {
        Rect box = boundingBoxes[selectedBoxIndex!];
        switch (resizeHandleIndex) {
          case 0:
            boundingBoxes[selectedBoxIndex!] =
                Rect.fromPoints(point, box.bottomRight);
            break;
          case 1:
            boundingBoxes[selectedBoxIndex!] =
                Rect.fromPoints(box.topLeft, point);
            break;
          case 2:
            boundingBoxes[selectedBoxIndex!] =
                Rect.fromPoints(point, box.topRight);
            break;
          case 3:
            boundingBoxes[selectedBoxIndex!] =
                Rect.fromPoints(box.topLeft, point);
            break;
        }
      });
    }
  }

  void stopResizing() {
    setState(() {
      isResizing = false;
      resizeHandleIndex = null;
    });
  }

  Future<void> displayYOLOCoordinates() async {
    final image = widget.previewImageFile != null
        ? await decodeImageFromList(widget.previewImageFile!.readAsBytesSync())
        : null;

    if (image != null) {
      final imageWidth = image.width.toDouble();
      final imageHeight = image.height.toDouble();

      setState(() {
        yoloCoordinates.clear();
        for (Rect box in boundingBoxes) {
          final centerX = ((box.left + box.right) / 2) / imageWidth;
          final centerY = ((box.top + box.bottom) / 2) / imageHeight;
          final boxWidth = box.width / imageWidth;
          final boxHeight = box.height / imageHeight;

          yoloCoordinates.add(
              'YOLO Format: ${centerX.toStringAsFixed(4)} ${centerY.toStringAsFixed(4)} ${boxWidth.toStringAsFixed(4)} ${boxHeight.toStringAsFixed(4)}');
        }
      });
    }
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
            if (widget.previewImageFile != null)
              GestureDetector(
                onPanStart: (details) {
                  if (selectedBoxIndex != null) {
                    startResizing(details.localPosition);
                  } else {
                    startDrawing(details.localPosition);
                  }
                },
                onPanUpdate: (details) {
                  if (isResizing) {
                    updateResizing(details.localPosition);
                  } else {
                    updateDrawing(details.localPosition);
                  }
                },
                onPanEnd: (_) {
                  if (isResizing) {
                    stopResizing();
                  } else {
                    stopDrawing();
                  }
                },
                onTapUp: (details) => selectBoundingBox(details.localPosition),
                child: Stack(
                  children: [
                    Image.file(
                      widget.previewImageFile!,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: screenHeight * 0.40,
                    ),
                    CustomPaint(
                      size: Size(double.infinity, screenHeight * 0.40),
                      painter: BoundingBoxPainter(
                        boundingBoxes: boundingBoxes,
                        selectedBoxIndex: selectedBoxIndex,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: displayYOLOCoordinates,
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.blue),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                  ),
                  child: Text(
                    'Show YOLO Coordinates',
                    style: GoogleFonts.urbanist(
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: removeSelectedBoundingBox,
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.blue),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                  ),
                  child: Text(
                    'Remove',
                    style: GoogleFonts.urbanist(
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            Expanded(
              child: ListView.builder(
                itemCount: yoloCoordinates.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      yoloCoordinates[index],
                      style: GoogleFonts.inter(
                        textStyle: const TextStyle(
                          fontSize: 14.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20.0),
            Switch(
              value: true, // Trainer mode is on
              onChanged: (bool value) {
                // When toggled off, call onToggle
                if (!value) {
                  widget.onToggle(); // Navigate back to Document Status Page
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
