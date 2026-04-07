import 'dart:ui'; // Required for PointerDeviceKind
import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({Key? key}) : super(key: key);

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  int _selectedTabIndex = 0;
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final cats = await _dbHelper.getCategories();
    setState(() {
      _categories = cats;
      if (_selectedTabIndex >= _categories.length && _categories.isNotEmpty) {
        _selectedTabIndex = 0;
      }
      _isLoading = false;
    });
  }

  void _addNewCategory() {
    TextEditingController _catController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Category Tab"),
        content: TextField(
          controller: _catController,
          decoration: const InputDecoration(hintText: "e.g., Biology, Math"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_catController.text.isNotEmpty) {
                await _dbHelper.insertCategory(_catController.text, 0xFFCBA5F5);
                Navigator.pop(context);
                _loadData();
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(int categoryId, String categoryName) {
    TextEditingController _taskController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add to $categoryName"),
        content: TextField(
          controller: _taskController,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Enter task..."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_taskController.text.isNotEmpty) {
                await _dbHelper.insertCategorizedTodo(
                  categoryId,
                  _taskController.text,
                );
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- TAB BAR ROW ---
          Row(
            children: [
              // 1. SCROLLABLE AREA (Takes all available space except the + button)
              Expanded(
                child: ScrollConfiguration(
                  behavior: const MaterialScrollBehavior().copyWith(
                    dragDevices: {...PointerDeviceKind.values},
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: _categories.asMap().entries.map((entry) {
                        int idx = entry.key;
                        var cat = entry.value;
                        bool isSelected = _selectedTabIndex == idx;

                        return GestureDetector(
                          onTap: () => setState(() => _selectedTabIndex = idx),
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Color(cat['color'])
                                  : Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Text(
                              cat['name'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.black87
                                    : Colors.white,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              // 2. PINNED ADD BUTTON (Always visible on the right)
              const SizedBox(width: 8),
              IconButton(
                onPressed: _addNewCategory,
                icon: const Icon(
                  Icons.add_circle,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // --- MAIN TASK CONTENT ---
          Expanded(
            child: _categories.isEmpty
                ? const Center(
                    child: Text(
                      "No tabs found.",
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : FutureBuilder<List<Map<String, dynamic>>>(
                    key: ValueKey(_categories[_selectedTabIndex]['id']),
                    future: _dbHelper.getTodosForCategory(
                      _categories[_selectedTabIndex]['id'],
                    ),
                    builder: (context, snapshot) {
                      final tasks = snapshot.data ?? [];

                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _categories[_selectedTabIndex]['name'],
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.add_task,
                                    size: 28,
                                    color: Color(0xFF7F76B3),
                                  ),
                                  onPressed: () => _showAddTaskDialog(
                                    _categories[_selectedTabIndex]['id'],
                                    _categories[_selectedTabIndex]['name'],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
                            Expanded(
                              child: ListView.builder(
                                itemCount: tasks.length,
                                itemBuilder: (context, index) {
                                  final task = tasks[index];
                                  return CheckboxListTile(
                                    title: Text(task['task']),
                                    value: task['isDone'] == 1,
                                    onChanged: (val) async {
                                      await _dbHelper.toggleTodoStatus(
                                        task['id'],
                                        val!,
                                      );
                                      setState(() {});
                                    },
                                  );
                                },
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
    );
  }
}
