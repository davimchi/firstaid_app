import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'home_screen.dart';
import 'emergency_screen.dart';
import 'guides_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const EmergencyScreen(),
    const GuidesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppTheme.primaryRed,
        unselectedItemColor: AppTheme.textMuted,
        backgroundColor: AppTheme.surface,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.emergency), label: 'Emergency'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Guides'),
        ],
      ),
    );
  }
}
