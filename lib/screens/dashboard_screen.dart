import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _todayTasks = [];

  @override
  void initState() {
    super.initState();
    _loadTodayTasks();
  }

  // Fetches tasks from the database for the current date
  Future<void> _loadTodayTasks() async {
    DateTime now = DateTime.now();
    // Format must match the format used in CalendarScreen: YYYY-MM-DD
    String dateStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final tasks = await _dbHelper.getTasksForDate(dateStr);
    setState(() {
      _todayTasks = tasks;
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

              // TODO: Task checkmarks
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
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _todayTasks[index]['task'],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
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
        const SizedBox(width: 16),

        // RIGHT SIDE: Profile and Cookies
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

              // Cookie Counter Panel
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Cookie Jar",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: 120,
                        height: 120,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Text("Penguin Cookie Image"),
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

  // Helper widget for the top pinned squares
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
