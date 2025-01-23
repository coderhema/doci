import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:io';
import 'widgets/animated_fab.dart';
import 'models/file_item.dart';
import 'services/storage_service.dart'; 

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
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No documents here',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.withOpacity(0.5),
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
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            child: Dismissible(
              key: Key(file.path), // Unique key for each file
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const [
                    Icon(Icons.delete, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      'Delete',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
              onDismissed: (direction) {
                _deleteFile(file);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${file.name} deleted')),
                );
              },
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  _openPdfViewer(file.path);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.description, color: Colors.blue),
                      ),
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

  void _deleteFile(FileItem file) {
    setState(() {
      _files.remove(file);
    });
    _storage.saveFiles(_files); // Update storage after deletion
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DOCI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 28),
            onPressed: () {},
          ),
        ],
      ),
      body: _buildFilesList(),
      bottomNavigationBar: widget.bottomNavigationBar,
      floatingActionButton: CustomFAB(
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
    );
  }
}

class AnimatedFileFAB extends StatefulWidget {
  const AnimatedFileFAB({Key? key}) : super(key: key);

  @override
  State<AnimatedFileFAB> createState() => _AnimatedFileFABState();
}

class _AnimatedFileFABState extends State<AnimatedFileFAB> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      // Handle file upload here
      setState(() => _isExpanded = false);
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isExpanded ? 160 : 56,
      height: 56,
      child: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        onPressed: () {
          setState(() {
            _isExpanded = !_isExpanded;
            if (_isExpanded) {
              _animationController.forward();
            } else {
              _animationController.reverse();
            }
          });
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_isExpanded ? Icons.close : Icons.add),
            if (_isExpanded) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: _pickFile,
                child: const Text('Add File', 
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
