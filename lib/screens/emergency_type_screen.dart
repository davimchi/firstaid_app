import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/database_helper.dart';
import '../services/language_service.dart';
import 'protocol_screen.dart';

class EmergencyTypeScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;
  const EmergencyTypeScreen({super.key, required this.categoryId, required this.categoryName});

  @override
  State<EmergencyTypeScreen> createState() => _EmergencyTypeScreenState();
}

class _EmergencyTypeScreenState extends State<EmergencyTypeScreen> {
  List<Map<String, dynamic>> _types = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final types = await DatabaseHelper.instance.getEmergencyTypes(widget.categoryId);
    setState(() { _types = types; _loading = false; });
  }

  Future<void> _openProtocol(String typeSlug) async {
    final protocol = await DatabaseHelper.instance.getProtocolByEmergencyType(typeSlug);
    if (protocol != null) {
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProtocolScreen(protocolId: protocol['id'])));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No published protocol for this emergency yet.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ls = LanguageService.instance;
    return Scaffold(
      appBar: AppBar(title: Text(widget.categoryName)),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _types.length,
        itemBuilder: (context, index) {
          final type = _types[index];
          final nameMap = jsonDecode(type['name']);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(ls.tr(type['name']), style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textMuted),
              onTap: () => _openProtocol(type['slug']),
            ),
          );
        },
      ),
    );
  }
}
