import 'package:flutter/material.dart';
import 'dart:async';
import '../services/database_helper.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({Key? key}) : super(key: key);

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Map<String, List<Map<String, dynamic>>> _groupedTasks = {};
  bool _isLoading = true;
  Timer? _dateTimer; // Added
  String _lastCheckedDate = ""; // Added

  @override
  void initState() {
    super.initState();
    _lastCheckedDate = _getDateString(); // Added
    _refreshTasks();
    _startDateListener(); // Added
  }

  @override
  void dispose() {
    _dateTimer?.cancel(); // Added
    super.dispose();
  }

  String _getDateString() {
    DateTime now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  void _startDateListener() {
    _dateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      String currentDate = _getDateString();
      if (currentDate != _lastCheckedDate) {
        _lastCheckedDate = currentDate;
        _refreshTasks();
      }
    });
  }

  // Fetches ALL tasks and groups them by date for the list
  Future<void> _refreshTasks() async {
    setState(() => _isLoading = true);

    final DatabaseHelper db = DatabaseHelper();
    final dbClient = await db.database;

    // Query all tasks ordered by date
    final List<Map<String, dynamic>> allTasks = await dbClient.query(
      'calendar_tasks',
      orderBy: 'date DESC',
    );

    // Grouping logic: { "2024-10-12": [task1, task2], "2024-10-11": [task3] }
    Map<String, List<Map<String, dynamic>>> tempGrouped = {};
    for (var task in allTasks) {
      String date = task['date'] as String;
      if (tempGrouped[date] == null) {
        tempGrouped[date] = [];
      }
      tempGrouped[date]!.add(task);
    }

    setState(() {
      _groupedTasks = tempGrouped;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine the theme color (using the purple from your design)
    const Color themeColor = Color(0xFF9E8DD6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "All Tasks",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _groupedTasks.isEmpty
                ? const Center(
                    child: Text(
                      "No tasks found.\nAdd some in the Calendar!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black45, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: _groupedTasks.keys.length,
                    itemBuilder: (context, index) {
                      String dateKey = _groupedTasks.keys.elementAt(index);
                      List<Map<String, dynamic>> tasks =
                          _groupedTasks[dateKey]!;

                      return _buildDateSection(dateKey, tasks, themeColor);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Builds a header for the date and the list of tasks under it
  Widget _buildDateSection(
    String date,
    List<Map<String, dynamic>> tasks,
    Color color,
  ) {
    // Simplify date display (e.g., Check if it's today)
    String displayDate = date;
    DateTime now = DateTime.now();
    String todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    if (date == todayStr) displayDate = "Today";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text(
            displayDate,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7F76B3),
            ),
          ),
        ),
        ...tasks.map((task) => _buildTaskItem(task, color)).toList(),
        const Divider(height: 32),
      ],
    );
  }

  Widget _buildTaskItem(Map<String, dynamic> task, Color themeColor) {
    bool isDone = task['isDone'] == 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onLongPress: () => _confirmDelete(task['id']), // Delete on long press
        child: Row(
          children: [
            // Custom Checkbox
            GestureDetector(
              onTap: () async {
                await _dbHelper.toggleCalendarTask(task['id'], isDone);
                _refreshTasks(); // Refresh UI after database change
              },
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isDone ? themeColor : Colors.white,
                  border: Border.all(color: themeColor, width: 2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: isDone
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            // Task Text
            Expanded(
              child: Text(
                task['task'],
                style: TextStyle(
                  fontSize: 16,
                  color: isDone ? Colors.black38 : Colors.black87,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            // Individual delete button
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                size: 20,
                color: Colors.black26,
              ),
              onPressed: () => _confirmDelete(task['id']),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Task?"),
        content: const Text(
          "This will remove the task from your schedule and history.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await _dbHelper.deleteCalendarTask(id);
              Navigator.pop(context);
              _refreshTasks();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
