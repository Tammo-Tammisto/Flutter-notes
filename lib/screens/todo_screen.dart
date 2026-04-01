import 'package:flutter/material.dart';

// Dummy model to represent our notebook categories
class NoteCategory {
  final String title;
  final int noteCount;
  final Color color;

  NoteCategory({required this.title, required this.noteCount, required this.color});
}

class TodoScreen extends StatefulWidget {
  const TodoScreen({Key? key}) : super(key: key);

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  int _selectedIndex = 0;

  // Recreating the beautiful pastel categories from your design
  final List<NoteCategory> _categories = [
    NoteCategory(title: "Biology", noteCount: 20, color: const Color(0xFFCBA5F5)),
    NoteCategory(title: "Math", noteCount: 33, color: const Color(0xFFE6B8D4)),
    NoteCategory(title: "Cooking", noteCount: 10, color: const Color(0xFFFFDAB9)),
    NoteCategory(title: "Book notes", noteCount: 26, color: const Color(0xFFFFFACD)),
    NoteCategory(title: "Personal", noteCount: 22, color: const Color(0xFFFFC0CB)),
    NoteCategory(title: "Presentations", noteCount: 10, color: const Color(0xFFDDA0DD)),
    NoteCategory(title: "Everything important", noteCount: 30, color: const Color(0xFFBCA9DE)),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // LEFT PANEL: Categories List
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                // The vertical dotted line detail from your design
                Positioned(
                  left: 30,
                  top: 20,
                  bottom: 20,
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: Colors.deepPurple.withOpacity(0.5),
                          width: 2,
                          style: BorderStyle.solid, // Flutter doesn't support native dotted borders easily, solid works as a nice stand-in
                        ),
                      ),
                    ),
                  ),
                ),
                // The actual category list
                ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedIndex == index;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: category.color.withOpacity(isSelected ? 1.0 : 0.6),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isSelected
                              ? [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(2, 2))]
                              : [],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 20), // Push text past the line
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${category.noteCount} notes",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(width: 16),

        // RIGHT PANEL: Notes in selected category
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF7F2F8), // Very light pink/purple
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Simulating the 3 columns of notes from your design
                Expanded(child: _buildNotesColumn("Blood cells", _categories[_selectedIndex].color)),
                const SizedBox(width: 20),
                Expanded(child: _buildNotesColumn("Blood cells", _categories[_selectedIndex].color)),
                const SizedBox(width: 20),
                Expanded(child: _buildNotesColumn("Blood cells", _categories[_selectedIndex].color)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper widget to build the lists of notes on the right side
  Widget _buildNotesColumn(String headerTitle, Color themeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          headerTitle,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildNoteItem("worksheet", themeColor),
        _buildNoteItem("sample text", themeColor),
        _buildNoteItem("I don't know anymore", themeColor, isStrikethrough: true),
        const SizedBox(height: 24),
        Text(
          "Title 2",
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildNoteItem("worksheet", themeColor),
        _buildNoteItem("sample text", themeColor),
        _buildNoteItem("I don't know anymore", themeColor),
      ],
    );
  }

  // Helper widget for individual note list items
  Widget _buildNoteItem(String title, Color themeColor, {bool isStrikethrough = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: themeColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: isStrikethrough ? Colors.black38 : Colors.black87,
              decoration: isStrikethrough ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }
}