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

    // NEW: Table for Notebooks (The books on the shelf)
    await db.execute('''
      CREATE TABLE notebooks(
        id TEXT PRIMARY KEY, 
        title TEXT,
        color INTEGER
      )
    ''');

    // NEW: Table for Items inside notebooks
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
  }

  // --- Notebook Persistence Methods ---

  Future<void> saveNotebook(String id, String title, int colorValue) async {
    final db = await database;
    await db.insert('notebooks', {
      'id': id,
      'title': title,
      'color': colorValue,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
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
    await db.delete(
      'notebook_items',
      where: 'notebookId = ?',
      whereArgs: [notebookId],
    );
    for (var item in items) {
      await db.insert('notebook_items', {'notebookId': notebookId, ...item});
    }
  }

  Future<List<Map<String, dynamic>>> getNotebookItems(String notebookId) async {
    final db = await database;
    return await db.query(
      'notebook_items',
      where: 'notebookId = ?',
      whereArgs: [notebookId],
    );
  }

  Future<int> insertNote(Note note) async {
    final db = await database;
    return await db.insert('notes', note.toMap());
  }

  Future<List<Note>> getNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('notes');
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }

  Future<int> updateNote(Note note) async {
    final db = await database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNote(int id) async {
    final db = await database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }
}
