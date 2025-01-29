import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:io';
import 'scan_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'main.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'widgets/animated_fab.dart';
import 'models/file_item.dart';
import 'services/storage_service.dart'; 
import 'package:path/path.dart' as path;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class HomeScreen extends StatefulWidget {
  final Widget bottomNavigationBar;
  
  const HomeScreen({
    super.key,
    required this.bottomNavigationBar,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late StorageService _storage;
  final List<FileItem> _files = [];

  @override
  void initState() {
    super.initState();
    _initStorage();
  }

  Future<void> _initStorage() async {
    _storage = await StorageService.getInstance();
    _loadSavedFiles();
  }

  Future<void> _loadSavedFiles() async {
    final savedFiles = await _storage.loadFiles();
    setState(() {
      _files.addAll(savedFiles);
    });
  }

  Future<void> addFile(FileItem file) async {
    setState(() {
      _files.add(file);
    });
    await _storage.saveFiles(_files);
  }

  Widget _buildEmptyState() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.surfaceBright.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No documents here',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.surfaceBright.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilesList() {
    if (_files.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _files.length,
      itemBuilder: (context, index) {
        final file = _files[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Material(
            color: const Color.fromARGB(255, 4, 4, 4),
            borderRadius: BorderRadius.circular(12),
            child: Dismissible(
              key: Key(file.path), // Unique key for each file
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.delete, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      'Delete',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
              onDismissed: (_) => _deleteFile(file),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _openFile(file),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      _buildFileIcon(file.path),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              file.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Added ${file.dateAdded.toString().split(' ')[0]}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openPdfViewer(String filePath) {
    final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

    if (File(filePath).existsSync()) {
      debugPrint('Opening PDF at path: $filePath');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
          title: Text(File(filePath).uri.pathSegments.last),
          actions: [
            IconButton(
                icon: SvgPicture.asset(
                'assets/icons/book_4_spark_24px.svg',
                width: 24,
                height: 24,
                ),
              onPressed: () async {
                try {
                  // Load the PDF document
                  final PdfDocument document = PdfDocument(inputBytes: File(filePath).readAsBytesSync());
                  // Extract text
                  String text = PdfTextExtractor(document).extractText();
                  document.dispose();
                  
                  if (mounted) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20))
                      ),
                      builder: (context) => DraggableScrollableSheet(
                      initialChildSize: 0.4,
                      minChildSize: 0.2,
                      maxChildSize: 0.8,
                      expand: false,
                      builder: (context, scrollController) => Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                        children: [
                          Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                          ),
                          Expanded(
                          child: SingleChildScrollView(
                            controller: scrollController,
                            child: Text(
                            text.isEmpty 
                              ? 'No text found in PDF' 
                              : text,
                            style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          ),
                        ],
                        ),
                      ),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to extract text: $e')),
                  );
                }
              },
            ),
          ],
        ),
            body: SfPdfViewer.file(
              File(filePath),
              key: _pdfViewerKey,
              onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                debugPrint('PDF load failed: ${details.error}');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to load PDF: ${details.error}')),
                );
              },
              onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                debugPrint('PDF loaded successfully');
              },
            ),
          ),
        ),
      );
    } else {
      debugPrint('File not found at path: $filePath');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File not found: $filePath')),
      );
    }
  }

  void _openFile(FileItem file) {
    final extension = path.extension(file.path).toLowerCase();
    if (extension == '.pdf') {
      _openPdfViewer(file.path);
    } else if (['.jpg', '.jpeg', '.png'].contains(extension)) {
      _openImageViewer(file.path);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unsupported file type')),
      );
    }
  }

  void _openImageViewer(String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(path.basename(imagePath)),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.file(File(imagePath)),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              try {
                // Initialize text recognizer
                final textRecognizer = TextRecognizer();
                final inputImage = InputImage.fromFilePath(imagePath);
                
                // Process the image
                final recognizedText = await textRecognizer.processImage(inputImage);
                await textRecognizer.close();

                if (mounted) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true, // Makes the sheet larger
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20))
                    ),
                    builder: (context) => DraggableScrollableSheet(
                      initialChildSize: 0.4,
                      minChildSize: 0.2,
                      maxChildSize: 0.8,
                      expand: false,
                      builder: (context, scrollController) => Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Container(
                              width: 40,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                controller: scrollController,
                                child: Text(
                                  recognizedText.text.isEmpty 
                                    ? 'No text found in image' 
                                    : recognizedText.text,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to extract text: $e')),
                  );
                }
              }
            },
            child: SvgPicture.asset(
              'assets/icons/book_4_spark_24px.svg',
              width: 24,
              height: 24,
            ),
            tooltip: 'Extract Text from Image',
          ),
        ),
      ),
    );
  }

  Widget _buildFileIcon(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    IconData iconData;
    Color iconColor = Theme.of(context).colorScheme.primary;

    switch (extension) {
      case '.pdf':
        iconData = Icons.picture_as_pdf;
        break;
      case '.jpg':
      case '.jpeg':
      case '.png':
        iconData = Icons.image;
        break;
      default:
        iconData = Icons.description;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: iconColor),
    );
  }

  Future<void> _deleteFile(FileItem file) async {
    final bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete ${file.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (confirmDelete && mounted) {
      try {
        final fileToDelete = File(file.path);
        if (await fileToDelete.exists()) {
          await fileToDelete.delete();
        }
        setState(() => _files.remove(file));
        await _storage.saveFiles(_files);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting file: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DOCI'),
        actions: [
          PopupMenuButton(
            tooltip: 'More Options',
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 1,
                child: Text('Paste Document URL'),
              ),
            ],
            onSelected: (value) {
              if (value == 1) {
                showDialog(
                  context: context,
                  builder: (context) {
                    final urlController = TextEditingController();
                    return AlertDialog(
                      title: const Text('Paste Document URL'),
                      content: TextField(
                        controller: urlController,
                        decoration: const InputDecoration(
                          hintText: 'Enter document URL',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            final url = urlController.text.trim();
                            if (url.isNotEmpty) {
                              // Handle the URL here
                              debugPrint('Document URL: $url');
                            }
                            Navigator.pop(context);
                          },
                          child: const Text('Add'),
                        ),
                      ],
                    );
                  },
                );
              }
            },
          ),
        ],
      ),
      body: _buildFilesList(),
      bottomNavigationBar: widget.bottomNavigationBar,
      floatingActionButton: Align(
        alignment: Alignment.bottomRight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton(
              onPressed: () async {
                try {
                  final FileItem? scannedFile = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ScanScreen(autoStart: true)),
                  );
                  if (scannedFile != null && mounted) {
                    addFile(scannedFile);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              tooltip: 'Scan Document',
              child: SvgPicture.asset(
              'assets/icons/scan_24px.svg',
              width: 24,
              height: 24,
            ),
            ),
            const SizedBox(height: 16),
            CustomFAB(
              onFilePicked: (result) {
                if (result != null) {
                  addFile(FileItem(
                    name: result.files.first.name,
                    path: result.files.first.path!,
                    dateAdded: DateTime.now(),
                  ));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}