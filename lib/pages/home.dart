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
    int durationHours = 1;

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
                  
                  // Duration Selection
                  const Text('Duration (Hours):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  
                  // Duration Hours
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Hours:', style: TextStyle(fontSize: 14)),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              if (durationHours > 1) {
                                setState(() {
                                  durationHours--;
                                });
                              }
                            },
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$durationHours ${durationHours == 1 ? 'hour' : 'hours'}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              if (durationHours < 8) { // Max 8 hours (9 AM - 5 PM)
                                setState(() {
                                  durationHours++;
                                });
                              }
                            },
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Available hours: 9 AM - 5 PM (max 8 hours)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
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
                  onPressed: () async {
                    // Get current user
                    final user = await _dbHelper.getCurrentUser();
                    if (user == null) return;

                    // Map resource type to resource ID
                    String resourceId;
                    switch (resourceType) {
                      case 'Laptops':
                        resourceId = 'L';
                        break;
                      case 'Chairs':
                        resourceId = 'C';
                        break;
                      case 'Room':
                        resourceId = 'R';
                        break;
                      default:
                        resourceId = 'L';
                    }

                    // Check resource quantity before submitting
                    final resource = await _dbHelper.getResource(resourceId);
                    int available = resource?['total_quantity'] ?? 0;
                    if (quantity > available) {
                      // Show warning dialog
                      if (mounted) {
                        Navigator.of(context).pop();
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Not Enough Resources'),
                            content: Text('Only $available $resourceType available. Please request $available or fewer.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      }
                      return;
                    }

                    // Submit request to database
                    final success = await _dbHelper.createRequest(
                      user['id'],
                      resourceId,
                      quantity,
                      durationHours,
                    );
                    Navigator.of(context).pop();
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Request submitted successfully!\n$quantity $resourceType for $durationHours ${durationHours == 1 ? 'hour' : 'hours'}'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to submit request. Please try again.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
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
                    ? 'Welcome "$userName", please choose a resource'
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


