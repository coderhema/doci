import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class CustomFAB extends StatefulWidget {
  final Function(FilePickerResult?) onFilePicked;

  const CustomFAB({
    super.key,
    required this.onFilePicked,
  });

  @override
  State<CustomFAB> createState() => _CustomFABState();
}

class _CustomFABState extends State<CustomFAB> with SingleTickerProviderStateMixin {
  bool isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      isExpanded = !isExpanded;
      if (isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    widget.onFilePicked(result);
    _toggleExpanded();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isExpanded ? 160.0 : 56.0,
      height: 56.0,
      child: Material(
        color: Theme.of(context).primaryColor,
        elevation: 6,
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _toggleExpanded,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  isExpanded ? Icons.close : Icons.add,
                  color: Colors.white,
                ),
                if (isExpanded)
                  Expanded(
                    child: TextButton(
                      onPressed: _pickFile,
                      child: const Text(
                        'Add File',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}