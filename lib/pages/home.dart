import 'package:flutter/material.dart';
import 'package:resource_allocator_app/pages/dashboard.dart';
import 'package:resource_allocator_app/pages/login.dart';
import 'package:resource_allocator_app/db_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  String userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = await _dbHelper.getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        userName = user['name'] ?? '';
      });
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Do you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _handleLogout();
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    try {
      await _dbHelper.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showResourceDialog(BuildContext context, String resourceType, IconData icon, Color iconColor) {
    int quantity = 1;
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 17, minute: 0);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Request $resourceType'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Quantity Selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Quantity:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              if (quantity > 1) {
                                setState(() {
                                  quantity--;
                                });
                              }
                            },
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text('$quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                quantity++;
                              });
                            },
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Time Selection
                  const Text('Duration:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  
                  // Start Time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Start Time:'),
                      TextButton(
                        onPressed: () async {
                          TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: startTime,
                            builder: (context, child) {
                              return MediaQuery(
                                data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            // Restrict to 9 AM - 5 PM
                            if (picked.hour >= 9 && picked.hour <= 17) {
                              setState(() {
                                startTime = picked;
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please select time between 9 AM - 5 PM')),
                              );
                            }
                          }
                        },
                        child: Text(startTime.format(context)),
                      ),
                    ],
                  ),
                  
                  // End Time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('End Time:'),
                      TextButton(
                        onPressed: () async {
                          TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: endTime,
                            builder: (context, child) {
                              return MediaQuery(
                                data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            // Restrict to 9 AM - 5 PM and after start time
                            if (picked.hour >= 9 && picked.hour <= 17) {
                              setState(() {
                                endTime = picked;
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please select time between 9 AM - 5 PM')),
                              );
                            }
                          }
                        },
                        child: Text(endTime.format(context)),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // TODO: Submit request with quantity, startTime, endTime
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Requested $quantity $resourceType from ${startTime.format(context)} to ${endTime.format(context)}'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text('Submit Request'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple,
      appBar: AppBar(
        title: const Text('Resource Allocator'),
        backgroundColor: Colors.blueAccent,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white, size: 30),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _showLogoutDialog(context);
            },
            icon: const Icon(Icons.logout, color: Colors.white, size: 30),
          )
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blueAccent,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DashboardPage()),
                );
              },
            ),
            // Add this new ListTile for database export
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export Database'),
              onTap: () async {
                Navigator.pop(context); // Close drawer
                
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
                
                try {
                  final exportPath = await _dbHelper.exportDatabase();
                  Navigator.pop(context); // Close loading dialog
                  
                  if (exportPath != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Database exported to Downloads folder!\nUse: adb pull /storage/emulated/0/Download/resource_allocator_export.db ./'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 5),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to export database'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  Navigator.pop(context); // Close loading dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
            // Add debug info button too
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Database Info'),
              onTap: () async {
                Navigator.pop(context); // Close drawer
                await _dbHelper.printDatabaseInfo();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Database info printed to console (check VS Code debug console)'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Welcome message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Text(
                userName.isNotEmpty 
                    ? 'Welcome $userName, please choose a resource'
                    : 'Welcome, please choose a resource',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const Text(
              'Request Resources',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: GridView.count(
                crossAxisCount: 1,
                mainAxisSpacing: 20,
                childAspectRatio: 4,
                children: [
                  // Laptops Card
                  Card(
                    elevation: 5,
                    child: ListTile(
                      leading: const Icon(Icons.laptop, size: 40, color: Colors.blue),
                      title: const Text(
                        'Laptops',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('Request laptop'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        _showResourceDialog(context, 'Laptops', Icons.laptop, Colors.blue);
                      },
                    ),
                  ),
                  
                  // Chairs Card
                  Card(
                    elevation: 5,
                    child: ListTile(
                      leading: const Icon(Icons.chair, size: 40, color: Colors.green),
                      title: const Text(
                        'Chairs',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('Request chairs'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        _showResourceDialog(context, 'Chairs', Icons.chair, Colors.green);
                      },
                    ),
                  ),
                  
                  // Room Card
                  Card(
                    elevation: 5,
                    child: ListTile(
                      leading: const Icon(Icons.meeting_room, size: 40, color: Colors.orange),
                      title: const Text(
                        'Room',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('Book a room'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        _showResourceDialog(context, 'Room', Icons.meeting_room, Colors.orange);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


