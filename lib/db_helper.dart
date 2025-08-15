import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'resource_allocator.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here when adding new tables in the future
    if (oldVersion < newVersion) {
      // Add migration logic here for future updates
    }
  }

  // User authentication methods
  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<bool> signupUser(String name, String email, String password) async {
    final db = await database;
    
    // Check if user already exists
    final existingUser = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    
    if (existingUser.isNotEmpty) {
      return false; // User already exists
    }
    
    try {
      await db.insert('users', {
        'name': name,
        'email': email,
        'password': password,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkUserExists(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty;
  }

  // Session management using SharedPreferences
  Future<void> saveUserSession(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', user['id']);
    await prefs.setString('user_name', user['name']);
    await prefs.setString('user_email', user['email']);
    await prefs.setBool('is_logged_in', true);
  }

  Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    
    if (!isLoggedIn) return null;
    
    return {
      'id': prefs.getInt('user_id'),
      'name': prefs.getString('user_name'),
      'email': prefs.getString('user_email'),
    };
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Debug methods for database inspection
  Future<void> printDatabasePath() async {
    String path = join(await getDatabasesPath(), 'resource_allocator.db');
    print('Database path: $path');
  }

  Future<void> printAllUsers() async {
    final db = await database;
    final users = await db.query('users');
    print('All users in database:');
    for (var user in users) {
      print('ID: ${user['id']}, Name: ${user['name']}, Email: ${user['email']}, Created: ${user['created_at']}');
    }
  }

  Future<void> printDatabaseInfo() async {
    final db = await database;
    
    // Get all tables
    final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    print('Database tables: $tables');
    
    // Get user count
    final userCount = await db.rawQuery('SELECT COUNT(*) as count FROM users');
    print('Total users: ${userCount.first['count']}');
    
    // Print database path
    await printDatabasePath();
    
    // Print all users
    await printAllUsers();
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return await db.query('users');
  }

  Future<void> deleteUser(int userId) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [userId]);
  }

  // Export database to Downloads folder for easy access
  Future<String?> exportDatabase() async {
    try {
      // Get the current database file
      String dbPath = join(await getDatabasesPath(), 'resource_allocator.db');
      File dbFile = File(dbPath);
      
      // Create a copy in Downloads directory (accessible via ADB)
      String exportPath = '/storage/emulated/0/Download/resource_allocator_export.db';
      await dbFile.copy(exportPath);
      
      print('Database exported to: $exportPath');
      return exportPath;
    } catch (e) {
      print('Error exporting database: $e');
      return null;
    }
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}