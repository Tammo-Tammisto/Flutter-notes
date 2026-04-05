import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  final DateTime _today = DateTime.now();
  bool _showTasks = false;

  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _dayTasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() async {
    String dateStr =
        "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
    final tasks = await _dbHelper.getTasksForDate(dateStr);
    setState(() => _dayTasks = tasks);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildWeekdayLabels(),
          const SizedBox(height: 10),

          // Using LayoutBuilder to calculate the aspect ratio so it fills the height
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate ideal aspect ratio to prevent scrolling
                // 7 columns, roughly 5-6 rows
                final double cellWidth = constraints.maxWidth / 7;
                final double cellHeight = constraints.maxHeight / 6;
                final double aspectRatio = cellWidth / cellHeight;

                return _buildCalendarGrid(aspectRatio);
              },
            ),
          ),

          if (_showTasks) ...[
            const Divider(height: 40, thickness: 2),
            _buildTaskListHeader(),
            const SizedBox(height: 10),
            _buildTaskList(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "${_monthName(_selectedDate.month)} ${_selectedDate.year}",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildWeekdayLabels() {
    const labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return Row(
      children: labels
          .map(
            (label) => Expanded(
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCalendarGrid(double aspectRatio) {
    int daysInMonth = DateUtils.getDaysInMonth(
      _selectedDate.year,
      _selectedDate.month,
    );
    DateTime firstOfMonth = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      1,
    );
    int offset = firstOfMonth.weekday - 1;

    return GridView.builder(
      physics:
          const NeverScrollableScrollPhysics(), // Disable scrolling inside the grid
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: aspectRatio, // Dynamic ratio to fill space
      ),
      itemCount: daysInMonth + offset,
      itemBuilder: (context, index) {
        if (index < offset) return const SizedBox.shrink();

        int day = index - offset + 1;
        bool isToday =
            day == _today.day &&
            _selectedDate.month == _today.month &&
            _selectedDate.year == _today.year;
        bool isSelected = _selectedDate.day == day && _showTasks;

        return InkWell(
          onTap: () {
            if (_selectedDate.day == day && _showTasks) {
              // Tapping the same day that is already open closes it
              setState(() => _showTasks = false);
            } else {
              setState(() {
                _selectedDate = DateTime(
                  _selectedDate.year,
                  _selectedDate.month,
                  day,
                );
                _showTasks = true;
              });
              _loadTasks();
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: isToday
                  ? Colors.amberAccent.withOpacity(0.7)
                  : (isSelected ? const Color(0xFFD3B8D8) : Colors.white54),
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: Colors.purple, width: 2)
                  : (isToday
                        ? Border.all(color: Colors.orange, width: 1)
                        : null),
            ),
            child: Center(
              child: Text(
                "$day",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isToday ? Colors.brown : Colors.black87,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaskListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Tasks for ${_monthName(_selectedDate.month)} ${_selectedDate.day}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Tap day again to close",
              style: TextStyle(fontSize: 10, color: Colors.black45),
            ),
          ],
        ),
        // Add Task Button is now here
        ElevatedButton.icon(
          onPressed: _showAddTaskDialog,
          icon: const Icon(Icons.add, size: 18),
          label: const Text("Add Task"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    );
  }

  // Find _buildTaskList in calendar_screen.dart and update the trailing widget
  Widget _buildTaskList() {
    return Expanded(
      child: _dayTasks.isEmpty
          ? const Center(
              child: Text(
                "No tasks for this day.",
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.black45,
                ),
              ),
            )
          : ListView.builder(
              itemCount: _dayTasks.length,
              itemBuilder: (context, i) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: Colors.white.withOpacity(0.8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.purple,
                  ),
                  title: Text(_dayTasks[i]['task']),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    onPressed: () async {
                      // Added Delete Logic
                      await _dbHelper.deleteCalendarTask(_dayTasks[i]['id']);
                      _loadTasks(); // Refresh list
                    },
                  ),
                ),
              ),
            ),
    );
  }

  void _showAddTaskDialog() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "New Task: ${_monthName(_selectedDate.month)} ${_selectedDate.day}",
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Enter task details..."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                String dateStr =
                    "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
                await _dbHelper.insertCalendarTask(controller.text, dateStr);
                _loadTasks();
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  String _monthName(int m) => [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
  ][m - 1];
}
