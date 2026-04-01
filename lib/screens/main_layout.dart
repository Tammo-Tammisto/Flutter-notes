import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
// You will create these later:
import 'bookshelf_screen.dart';
import 'todo_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  // The different screens for your sidebar navigation
  final List<Widget> _screens = [
    const DashboardScreen(),
    const BookshelfScreen(), // Placeholder
    const TodoScreen(), // Placeholder
    const Center(child: Text("Calendar Coming Soon")), // Placeholder
    const Center(child: Text("Stickers Coming Soon")), // Placeholder
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The main background color from your design
      backgroundColor: const Color(0xFF9E8DD6),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // SIDEBAR
            Container(
              width: 250,
              decoration: BoxDecoration(
                color: const Color(0xFFFFDFDF), // Light pink
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Placeholder for your Penguin Logo
                  // Make sure to add your image to assets in pubspec.yaml
                  Container(
                    height: 100,
                    width: 150,
                    color: Colors.white54,
                    child: const Center(child: Text("Penguin Image")),
                  ),
                  const SizedBox(height: 40),
                  _buildNavItem(0, "Dashboard"),
                  _buildNavItem(1, "Bookshelf"),
                  _buildNavItem(2, "To-Do list"),
                  _buildNavItem(3, "Calendar"),
                  _buildNavItem(4, "Stickers"),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // MAIN CONTENT AREA
            Expanded(child: _screens[_selectedIndex]),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String title) {
    bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD3B8D8) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              color: isSelected ? Colors.black87 : Colors.black54,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
