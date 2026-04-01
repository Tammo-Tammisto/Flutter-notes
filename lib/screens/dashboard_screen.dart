import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // LEFT SIDE: Pinned Notes & Recent Activity
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TOP ROW: Pinned Note Cards
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
              // RECENT ACTIVITY PANEL
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF7F76B3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Recent activity",
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0F5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          // Placeholder for your recent activity lists
                          child: const Center(
                            child: Text("Activity Lists go here"),
                          ),
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
        // RIGHT SIDE: Today's To-Do List
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF7F76B3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Todays To-do list",
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF0F5),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Here is where you will conditionally show your items OR the empty state
                        const Text(
                          "Nothing to do today!",
                          style: TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 20),
                        // Empty state penguin
                        Container(
                          height: 150,
                          width: 150,
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
                  ? const Center(
                      child: Text("Fishbowl Img"),
                    ) // Replace with Image.asset
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
