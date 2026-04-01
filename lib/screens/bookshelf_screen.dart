import 'package:flutter/material.dart';
import 'package:flutter_notes/screens/notebook_view_screen.dart';
import 'package:flutter_notes/services/database_helper.dart';

class BookshelfScreen extends StatefulWidget {
  const BookshelfScreen({Key? key}) : super(key: key);

  @override
  State<BookshelfScreen> createState() => _BookshelfScreenState();
}

class _BookshelfScreenState extends State<BookshelfScreen> {
  // Store custom titles - empty by default
  final Map<String, String> _bookTitles = {};

  // Inside _BookshelfScreenState
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadTitles();
  }

  Future<void> _loadTitles() async {
    final titles = await _dbHelper.getNotebookTitles();
    setState(() {
      _bookTitles.addAll(titles);
    });
  }

  final List<Color> shelf1Colors = [
    const Color(0xFF98A9B8),
    const Color(0xFFB5C5D1),
    const Color(0xFFC7D9E5),
    const Color(0xFFD9EAF2),
    const Color(0xFFAFB6CB),
    const Color(0xFFBDC4D9),
    const Color(0xFFCEC8D9),
    const Color(0xFFA39BB3),
    const Color(0xFF8B849C),
    const Color(0xFFE5E8F2),
    const Color(0xFFC9D1E6),
  ];

  final List<Color> shelf2Colors = [
    const Color(0xFFE2D1E2),
    const Color(0xFFC1A4B1),
    const Color(0xFFE4A9AC),
    const Color(0xFFF2C9C9),
    const Color(0xFFF5D5D5),
    const Color(0xFFB59D94),
    const Color(0xFFEED5C7),
    const Color(0xFFD9B9A6),
    const Color(0xFFEFE0E5),
    const Color(0xFFCCB6B0),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF9CB9C),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Expanded(child: _buildShelfRow(context, shelf1Colors, "Shelf1")),
            Expanded(child: _buildShelfRow(context, shelf2Colors, "Shelf2")),
          ],
        ),
      ),
    );
  }

  Widget _buildShelfRow(
    BuildContext context,
    List<Color> colors,
    String shelfName,
  ) {
    return Container(
      margin: const EdgeInsets.all(30),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: colors.asMap().entries.map((entry) {
          int idx = entry.key;
          Color color = entry.value;
          // Create a unique ID for each book based on shelf and position
          String bookId = "${shelfName}_$idx";
          String title = _bookTitles[bookId] ?? "";

          return _buildBook(context, color, title, bookId);
        }).toList(),
      ),
    );
  }

  Widget _buildBook(
    BuildContext context,
    Color color,
    String title,
    String id,
  ) {
    return GestureDetector(
      onTap: () async {
        String initialTitle = title.isEmpty ? "My Notebook" : title;

        // Navigate and wait for the result
        final dynamic result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NotebookViewScreen(
              bookColor: color,
              title: initialTitle,
              notebookId: id,
            ),
          ),
        );

        // If the result is a string, it's the new title
        if (result != null && result is String) {
          setState(() {
            _bookTitles[id] = result;
          });
          // Save the updated title to the DB immediately
          await _dbHelper.saveNotebook(id, result, color.value);
        }
      },
      child: Container(
        width: 40,
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              offset: const Offset(2, 0),
              blurRadius: 2,
            ),
          ],
        ),
        child: title.isNotEmpty
            ? RotatedBox(
                quarterTurns: 3,
                child: Center(
                  child: Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
