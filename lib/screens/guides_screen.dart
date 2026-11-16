import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/database_helper.dart';
import '../services/language_service.dart';
import 'emergency_type_screen.dart';

class GuidesScreen extends StatefulWidget {
  const GuidesScreen({super.key});

  @override
  State<GuidesScreen> createState() => _GuidesScreenState();
}

class _GuidesScreenState extends State<GuidesScreen> {
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cats = await DatabaseHelper.instance.getCategories();
    setState(() { _categories = cats; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final ls = LanguageService.instance;
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: Text(ls.t("What's happening?", 'Nini kinaendelea?'))),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.sageGreen, shape: BoxShape.circle),
                child: const Icon(Icons.medical_services, color: AppTheme.textDark),
              ),
              title: Text(ls.tr(cat['name']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
              onTap: () => Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => EmergencyTypeScreen(categoryId: cat['id'], categoryName: ls.tr(cat['name'])))
              ),
            ),
          );
        },
      ),
    );
  }
}
