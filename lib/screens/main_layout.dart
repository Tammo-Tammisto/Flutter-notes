import 'package:flutter/material.dart';
import 'dart:async';
import 'dashboard_screen.dart';
import 'bookshelf_screen.dart';
import 'todo_screen.dart';
import 'calendar_screen.dart';
import '../services/notification_service.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const BookshelfScreen(),
    const TodoScreen(),
    const CalendarScreen(),
    //const Center(child: Text("Stickers Coming Soon")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF9E8DD6),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // SIDEBAR
            Container(
              width: 250,
              decoration: BoxDecoration(
                color: const Color(0xFFFFDFDF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                // Stretch ensures the timer doesn't cause width calculation errors
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  const Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Text("Logo"),
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildNavItem(0, "Dashboard"),
                  _buildNavItem(1, "Bookshelf"),
                  _buildNavItem(2, "To-Do list"),
                  _buildNavItem(3, "Calendar"),
                  //_buildNavItem(4, "Stickers"),

                  const Spacer(),

                  // THE TIMER WIDGET - Wrapped to prevent overflow
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: SidebarTimer(),
                  ),
                  const SizedBox(height: 20),
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
      onTap: () => setState(() => _selectedIndex = index),
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

class SidebarTimer extends StatefulWidget {
  const SidebarTimer({Key? key}) : super(key: key);

  @override
  State<SidebarTimer> createState() => _SidebarTimerState();
}

class _SidebarTimerState extends State<SidebarTimer> {
  Timer? _timer;
  int _secondsRemaining = 0;
  bool _isRunning = false;
  final TextEditingController _minController = TextEditingController(
    text: "00",
  );

  void _startTimer() {
    if (_secondsRemaining > 0) {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          setState(() => _secondsRemaining--);
        } else {
          _stopTimer();
          // Trigger the Sound and Notification
          StudyAlertService.showAlert();
          _showTimeUpDialog();
        }
      });
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _stopTimer();
    setState(() => _secondsRemaining = 0);
  }

  void _setQuickTime(int minutes) {
    _stopTimer();
    setState(() => _secondsRemaining = minutes * 60);
  }

  void _showTimeUpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Time's Up!"),
        content: const Text("Great study session! Take a break."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  String _formatTime() {
    int mins = _secondsRemaining ~/ 60;
    int secs = _secondsRemaining % 60;
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _timer?.cancel();
    _minController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Prevents infinite height expansion
        children: [
          const Text(
            "STUDY TIMER",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _isRunning ? null : _showSetTimeDialog,
            child: Text(
              _formatTime(),
              style: TextStyle(
                fontSize:
                    32, // Reduced slightly to ensure it fits the 250px sidebar
                fontWeight: FontWeight.bold,
                color: _isRunning ? Colors.deepPurple : Colors.black87,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _isRunning
                    ? Colors.orangeAccent
                    : Colors.greenAccent,
                child: IconButton(
                  iconSize: 18,
                  icon: Icon(
                    _isRunning ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: _isRunning ? _stopTimer : _startTimer,
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[300],
                child: IconButton(
                  iconSize: 18,
                  icon: const Icon(Icons.refresh, color: Colors.black54),
                  onPressed: _resetTimer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [_presetButton(15), _presetButton(25), _presetButton(50)],
          ),
        ],
      ),
    );
  }

  Widget _presetButton(int mins) {
    return InkWell(
      onTap: () => _setQuickTime(mins),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          "${mins}m",
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showSetTimeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Set Minutes"),
        content: TextField(
          controller: _minController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Enter minutes (e.g. 25)",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              int? mins = int.tryParse(_minController.text);
              if (mins != null) setState(() => _secondsRemaining = mins * 60);
              Navigator.pop(context);
            },
            child: const Text("Set"),
          ),
        ],
      ),
    );
  }
}
