import 'package:flutter/material.dart';
import 'package:resource_allocator_app/pages/home.dart';
import 'package:resource_allocator_app/pages/login.dart';
import 'package:resource_allocator_app/pages/dashboard.dart';
import 'package:resource_allocator_app/pages/admin.dart';

void main() {


  runApp(const ResourceAllocatorApp());
}

class ResourceAllocatorApp extends StatelessWidget {
  const ResourceAllocatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Resource Allocator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ), 
      debugShowCheckedModeBanner: false,
      home: const AuthScreen(),
      routes: {
        '/login': (context) => const AuthScreen(),
        '/dashboard': (context) => const DashboardPage(),
        '/home': (context) => const HomeScreen(),
        '/admin': (context) => const AdminPage(),
      },
    );
  }
}

