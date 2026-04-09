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
  List<Map<String, dynamic>> _stickies = [];
  List<Map<String, dynamic>> _todayTasks = [];
  List<Map<String, dynamic>> _recentActivity = [];
  Timer? _refreshTimer;
  String _lastDate = "";

  @override
  void initState() {
    super.initState();
    _lastDate = _getDateString();
    _loadDashboardData();
    _startTimer();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
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
    final stickies = await _dbHelper.getDashboardStickies();

    setState(() {
      _todayTasks = tasks;
      _recentActivity = _groupActivities(activity);
      _stickies = stickies;
    });
  }

  List<Map<String, dynamic>> _groupActivities(List<Map<String, dynamic>> raw) {
    if (raw.isEmpty) return [];

    List<Map<String, dynamic>> grouped = [];

    for (var row in raw) {
      if (grouped.isEmpty) {
        grouped.add({...row, 'count': 1});
      } else {
        if (grouped.last['description'] == row['description']) {
          grouped.last['count']++;
        } else {
          grouped.add({...row, 'count': 1});
        }
      }
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // TOP ROW — 6 FULL-WIDTH STICKY NOTES
        Row(
          children: List.generate(6, (index) {
            if (index < _stickies.length) {
              return _buildStickyCard(_stickies[index]);
            } else {
              return _buildEmptyStickySlot(index);
            }
          }),
        ),

        const SizedBox(height: 16),

        // BOTTOM AREA — TWO COLUMNS
        Expanded(
          child: Row(
            children: [
              // LEFT — TODAY'S SCHEDULE
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7F76B3),
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

              const SizedBox(width: 16),

              // RIGHT — RECENT ACTIVITY
              Expanded(
                flex: 1,
                child: Container(
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
                                  final int count = activity['count'] ?? 1;

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
                                          child: Text.rich(
                                            TextSpan(
                                              text: activity['description'],
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black87,
                                                height: 1.3,
                                              ),
                                              children: [
                                                if (count > 1)
                                                  TextSpan(
                                                    text: " ($count)",
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.blueAccent,
                                                    ),
                                                  ),
                                              ],
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

  // EMPTY SLOT (shows + button)
  Widget _buildEmptyStickySlot(int index) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1,
        child: GestureDetector(
          onTap: () async {
            await _dbHelper.insertDashboardSticky("Title", "", 0xFFD6B5D8);
            _loadDashboardData();
          },
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white30),
            ),
            child: const Center(
              child: Icon(Icons.add, color: Colors.white70, size: 32),
            ),
          ),
        ),
      ),
    );
  }

  // FILLED STICKY NOTE
  Widget _buildStickyCard(Map<String, dynamic> sticky) {
    TextEditingController titleCtrl = TextEditingController(
      text: sticky['title'],
    );
    TextEditingController contentCtrl = TextEditingController(
      text: sticky['content'],
    );

    return Expanded(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color(sticky['color']),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Title",
                ),
                style: const TextStyle(fontWeight: FontWeight.bold),
                onChanged: (val) {
                  _dbHelper.updateDashboardSticky(
                    sticky['id'],
                    val,
                    contentCtrl.text,
                  );
                },
              ),
              const SizedBox(height: 4),
              Expanded(
                child: TextField(
                  controller: contentCtrl,
                  maxLines: null,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Write something...",
                  ),
                  onChanged: (val) {
                    _dbHelper.updateDashboardSticky(
                      sticky['id'],
                      titleCtrl.text,
                      val,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
