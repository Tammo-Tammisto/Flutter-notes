import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_notes/services/database_helper.dart';

class NotebookItemData {
  String type;
  String content;
  Offset position;
  Size size;

  NotebookItemData({
    required this.type,
    required this.content,
    required this.position,
    required this.size,
  });

  Map<String, dynamic> toMap() => {
    'type': type,
    'content': content,
    'posX': position.dx,
    'posY': position.dy,
    'width': size.width,
    'height': size.height,
  };
}

class NotebookViewScreen extends StatefulWidget {
  final Color bookColor;
  final String title;
  final String notebookId;

  const NotebookViewScreen({
    Key? key,
    required this.bookColor,
    required this.title,
    required this.notebookId,
  }) : super(key: key);

  @override
  State<NotebookViewScreen> createState() => _NotebookViewScreenState();
}

class _NotebookViewScreenState extends State<NotebookViewScreen> {
  List<NotebookItemData> _items = [];
  bool _isWaitingForTextPlacement = false;
  late String _currentTitle;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.title;
    _loadSavedItems();
  }

  Future<void> _loadSavedItems() async {
    final savedData = await _dbHelper.getNotebookItems(widget.notebookId);
    setState(() {
      _items = savedData
          .map(
            (map) => NotebookItemData(
              type: map['type'],
              content: map['content'] ?? "",
              position: Offset(map['posX'] ?? 50.0, map['posY'] ?? 50.0),
              size: Size(map['width'] ?? 150.0, map['height'] ?? 150.0),
            ),
          )
          .toList();
    });
  }

  Future<void> _saveToDatabase() async {
    List<Map<String, dynamic>> data = _items
        .map((item) => item.toMap())
        .toList();
    await _dbHelper.saveNotebookItems(widget.notebookId, data);
    await _dbHelper.saveNotebook(
      widget.notebookId,
      _currentTitle,
      widget.bookColor.value,
    );
  }

  void _renameNotebook() {
    TextEditingController renameController = TextEditingController(
      text: _currentTitle,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Rename Notebook"),
        content: TextField(
          controller: renameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Enter new name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() => _currentTitle = renameController.text);
              _saveToDatabase();
              Navigator.pop(context);
            },
            child: const Text("Rename"),
          ),
        ],
      ),
    );
  }

  void _addItem(NotebookItemData newItem) {
    setState(() => _items.add(newItem));
    _saveToDatabase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: widget.bookColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            _saveToDatabase();
            Navigator.pop(context, _currentTitle);
          },
        ),
        title: InkWell(
          // Using InkWell for a better tap area for renaming
          onTap: _renameNotebook,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Text(
              _currentTitle,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ),
      ),
      body: GestureDetector(
        onTapDown: (details) {
          if (_isWaitingForTextPlacement) {
            _addItem(
              NotebookItemData(
                type: 'text',
                content: 'New Text',
                position: details.localPosition,
                size: const Size(200, 80),
              ),
            );
            setState(() => _isWaitingForTextPlacement = false);
          }
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color(0xFFF5F5F5),
          child: Stack(
            children: _items.asMap().entries.map((entry) {
              int idx = entry.key;
              return DraggableItem(
                key: ObjectKey(_items[idx]), // Use ObjectKey to maintain state
                initialPosition: _items[idx].position,
                initialSize: _items[idx].size,
                isResizable: _items[idx].type == 'image',
                onUpdate: (pos, size) {
                  _items[idx].position = pos;
                  _items[idx].size = size;
                  _saveToDatabase();
                },
                onDelete: () {
                  setState(() => _items.removeAt(idx));
                  _saveToDatabase();
                },
                child: _buildItemContent(_items[idx], idx),
              );
            }).toList(),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.note_add),
              onPressed: () => _addItem(
                NotebookItemData(
                  type: 'sticky',
                  content: '',
                  position: const Offset(50, 50),
                  size: const Size(150, 150),
                ),
              ),
            ),
            IconButton(icon: const Icon(Icons.image), onPressed: _addImage),
            IconButton(
              icon: const Icon(Icons.text_fields),
              onPressed: () =>
                  setState(() => _isWaitingForTextPlacement = true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemContent(NotebookItemData item, int index) {
    if (item.type == 'image') {
      return item.content.isNotEmpty
          ? Image.file(File(item.content), fit: BoxFit.cover)
          : const Icon(Icons.broken_image);
    }

    return Container(
      decoration: BoxDecoration(
        color: item.type == 'sticky'
            ? const Color(0xFFFFF9C4)
            : Colors.transparent,
        border: item.type == 'text'
            ? Border.all(color: Colors.blue.withOpacity(0.3))
            : null,
      ),
      padding: const EdgeInsets.all(8),
      child: TextField(
        controller: TextEditingController.fromValue(
          TextEditingValue(
            text: item.content,
            selection: TextSelection.collapsed(offset: item.content.length),
          ),
        ),
        maxLines: null,
        style: const TextStyle(fontSize: 14),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
        ),
        onChanged: (val) {
          _items[index].content = val;
          // We don't call _saveToDatabase on every keystroke to prevent lag;
          // it saves when moved, resized, or exiting.
        },
      ),
    );
  }

  Future<void> _addImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null && result.files.single.path != null) {
      _addItem(
        NotebookItemData(
          type: 'image',
          content: result.files.single.path!,
          position: const Offset(50, 50),
          size: const Size(150, 150),
        ),
      );
    }
  }
}

class DraggableItem extends StatefulWidget {
  final Widget child;
  final Offset initialPosition;
  final Size initialSize;
  final bool isResizable;
  final Function(Offset, Size) onUpdate;
  final VoidCallback onDelete;

  const DraggableItem({
    Key? key,
    required this.child,
    required this.initialPosition,
    required this.initialSize,
    required this.onUpdate,
    required this.onDelete,
    this.isResizable = false,
  }) : super(key: key);

  @override
  State<DraggableItem> createState() => _DraggableItemState();
}

class _DraggableItemState extends State<DraggableItem> {
  late Offset position;
  late Size size;

  @override
  void initState() {
    super.initState();
    position = widget.initialPosition;
    size = widget.initialSize;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() => position += details.delta);
        },
        onPanEnd: (_) => widget.onUpdate(position, size),
        onLongPress: widget.onDelete,
        child: SizedBox(
          width: size.width,
          height: widget.isResizable ? size.height : null,
          child: Stack(
            children: [
              widget.child,
              if (widget.isResizable)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        size = Size(
                          size.width + details.delta.dx,
                          size.height + details.delta.dy,
                        );
                      });
                    },
                    onPanEnd: (_) => widget.onUpdate(position, size),
                    child: const Icon(
                      Icons.open_in_full,
                      size: 18,
                      color: Colors.blue,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
