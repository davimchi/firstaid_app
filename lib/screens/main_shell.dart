import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/language_service.dart';
import 'home_screen.dart';
import 'emergency_screen.dart';
import 'categories_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // Using IndexedStack so the pages don't reload when switching tabs
  final List<Widget> _pages = const [
    HomeScreen(),
    EmergencyScreen(),
    CategoriesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final ls = LanguageService.instance;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppTheme.primaryRed,
        unselectedItemColor: AppTheme.textMuted,
        backgroundColor: AppTheme.surface,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined), 
            activeIcon: const Icon(Icons.home),
            label: ls.t('Home', 'Nyumbani')
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.emergency_outlined), 
            activeIcon: const Icon(Icons.emergency),
            label: ls.t('Emergency', 'Dharura')
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.grid_view_outlined), 
            activeIcon: const Icon(Icons.grid_view),
            label: ls.t('Guides', 'Miongozo')
          ),
        ],
      ),
    );
  }
}
