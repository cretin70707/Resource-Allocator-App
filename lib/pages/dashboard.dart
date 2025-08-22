import 'package:flutter/material.dart';
import 'package:resource_allocator_app/db_helper.dart';
import 'package:resource_allocator_app/pdf_logic.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> schedule = [];
  bool isLoading = true;
  String currentAlgorithm = 'FCFS';

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    try {
      List<Map<String, dynamic>> newSchedule;
      
      switch (currentAlgorithm) {
        case 'SJF':
          newSchedule = await _dbHelper.generateSJFSchedule();
          break;
        case 'Priority':
          newSchedule = await _dbHelper.generatePrioritySchedule();
          break;
        case 'FCFS':
        default:
          newSchedule = await _dbHelper.generateFCFSSchedule();
          break;
      }
      
      if (mounted) {
        setState(() {
          schedule = newSchedule;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading schedule: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
      );
    }
  }
}  Future<void> _refreshSchedule() async {
    setState(() {
      isLoading = true;
    });
    await _loadSchedule();
  }

  void _showAlgorithmSelector() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Scheduling Algorithm'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Radio<String>(
                  value: 'FCFS',
                  groupValue: currentAlgorithm,
                  onChanged: (value) {
                    Navigator.pop(context);
                    _changeAlgorithm('FCFS');
                  },
                ),
                title: const Text('First Come First Served (FCFS)'),
                subtitle: const Text('Orders by arrival time'),
              ),
              ListTile(
                leading: Radio<String>(
                  value: 'SJF',
                  groupValue: currentAlgorithm,
                  onChanged: (value) {
                    Navigator.pop(context);
                    _changeAlgorithm('SJF');
                  },
                ),
                title: const Text('Shortest Job First (SJF)'),
                subtitle: const Text('Orders by shortest duration'),
              ),
              ListTile(
                leading: Radio<String>(
                  value: 'Priority',
                  groupValue: currentAlgorithm,
                  onChanged: (value) {
                    Navigator.pop(context);
                    _changeAlgorithm('Priority');
                  },
                ),
                title: const Text('Priority Scheduling'),
                subtitle: const Text('Orders by user priority'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _changeAlgorithm(String algorithm) {
    setState(() {
      currentAlgorithm = algorithm;
      isLoading = true;
    });
    _loadSchedule();
  }

  void _showExportOptions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Export Schedule'),
          content: const Text('Choose export format:'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _exportToCSV();
              },
              child: const Text('Export as CSV'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _exportToPDF();
              },
              child: const Text('Export as PDF'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportToCSV() async {
    if (schedule.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No schedule data to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final exportPath = await _dbHelper.exportScheduleToCSV(schedule, currentAlgorithm);
      Navigator.pop(context); // Close loading dialog

      if (exportPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Schedule exported successfully!\nFile: ${exportPath.split('/').last}\nUse: adb pull $exportPath ./'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to export schedule'),
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
  }

  Future<void> _exportToPDF() async {
    if (schedule.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No schedule data to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final exportPath = await PDFGenerator.exportScheduleToPDF(schedule, currentAlgorithm);
      Navigator.pop(context); // Close loading dialog

      if (exportPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF exported successfully!\nFile: ${exportPath.split('/').last}\nUse: adb pull $exportPath ./'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to export PDF'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF Export Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  String _getAlgorithmDescription() {
    switch (currentAlgorithm) {
      case 'FCFS':
        return 'Orders requests by arrival time (First Come First Served)';
      case 'SJF':
        return 'Orders requests by shortest burst time (Shortest Job First)';
      case 'Priority':
        return 'Orders requests by user priority (lower number = higher priority)';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$currentAlgorithm Schedule Dashboard'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _showAlgorithmSelector,
            icon: const Icon(Icons.tune),
            tooltip: 'Change Algorithm',
          ),
          IconButton(
            onPressed: _showExportOptions,
            icon: const Icon(Icons.download),
            tooltip: 'Export Schedule',
          ),
          IconButton(
            onPressed: _refreshSchedule,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Schedule',
          ),
        ],
      ),
      backgroundColor: Colors.purple,
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : schedule.isEmpty
              ? const Center(
                  child: Text(
                    'No pending requests to schedule',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$currentAlgorithm Schedule',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${schedule.length} tasks',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getAlgorithmDescription(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Working Hours: 9:00 AM - 5:00 PM',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: schedule.length,
                          itemBuilder: (context, index) {
                            final item = schedule[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              elevation: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${item['resource_type']} x${item['quantity']}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8, 
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'Arrival: ${item['arrival_time']}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.orange,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.person, size: 16, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          item['user_name'],
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        const Icon(Icons.flag, size: 16, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Priority: ${item['priority']}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.green.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['date'],
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${item['start_time']} - ${item['end_time']}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.green,
                                            ),
                                          ),
                                          Text(
                                            'Duration: ${item['duration']} ${item['duration'] == 1 ? 'hour' : 'hours'}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
