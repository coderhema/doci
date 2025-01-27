import 'package:flutter/material.dart';
import 'package:flutter_document_scanner/flutter_document_scanner.dart';
import 'dart:typed_data';

class ScanScreen extends StatefulWidget {
  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final DocumentScannerController _controller = DocumentScannerController();

  @override
  void initState() {
    super.initState();
    // Add listeners to the controller
    _controller.statusTakePhotoPage.listen((AppStatus event) {
      print("Changes when taking the picture: $event");
    });

    _controller.statusCropPhoto.listen((AppStatus event) {
      print("Changes while cutting the image: $event");
    });

    _controller.statusEditPhoto.listen((AppStatus event) {
      print("Changes when editing the image: $event");
    });

    _controller.statusSavePhotoDocument.listen((AppStatus event) {
      print("Changes while the document image is being saved: $event");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Document'),
      ),
      body: DocumentScanner(
        controller: _controller,
        onSave: (Uint8List imageBytes) {
          print("image bytes: $imageBytes");
        },
        generalStyles: const GeneralStyles(
          messageTakingPicture: 'Scanning Document',
          messageCroppingPicture: 'Cropping Document',
          messageEditingPicture: 'Editing Document',
          messageSavingPicture: 'Document saved',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
