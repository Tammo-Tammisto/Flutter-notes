import 'package:flutter_notes/model/notes_model.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'my_notes_v2.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    // Original notes table (Dashboard)
    await db.execute('''
      CREATE TABLE notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        content TEXT,
        color TEXT,
        dateTime TEXT
      )
    ''');

    // Table for Notebooks (The books on the shelf)
    await db.execute('''
      CREATE TABLE notebooks(
        id TEXT PRIMARY KEY, 
        title TEXT,
        color INTEGER
      )
    ''');

    // Table for Items inside notebooks
    await db.execute('''
      CREATE TABLE notebook_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        notebookId TEXT,
        type TEXT, -- 'sticky', 'image', 'text'
        content TEXT, -- text content or file path
        posX REAL,
        posY REAL,
        width REAL,
        height REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE calendar_tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task TEXT,
        date TEXT,
        isDone INTEGER DEFAULT 0 
      )
    ''');

    // NEW: Table for Recent Activity
    await db.execute('''
      CREATE TABLE recent_activity(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT,
        timestamp TEXT
      )
    ''');
  }

  // --- NEW: Logging Method ---
  Future<void> logActivity(String description) async {
    final db = await database;
    await db.insert('recent_activity', {
      'description': description,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // --- NEW: Fetch Recent Activity ---
  Future<List<Map<String, dynamic>>> getRecentActivity() async {
    final db = await database;
    // Get the 15 most recent activities
    return await db.query(
      'recent_activity',
      orderBy: 'timestamp DESC',
      limit: 15,
    );
  }

  // --- Calendar Methods ---
  Future<void> insertCalendarTask(String task, String date) async {
    final db = await database;
    await db.insert('calendar_tasks', {'task': task, 'date': date});
    await logActivity("Added calendar task: '$task'");
  }

  Future<List<Map<String, dynamic>>> getTasksForDate(String date) async {
    final db = await database;
    return await db.query(
      'calendar_tasks',
      where: 'date = ?',
      whereArgs: [date],
    );
  }

  // --- Updated Toggle Task with Name ---
  Future<void> toggleCalendarTask(int id, bool currentStatus) async {
    final db = await database;
    bool isNowDone = !currentStatus;

    // 1. Fetch the task name first so we can use it in the log
    final List<Map<String, dynamic>> maps = await db.query(
      'calendar_tasks',
      columns: ['task'],
      where: 'id = ?',
      whereArgs: [id],
    );

    String taskName = "Unknown Task";
    if (maps.isNotEmpty) {
      taskName = maps.first['task'];
    }

    // 2. Update the status
    await db.update(
      'calendar_tasks',
      {'isDone': isNowDone ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );

    // 3. Log with the specific name
    await logActivity(
      isNowDone
          ? "Completed task: '$taskName'"
          : "Marked task as pending: '$taskName'",
    );
  }

  // --- Updated Delete Task with Name ---
  Future<void> deleteCalendarTask(int id) async {
    final db = await database;

    // 1. Fetch the task name before we delete it
    final List<Map<String, dynamic>> maps = await db.query(
      'calendar_tasks',
      columns: ['task'],
      where: 'id = ?',
      whereArgs: [id],
    );

    String taskName = "Unknown Task";
    if (maps.isNotEmpty) {
      taskName = maps.first['task'];
    }

    // 2. Perform the deletion
    await db.delete('calendar_tasks', where: 'id = ?', whereArgs: [id]);

    // 3. Log the specific name
    await logActivity("Deleted calendar task: '$taskName'");
  }

  // --- Notebook Persistence Methods ---
  Future<void> saveNotebook(String id, String title, int colorValue) async {
    final db = await database;

    // 1. Check the existing title to see if it's actually changing
    final List<Map<String, dynamic>> existing = await db.query(
      'notebooks',
      where: 'id = ?',
      whereArgs: [id],
    );

    String? oldTitle;
    if (existing.isNotEmpty) {
      oldTitle = existing.first['title'];
    }

    // 2. Save the notebook
    await db.insert('notebooks', {
      'id': id,
      'title': title,
      'color': colorValue,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // 3. ONLY log if the title is NEW or CHANGED
    // This prevents the "double log" when opening/closing without changes
    if (title != "My Notebook" && title.isNotEmpty) {
      if (oldTitle == null) {
        // It's a brand new notebook
        await logActivity("Created notebook: '$title'");
      } else if (oldTitle != title) {
        // The name was changed
        await logActivity("Renamed notebook from '$oldTitle' to '$title'");
      }
    }
  }

  Future<Map<String, String>> getNotebookTitles() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('notebooks');
    return {
      for (var item in maps) item['id'] as String: item['title'] as String,
    };
  }

  Future<void> saveNotebookItems(
    String notebookId,
    List<Map<String, dynamic>> items,
  ) async {
    final db = await database;

    // 1. Get the notebook title to make the log entry look nice
    final List<Map<String, dynamic>> nb = await db.query(
      'notebooks',
      columns: ['title'],
      where: 'id = ?',
      whereArgs: [notebookId],
    );
    String nbTitle = nb.isNotEmpty ? nb.first['title'] : "Notebook";

    // 2. Perform the update
    await db.delete(
      'notebook_items',
      where: 'notebookId = ?',
      whereArgs: [notebookId],
    );

    for (var item in items) {
      await db.insert('notebook_items', {'notebookId': notebookId, ...item});
    }

    // 3. Log that the contents were updated
    // Note: To avoid spamming, we only log "Updated elements"
    // This handles adding/deleting/moving items inside
    await logActivity("Edited: '$nbTitle'");
  }

  Future<List<Map<String, dynamic>>> getNotebookItems(String notebookId) async {
    final db = await database;
    return await db.query(
      'notebook_items',
      where: 'notebookId = ?',
      whereArgs: [notebookId],
    );
  }

  // --- Sticky Note Methods ---
  Future<int> insertNote(Note note) async {
    final db = await database;
    int id = await db.insert('notes', note.toMap());
    await logActivity("Created new note: '${note.title}'");
    return id;
  }

  Future<List<Note>> getNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('notes');
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }

  Future<int> updateNote(Note note) async {
    final db = await database;
    int count = await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
    await logActivity("Updated note: '${note.title}'");
    return count;
  }

  Future<int> deleteNote(int id) async {
    final db = await database;
    int count = await db.delete('notes', where: 'id = ?', whereArgs: [id]);
    await logActivity("Deleted a note");
    return count;
  }
}
