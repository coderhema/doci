import 'package:flutter/material.dart';
import 'services/storage_service.dart';
import 'account_screen.dart';
import 'home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.getInstance();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: const DocumentScannerPage(),
    );
  }
}

class DocumentScannerPage extends StatefulWidget {
  const DocumentScannerPage({super.key});

  @override
  State<DocumentScannerPage> createState() => _DocumentScannerPageState();
}

class _DocumentScannerPageState extends State<DocumentScannerPage> {
  int _selectedIndex = 0;

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      
    });
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        border: Border(
          top: BorderSide(
            // ignore: deprecated_member_use
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            _selectedIndex == 0 ? Icons.description_rounded : Icons.description_outlined, 
            'Documents', 
            _selectedIndex == 0, 
            () => _onNavItemTapped(0)
          ),
          _buildNavItem(
            _selectedIndex == 1 ? Icons.person : Icons.person_outline, 
            'Account', 
            _selectedIndex == 1, 
            () => _onNavItemTapped(1)
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_selectedIndex == 0) {
      body = HomeScreen(bottomNavigationBar: _buildBottomNav());
    } else if (_selectedIndex == 1) {
      body = const AccountScreen();
    } else {
      body = const SizedBox();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: body,
      bottomNavigationBar: _selectedIndex != 0 ? _buildBottomNav() : null,
    );
  }
}