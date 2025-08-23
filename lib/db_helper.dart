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
      request_id INTEGER PRIMARY KEY AUTOINCREMENT,  -- unique ID for each request
      user_id INTEGER NOT NULL,                      -- foreign key from users
      resource_id TEXT NOT NULL,                     -- foreign key from resources
      quantity INTEGER NOT NULL,                     -- how many units requested
      request_priority INTEGER NOT NULL,             -- inherits from user's priority
      burst_time INTEGER NOT NULL,                   -- usage duration in hours
      arrival_time INTEGER NOT NULL,                 -- order of request arrival (1,2,3...)
      status TEXT DEFAULT 'pending',                 -- pending, approved, completed etc.
      created_at TEXT NOT NULL,                      -- timestamp when request was made
      FOREIGN KEY(user_id) REFERENCES users(id),
      FOREIGN KEY(resource_id) REFERENCES resources(resource_id)
);
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
    
    // Get request count
    final requestCount = await db.rawQuery('SELECT COUNT(*) as count FROM requests');
    print('Total requests: ${requestCount.first['count']}');
    
    // Print database path
    await printDatabasePath();
    
    // Print all users
    await printAllUsers();
    
    // Print all resources
    await printAllResources();
    
    // Print all requests
    await printAllRequests();
  }

  Future<void> printAllRequests() async {
    final db = await database;
    final requests = await db.query('requests', orderBy: 'arrival_time ASC');
    print('All requests in database:');
    for (var request in requests) {
      print('ID: ${request['request_id']}, User: ${request['user_id']}, Resource: ${request['resource_id']}, Qty: ${request['quantity']}, Priority: ${request['request_priority']}, Burst: ${request['burst_time']}hrs, Arrival: ${request['arrival_time']}, Status: ${request['status']}');
    }
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

  // Request management methods
  Future<bool> createRequest(int userId, String resourceId, int quantity, int burstTime) async {
    final db = await database;
    try {
      // Get user priority
      final user = await db.query('users', where: 'id = ?', whereArgs: [userId]);
      if (user.isEmpty) return false;
      int userPriority = user.first['priority'] as int;

      // Check resource quantity
      final resource = await db.query('resources', where: 'resource_id = ?', whereArgs: [resourceId]);
      if (resource.isEmpty) return false;
      int available = resource.first['total_quantity'] as int;
      if (quantity > available) {
        // Not enough resources
        return false;
      }

      // Get next arrival time (auto-increment)
      final maxArrivalResult = await db.rawQuery('SELECT COALESCE(MAX(arrival_time), 0) + 1 as next_arrival FROM requests');
      int nextArrival = maxArrivalResult.first['next_arrival'] as int;

      // Insert the request
      await db.insert('requests', {
        'user_id': userId,
        'resource_id': resourceId,
        'quantity': quantity,
        'request_priority': userPriority,
        'burst_time': burstTime,
        'arrival_time': nextArrival,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Error creating request: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getAllRequests() async {
    final db = await database;
    return await db.query('requests', orderBy: 'arrival_time ASC');
  }

  Future<List<Map<String, dynamic>>> getUserRequests(int userId) async {
    final db = await database;
    return await db.query(
      'requests',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'arrival_time DESC',
    );
  }

  Future<void> updateRequestStatus(int requestId, String status) async {
    final db = await database;
    await db.update(
      'requests',
      {'status': status},
      where: 'request_id = ?',
      whereArgs: [requestId],
    );
  }

  // FCFS Scheduling Algorithm
  Future<List<Map<String, dynamic>>> generateFCFSSchedule() async {
    final db = await database;
    
    // Get all pending requests ordered by arrival_time (FCFS)
    final requests = await db.rawQuery('''
      SELECT r.*, u.name as user_name, res.resource_type 
      FROM requests r
      JOIN users u ON r.user_id = u.id
      JOIN resources res ON r.resource_id = res.resource_id
      WHERE r.status = 'pending'
      ORDER BY r.arrival_time ASC
    ''');
    
    return _generateScheduleFromRequests(requests);
  }

  // SJF Scheduling Algorithm (Non-preemptive)
  Future<List<Map<String, dynamic>>> generateSJFSchedule() async {
    final db = await database;
    
    // Get all pending requests
    final allRequests = await db.rawQuery('''
      SELECT r.*, u.name as user_name, res.resource_type 
      FROM requests r
      JOIN users u ON r.user_id = u.id
      JOIN resources res ON r.resource_id = res.resource_id
      WHERE r.status = 'pending'
      ORDER BY r.arrival_time ASC
    ''');
    
    if (allRequests.isEmpty) return [];
    
    List<Map<String, dynamic>> orderedRequests = [];
    List<Map<String, dynamic>> availableRequests = List.from(allRequests);
    int currentTime = 0; // Track execution progress
    
    while (availableRequests.isNotEmpty) {
      // Find requests that have arrived by current time
      List<Map<String, dynamic>> arrivedRequests = availableRequests
          .where((req) => (req['arrival_time'] as int) <= currentTime + 1)
          .toList();
      
      if (arrivedRequests.isEmpty) {
        // No requests have arrived yet, advance time to next arrival
        int nextArrival = availableRequests
            .map((req) => req['arrival_time'] as int)
            .reduce((a, b) => a < b ? a : b);
        currentTime = nextArrival - 1;
        continue;
      }
      
      // Among arrived requests, pick the one with shortest burst time
      arrivedRequests.sort((a, b) {
        int burstCompare = (a['burst_time'] as int).compareTo(b['burst_time'] as int);
        if (burstCompare != 0) return burstCompare;
        // If burst times are equal, use arrival time as tiebreaker
        return (a['arrival_time'] as int).compareTo(b['arrival_time'] as int);
      });
      
      Map<String, dynamic> selectedRequest = arrivedRequests.first;
      orderedRequests.add(selectedRequest);
      availableRequests.remove(selectedRequest);
      
      // Advance current time by the burst time of executed process
      currentTime += (selectedRequest['burst_time'] as int);
    }
    
    return _generateScheduleFromRequests(orderedRequests);
  }

  // Priority Scheduling Algorithm (Non-preemptive)
  Future<List<Map<String, dynamic>>> generatePrioritySchedule() async {
    final db = await database;
    
    // Get all pending requests
    final allRequests = await db.rawQuery('''
      SELECT r.*, u.name as user_name, res.resource_type 
      FROM requests r
      JOIN users u ON r.user_id = u.id
      JOIN resources res ON r.resource_id = res.resource_id
      WHERE r.status = 'pending'
      ORDER BY r.arrival_time ASC
    ''');
    
    if (allRequests.isEmpty) return [];
    
    List<Map<String, dynamic>> orderedRequests = [];
    List<Map<String, dynamic>> availableRequests = List.from(allRequests);
    int currentTime = 0; // Track execution progress
    
    while (availableRequests.isNotEmpty) {
      // Find requests that have arrived by current time
      List<Map<String, dynamic>> arrivedRequests = availableRequests
          .where((req) => (req['arrival_time'] as int) <= currentTime + 1)
          .toList();
      
      if (arrivedRequests.isEmpty) {
        // No requests have arrived yet, advance time to next arrival
        int nextArrival = availableRequests
            .map((req) => req['arrival_time'] as int)
            .reduce((a, b) => a < b ? a : b);
        currentTime = nextArrival - 1;
        continue;
      }
      
      // Among arrived requests, pick the one with highest priority (lowest number)
      arrivedRequests.sort((a, b) {
        int priorityCompare = (a['request_priority'] as int).compareTo(b['request_priority'] as int);
        if (priorityCompare != 0) return priorityCompare;
        // If priorities are equal, use arrival time as tiebreaker
        return (a['arrival_time'] as int).compareTo(b['arrival_time'] as int);
      });
      
      Map<String, dynamic> selectedRequest = arrivedRequests.first;
      orderedRequests.add(selectedRequest);
      availableRequests.remove(selectedRequest);
      
      // Advance current time by the burst time of executed process
      currentTime += (selectedRequest['burst_time'] as int);
    }
    
    return _generateScheduleFromRequests(orderedRequests);
  }

  // Common scheduling logic for all algorithms
  Future<List<Map<String, dynamic>>> _generateScheduleFromRequests(List<Map<String, dynamic>> requests) async {
    List<Map<String, dynamic>> schedule = [];
    
    // Working hours: 9 AM to 5 PM (8 hours per day)
    const int workStartHour = 9;
    const int workEndHour = 17;
    const int workHoursPerDay = workEndHour - workStartHour; // 8 hours
    
    // Start from today
    DateTime currentDate = DateTime.now();
    int currentTimeSlot = 0; // Hours from 9 AM (0 = 9 AM, 1 = 10 AM, etc.)
    
    for (var request in requests) {
      int burstTime = request['burst_time'] as int;
      int remainingTime = burstTime;
      
      while (remainingTime > 0) {
        // Calculate how much time we can allocate today
        int availableTimeToday = workHoursPerDay - currentTimeSlot;
        int timeToAllocate = remainingTime < availableTimeToday ? remainingTime : availableTimeToday;
        
        if (timeToAllocate > 0) {
          // Calculate start and end times
          int startHour = workStartHour + currentTimeSlot;
          int endHour = startHour + timeToAllocate;
          
          // Format times
          String startTime = _formatTime(startHour, 0);
          String endTime = _formatTime(endHour, 0);
          String dateStr = _formatDate(currentDate);
          
          schedule.add({
            'request_id': request['request_id'],
            'user_name': request['user_name'],
            'resource_type': request['resource_type'],
            'quantity': request['quantity'],
            'date': dateStr,
            'start_time': startTime,
            'end_time': endTime,
            'duration': timeToAllocate,
            'arrival_time': request['arrival_time'],
            'priority': request['request_priority'],
            'burst_time': request['burst_time'],
          });
          
          remainingTime -= timeToAllocate;
          currentTimeSlot += timeToAllocate;
        }
        
        // If we've reached end of day or allocated all time, move to next day
        if (currentTimeSlot >= workHoursPerDay) {
          currentDate = currentDate.add(const Duration(days: 1));
          // Skip weekends (optional - you can remove this if you want 7-day scheduling)
          while (currentDate.weekday > 5) {
            currentDate = currentDate.add(const Duration(days: 1));
          }
          currentTimeSlot = 0;
        }
      }
    }
    
    return schedule;
  }

  String _formatTime(int hour, int minute) {
    String period = hour >= 12 ? 'PM' : 'AM';
    int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  String _formatDate(DateTime date) {
    List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day}${_getOrdinalSuffix(date.day)} ${months[date.month - 1]}';
  }

  String _getOrdinalSuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  // Export schedule to CSV
  Future<String?> exportScheduleToCSV(List<Map<String, dynamic>> schedule, String algorithm) async {
    try {
      // Create CSV content
      StringBuffer csv = StringBuffer();
      
      // Add header
      csv.writeln('Algorithm,Request_ID,User_Name,Resource_Type,Quantity,Date,Start_Time,End_Time,Duration_Hours,Arrival_Time,Priority,Burst_Time');
      
      // Add data rows
      for (var item in schedule) {
        csv.writeln('$algorithm,${item['request_id']},${item['user_name']},${item['resource_type']},${item['quantity']},${item['date']},${item['start_time']},${item['end_time']},${item['duration']},${item['arrival_time']},${item['priority']},${item['burst_time']}');
      }
      
      // Save to Downloads folder
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String fileName = 'schedule_${algorithm.toLowerCase()}_$timestamp.csv';
      String exportPath = '/storage/emulated/0/Download/$fileName';
      
      File csvFile = File(exportPath);
      await csvFile.writeAsString(csv.toString());
      
      print('Schedule exported to: $exportPath');
      return exportPath;
    } catch (e) {
      print('Error exporting schedule: $e');
      return null;
    }
  }

  // Export database to Downloads folder for easy access
  // Delete all requests from the database
  Future<void> deleteAllRequests() async {
    final db = await database;
    await db.delete('requests');
  }

  // Delete all entries from all tables (complete reset)
  Future<void> deleteAllEntries() async {
    final db = await database;
    // Delete all requests first (due to foreign key constraints)
    await db.delete('requests');
    // Delete all resources (but keep admin user)
    await db.delete('resources');
    // Delete all users except admin (priority 0)
    await db.delete('users', where: 'priority > ?', whereArgs: [0]);
  }

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