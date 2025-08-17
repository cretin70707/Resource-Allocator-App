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
        priority INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');
    
    await db.execute('''
      CREATE TABLE resources (
        resource_id TEXT PRIMARY KEY,
        resource_type TEXT NOT NULL,
        total_quantity INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE requests (
        req_id INTEGER PRIMARY KEY AUTOINCREMENT,
        req_type TEXT NOT NULL,
        
      )
    ''');
    
    
    // Insert admin user with priority 0
    await db.insert('users', {
      'name': 'Admin',
      'email': 'admin42@gmail.com',
      'password': 'admin3107',
      'priority': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
    
    // Insert initial resources
    await db.insert('resources', {
      'resource_id': 'L',
      'resource_type': 'Laptop',
      'total_quantity': 5,
    });
    
    await db.insert('resources', {
      'resource_id': 'R',
      'resource_type': 'Room',
      'total_quantity': 5,
    });
    
    await db.insert('resources', {
      'resource_id': 'C',
      'resource_type': 'Chair',
      'total_quantity': 5,
    });
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
      // Get the next priority value
      final maxPriorityResult = await db.rawQuery('SELECT COALESCE(MAX(priority), 0) + 1 as next_priority FROM users');
      int nextPriority = maxPriorityResult.first['next_priority'] as int;
      
      await db.insert('users', {
        'name': name,
        'email': email,
        'password': password,
        'priority': nextPriority,
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
    await prefs.setInt('user_priority', user['priority']);
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
      'priority': prefs.getInt('user_priority'),
    };
  }

  Future<bool> isCurrentUserAdmin() async {
    final user = await getCurrentUser();
    return user != null && user['priority'] == 0;
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
    final users = await db.query('users', orderBy: 'priority ASC');
    print('All users in database:');
    for (var user in users) {
      print('ID: ${user['id']}, Priority: ${user['priority']}, Name: ${user['name']}, Email: ${user['email']}, Created: ${user['created_at']}');
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
    
    // Get resource count
    final resourceCount = await db.rawQuery('SELECT COUNT(*) as count FROM resources');
    print('Total resources: ${resourceCount.first['count']}');
    
    // Print database path
    await printDatabasePath();
    
    // Print all users
    await printAllUsers();
    
    // Print all resources
    await printAllResources();
  }

  Future<void> printAllResources() async {
    final db = await database;
    final resources = await db.query('resources');
    print('All resources in database:');
    for (var resource in resources) {
      print('ID: ${resource['resource_id']}, Type: ${resource['resource_type']}, Quantity: ${resource['total_quantity']}');
    }
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return await db.query('users');
  }

  Future<void> deleteUser(int userId) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [userId]);
  }

  // Resource management methods
  Future<List<Map<String, dynamic>>> getAllResources() async {
    final db = await database;
    return await db.query('resources');
  }

  Future<Map<String, dynamic>?> getResource(String resourceId) async {
    final db = await database;
    final result = await db.query(
      'resources',
      where: 'resource_id = ?',
      whereArgs: [resourceId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> updateResourceQuantity(String resourceId, int newQuantity) async {
    final db = await database;
    await db.update(
      'resources',
      {'total_quantity': newQuantity},
      where: 'resource_id = ?',
      whereArgs: [resourceId],
    );
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