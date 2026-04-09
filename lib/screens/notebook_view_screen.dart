import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_notes/services/database_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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

  final Size _canvasSize = const Size(1920, 880);

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

  void _showHowToUseDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.orange),
              SizedBox(width: 10),
              Text("How to Use"),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Click the bottom icons to add items."),
              SizedBox(height: 8),
              Row(
                children: [
                  Text("   "),
                  Icon(Icons.note_add, size: 18),
                  Text(" icon to add a sticky note."),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Text("   "),
                  Icon(Icons.image, size: 18),
                  Text(" icon to add an image."),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Text("   "),
                  Icon(Icons.text_fields, size: 18),
                  Text(" icon, then click anywhere to place text."),
                ],
              ),
              SizedBox(height: 8),
              Text("• Drag items to move them around."),
              SizedBox(height: 8),
              Text("• Click and hold an item to delete it."),
              SizedBox(height: 8),
              Text("• Click the title in the top left to rename."),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Got it!"),
            ),
          ],
        );
      },
    );
  }

  void _addItem(NotebookItemData newItem) {
    setState(() => _items.add(newItem));
    _saveToDatabase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
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
          onTap: _renameNotebook,
          borderRadius: BorderRadius.circular(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _currentTitle,
                style: const TextStyle(color: Colors.black87),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.edit, size: 18, color: Colors.black54),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.black87),
            onPressed: _showHowToUseDialog,
          ),
        ],
      ),
      body: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: GestureDetector(
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
              width: _canvasSize.width,
              height: _canvasSize.height,
              color: const Color(0xFFF5F5F5),
              child: Stack(
                children: _items.asMap().entries.map((entry) {
                  int idx = entry.key;
                  final item = _items[idx];

                  return DraggableItem(
                    key: ObjectKey(item),
                    initialPosition: item.position,
                    initialSize: item.size,
                    canvasSize: _canvasSize,
                    isResizable: true,
                    maintainAspectRatio: item.type == 'image',
                    onUpdate: (pos, size) {
                      item.position = pos;
                      item.size = size;
                      _saveToDatabase();
                    },
                    onDelete: () async {
                      if (item.type == 'image') {
                        final file = File(item.content);
                        if (await file.exists()) await file.delete();
                      }
                      setState(() => _items.removeAt(idx));
                      _saveToDatabase();
                    },
                    child: _buildItemContent(item, idx),
                  );
                }).toList(),
              ),
            ),
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
          ? Image.file(File(item.content), fit: BoxFit.fill)
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
        onChanged: (val) => _items[index].content = val,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }

  Future<void> _addImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null && result.files.single.path != null) {
      File originalFile = File(result.files.single.path!);

      final appDir = await getApplicationDocumentsDirectory();
      final folderPath = p.join(appDir.path, 'notebook_images');

      if (!await Directory(folderPath).exists()) {
        await Directory(folderPath).create(recursive: true);
      }

      String fileName =
          "${DateTime.now().millisecondsSinceEpoch}_${p.basename(originalFile.path)}";
      String newPath = p.join(folderPath, fileName);

      File savedFile = await originalFile.copy(newPath);

      final data = await savedFile.readAsBytes();
      final image = await decodeImageFromList(data);

      double initialWidth = 200.0;
      double initialHeight = (image.height / image.width) * initialWidth;

      _addItem(
        NotebookItemData(
          type: 'image',
          content: savedFile.path,
          position: const Offset(50, 50),
          size: Size(initialWidth, initialHeight),
        ),
      );
    }
  }
}

class DraggableItem extends StatefulWidget {
  final Widget child;
  final Offset initialPosition;
  final Size initialSize;
  final Size canvasSize;
  final bool isResizable;
  final bool maintainAspectRatio;
  final Function(Offset, Size) onUpdate;
  final VoidCallback onDelete;

  const DraggableItem({
    Key? key,
    required this.child,
    required this.initialPosition,
    required this.initialSize,
    required this.canvasSize,
    required this.onUpdate,
    required this.onDelete,
    this.isResizable = false,
    this.maintainAspectRatio = false,
  }) : super(key: key);

  @override
  State<DraggableItem> createState() => _DraggableItemState();
}

class _DraggableItemState extends State<DraggableItem> {
  late Offset position;
  late Size size;
  late double aspectRatio;

  @override
  void initState() {
    super.initState();
    position = widget.initialPosition;
    size = widget.initialSize;
    aspectRatio = size.width / size.height;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            Offset newPosition = position + details.delta;

            double dx = newPosition.dx.clamp(
              0.0,
              widget.canvasSize.width - size.width,
            );
            double dy = newPosition.dy.clamp(
              0.0,
              widget.canvasSize.height - size.height,
            );

            position = Offset(dx, dy);
          });
        },
        onPanEnd: (_) => widget.onUpdate(position, size),
        onLongPress: widget.onDelete,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: widget.child),

              // Resize handle
              if (widget.isResizable)
                Positioned(
                  right: -10,
                  bottom: -10,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        double newWidth = size.width + details.delta.dx;
                        double newHeight;

                        if (widget.maintainAspectRatio) {
                          newHeight = newWidth / aspectRatio;

                          if (position.dx + newWidth >
                              widget.canvasSize.width) {
                            newWidth = widget.canvasSize.width - position.dx;
                            newHeight = newWidth / aspectRatio;
                          }
                          if (position.dy + newHeight >
                              widget.canvasSize.height) {
                            newHeight = widget.canvasSize.height - position.dy;
                            newWidth = newHeight * aspectRatio;
                          }
                        } else {
                          newHeight = size.height + details.delta.dy;

                          newWidth = newWidth.clamp(
                            30.0,
                            widget.canvasSize.width - position.dx,
                          );
                          newHeight = newHeight.clamp(
                            30.0,
                            widget.canvasSize.height - position.dy,
                          );
                        }

                        if (newWidth > 30 && newHeight > 30) {
                          size = Size(newWidth, newHeight);
                        }
                      });
                    },
                    onPanEnd: (_) => widget.onUpdate(position, size),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(blurRadius: 2, color: Colors.black26),
                        ],
                      ),
                      child: const Icon(
                        Icons.open_in_full,
                        size: 16,
                        color: Colors.white,
                      ),
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
