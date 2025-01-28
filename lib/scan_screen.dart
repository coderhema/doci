import 'package:flutter/material.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'models/file_item.dart';

class ScanScreen extends StatefulWidget {
  final bool autoStart;
  const ScanScreen({super.key, this.autoStart = false});
  
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  DocumentScanner? documentScanner;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndInitialize();
  }

  Future<void> _checkPermissionsAndInitialize() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      _initializeScanner();
      // Start scanning immediately after initialization
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          startScan();
        }
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required')),
        );
        Navigator.pop(context);
      }
    }
  }

  void _initializeScanner() {
    final options = DocumentScannerOptions(
      mode: ScannerMode.filter,
      isGalleryImport: false,
      pageLimit: 1,
    );
    documentScanner = DocumentScanner(options: options);
  }

  @override
  void dispose() {
    documentScanner?.close();
    super.dispose();
  }

  Future<void> startScan() async {
    if (_isScanning) return;

    setState(() => _isScanning = true);
    
    try {
      if (documentScanner == null) {
        throw Exception('Document scanner not initialized');
      }
      
      debugPrint('Starting document scan...');
      final result = await documentScanner!.scanDocument();
      debugPrint('Scan result: ${result?.images.length ?? 0} images');
      
      if (result != null && result.images.isNotEmpty) {
        debugPrint('First image path: ${result.images.first}');
        final savedPath = await _saveScannedFile(result.images.first);
        Navigator.pop(context, FileItem(name: path.basename(savedPath), path: savedPath, dateAdded: DateTime.now()));
      } else {
        throw Exception('No images found in the scanning result.');
      }
    } catch (e, stackTrace) {
      debugPrint('Scanning error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scanner Error: ${e.toString()}')),
        );
        Navigator.pop(context);
      }
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Future<String> _saveScannedFile(String originalPath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedPath = path.join(appDir.path, fileName);
    final file = File(originalPath);
    await file.copy(savedPath);
    return savedPath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Scanner'),
        centerTitle: true,
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}