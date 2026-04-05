import 'package:flutter/material.dart';
import 'dart:async';
import '../services/database_helper.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _todayTasks = [];
  List<Map<String, dynamic>> _recentActivity = [];
  Timer? _refreshTimer; // Added
  String _lastDate = ""; // Added

  @override
  void initState() {
    super.initState();
    _lastDate = _getDateString(); // Added
    _loadDashboardData();
    _startTimer(); // Added
  }

  @override
  void dispose() {
    _refreshTimer?.cancel(); // Added
    super.dispose();
  }

  String _getDateString() {
    DateTime now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  void _startTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      String currentDate = _getDateString();
      if (currentDate != _lastDate) {
        _lastDate = currentDate;
        _loadDashboardData();
      }
    });
  }

  Future<void> _loadDashboardData() async {
    String dateStr = _getDateString();
    final tasks = await _dbHelper.getTasksForDate(dateStr);
    final activity = await _dbHelper.getRecentActivity();

    setState(() {
      _todayTasks = tasks;
      _recentActivity = activity;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // LEFT SIDE: Pinned Notes & Today's Calendar Tasks
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TOP ROW: Pinned Note Cards (Placeholders)
              Row(
                children: [
                  _buildTopCard(
                    const Color(0xFFD6B5D8),
                    "Title space",
                    "Lorem ipsum dolor sit amet...",
                  ),
                  const SizedBox(width: 16),
                  _buildTopCard(
                    const Color(0xFFD6B5D8),
                    "",
                    "Something important..",
                    isImageCard: true,
                  ),
                  const SizedBox(width: 16),
                  _buildTopCard(const Color(0xFFD6B5D8), "", ""),
                  const SizedBox(width: 16),
                  _buildTopCard(const Color(0xFFD6B5D8), "", ""),
                ],
              ),
              const SizedBox(height: 16),

              // TODAY'S CALENDAR TASKS PANEL
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF7F76B3,
                    ), // Your original purple theme
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Today's Schedule",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _todayTasks.isEmpty
                            ? const Center(
                                child: Text(
                                  "No tasks scheduled for today.",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _todayTasks.length,
                                itemBuilder: (context, index) {
                                  final task = _todayTasks[index];
                                  bool isDone = task['isDone'] == 1;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDone
                                          ? Colors.white.withOpacity(0.05)
                                          : Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      leading: IconButton(
                                        icon: Icon(
                                          isDone
                                              ? Icons.check_box_outlined
                                              : Icons.check_box_outline_blank,
                                          color: isDone
                                              ? Colors.greenAccent
                                              : Colors.white,
                                          size: 20,
                                        ),
                                        onPressed: () async {
                                          await _dbHelper.toggleCalendarTask(
                                            task['id'],
                                            isDone,
                                          );
                                          // Refresh data to show new task state AND update activity log
                                          _loadDashboardData();
                                        },
                                      ),
                                      title: Text(
                                        task['task'],
                                        style: TextStyle(
                                          color: isDone
                                              ? Colors.white38
                                              : Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          decoration: isDone
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // RIGHT SIDE: Profile and Recent Activity
        Expanded(
          child: Column(
            children: [
              // Penguin Profile / Welcome
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDFDF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.face,
                        size: 40,
                        color: Colors.pinkAccent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Hi Penguin!",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "You have ${_todayTasks.length} tasks today",
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // NEW: Recent Activity Panel (Replaced Cookie Jar)
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Recent Activity",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _recentActivity.isEmpty
                            ? const Center(
                                child: Text(
                                  "No activity yet.",
                                  style: TextStyle(
                                    color: Colors.black45,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _recentActivity.length,
                                itemBuilder: (context, index) {
                                  final activity = _recentActivity[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 12.0,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.only(top: 2.0),
                                          child: Icon(
                                            Icons.history,
                                            size: 16,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            activity['description'],
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black87,
                                              height: 1.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopCard(
    Color color,
    String title,
    String content, {
    bool isImageCard = false,
  }) {
    return Expanded(
      child: Container(
        height: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty)
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Expanded(
              child: isImageCard
                  ? const Center(child: Text("Fishbowl Img"))
                  : Text(
                      content,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black54,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
