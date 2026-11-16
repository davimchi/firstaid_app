import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../services/api_service.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('firstaid.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    // Version 6 — adds emergency_types
    return await openDatabase(path, version: 6, onCreate: _createDB, onUpgrade: _upgradeDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('CREATE TABLE categories (id INTEGER PRIMARY KEY, name TEXT, icon TEXT, sort_order INTEGER)');
    await db.execute('CREATE TABLE emergency_types (id INTEGER PRIMARY KEY, category_id INTEGER, name TEXT, slug TEXT)');
    await db.execute('CREATE TABLE protocols (id INTEGER PRIMARY KEY, emergency_type TEXT, title TEXT, warning TEXT, summary TEXT)');
    await db.execute('CREATE TABLE protocol_steps (id INTEGER PRIMARY KEY, protocol_id INTEGER, step_number INTEGER, title TEXT, instruction TEXT, is_critical INTEGER, action_type TEXT)');
    await db.execute('CREATE TABLE emergency_numbers (id INTEGER PRIMARY KEY, country_code TEXT, service_name TEXT, phone_number TEXT)');
    await db.execute('CREATE TABLE emergency_contacts (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, phone_number TEXT, relationship TEXT)');
    await db.execute('CREATE TABLE healthcare_facilities (id INTEGER PRIMARY KEY, name TEXT, facility_type TEXT, phone_number TEXT, emergency_phone TEXT, address TEXT, county TEXT, latitude REAL, longitude REAL, is_emergency_ready INTEGER)');
    await db.execute('CREATE TABLE sync_meta (key TEXT PRIMARY KEY, value TEXT)');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 6) {
      await db.execute('DROP TABLE IF EXISTS protocols');
      await db.execute('DROP TABLE IF EXISTS emergency_types');
      await db.execute('CREATE TABLE emergency_types (id INTEGER PRIMARY KEY, category_id INTEGER, name TEXT, slug TEXT)');
      await db.execute('CREATE TABLE protocols (id INTEGER PRIMARY KEY, emergency_type TEXT, title TEXT, warning TEXT, summary TEXT)');
      await db.delete('sync_meta');
    }
  }

  Future<void> syncDataFromApi() async {
    final data = await ApiService().fetchContent();
    final db = await instance.database;

    await db.delete('categories');
    await db.delete('emergency_types');
    await db.delete('protocols');
    await db.delete('protocol_steps');
    await db.delete('emergency_numbers');
    await db.delete('healthcare_facilities');

    for (var cat in data['categories']) {
      await db.insert('categories', {'id': cat['id'], 'name': jsonEncode(cat['name']), 'icon': cat['icon'] ?? 'medical_services', 'sort_order': cat['sort_order']});
    }

    for (var type in data['emergency_types']) {
      await db.insert('emergency_types', {
        'id': type['id'], 'category_id': type['category_id'],
        'name': jsonEncode(type['name']), 'slug': type['slug']
      });
    }

    for (var proto in data['protocols']) {
      await db.insert('protocols', {
        'id': proto['id'],
        'emergency_type': proto['emergency_type'],
        'title': jsonEncode(proto['title']),
        'warning': proto['warning'] != null ? jsonEncode(proto['warning']) : '',
        'summary': proto['summary'] != null ? jsonEncode(proto['summary']) : '',
      });
      for (var step in proto['steps']) {
        await db.insert('protocol_steps', {
          'id': step['id'], 'protocol_id': proto['id'], 'step_number': step['step_number'],
          'title': step['title'] != null ? jsonEncode(step['title']) : '',
          'instruction': jsonEncode(step['instruction']),
          'is_critical': step['is_critical'] ? 1 : 0, 'action_type': step['action_type'],
        });
      }
    }

    for (var num in data['emergency_numbers']) {
      await db.insert('emergency_numbers', {
        'id': num['id'], 'country_code': num['country_code'],
        'service_name': num['service_name'], 'phone_number': num['phone_number'],
      });
    }

    for (var hosp in data['hospitals']) {
      await db.insert('healthcare_facilities', {
        'id': hosp['id'], 'name': jsonEncode(hosp['name']), 'facility_type': hosp['facility_type'] ?? 'hospital',
        'phone_number': hosp['phone_number'] ?? '', 'emergency_phone': hosp['emergency_phone'] ?? '',
        'address': hosp['address'] ?? '', 'county': hosp['county'] ?? '',
        'latitude': hosp['latitude'] ?? 0.0, 'longitude': hosp['longitude'] ?? 0.0,
        'is_emergency_ready': (hosp['is_emergency_ready'] == true) ? 1 : 0,
      });
    }
  }

  Future<int> getSyncedVersion() async {
    final db = await instance.database;
    final result = await db.query('sync_meta', where: 'key = ?', whereArgs: ['content_version']);
    if (result.isNotEmpty) return int.parse(result.first['value'] as String);
    return 0;
  }

  Future<void> updateSyncMeta(int version) async {
    final db = await instance.database;
    final now = DateTime.now().toIso8601String();
    await db.insert('sync_meta', {'key': 'content_version', 'value': version.toString()}, conflictAlgorithm: ConflictAlgorithm.replace);
    await db.insert('sync_meta', {'key': 'last_synced_at', 'value': now}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getLastSyncedTime() async {
    final db = await instance.database;
    final result = await db.query('sync_meta', where: 'key = ?', whereArgs: ['last_synced_at']);
    if (result.isNotEmpty) return result.first['value'] as String;
    return null;
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await instance.database;
    return await db.query('categories', orderBy: 'sort_order ASC');
  }

  Future<List<Map<String, dynamic>>> getEmergencyTypes(int categoryId) async {
    final db = await instance.database;
    return await db.query('emergency_types', where: 'category_id = ?', whereArgs: [categoryId]);
  }

  Future<Map<String, dynamic>?> getProtocolByEmergencyType(String typeSlug) async {
    final db = await instance.database;
    final result = await db.query('protocols', where: 'emergency_type = ?', whereArgs: [typeSlug], limit: 1);
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getProtocolWithSteps(int protocolId) async {
    final db = await instance.database;
    final protocol = await db.query('protocols', where: 'id = ?', whereArgs: [protocolId]);
    if (protocol.isEmpty) return null;
    final steps = await db.query('protocol_steps', where: 'protocol_id = ?', whereArgs: [protocolId], orderBy: 'step_number ASC');
    return {'protocol': protocol.first, 'steps': steps};
  }

  Future<Map<String, dynamic>?> getPrimaryEmergencyNumber() async {
    final db = await instance.database;
    final result = await db.query('emergency_numbers', where: 'service_name = ?', whereArgs: ['Ambulance'], limit: 1);
    if (result.isNotEmpty) return result.first;
    return null;
  }

  Future<List<Map<String, dynamic>>> getContacts() async {
    final db = await instance.database;
    return await db.query('emergency_contacts');
  }

  Future<int> addContact(String name, String phone, String relationship) async {
    final db = await instance.database;
    return await db.insert('emergency_contacts', {'name': name, 'phone_number': phone, 'relationship': relationship});
  }

  Future<int> deleteContact(int id) async {
    final db = await instance.database;
    return await db.delete('emergency_contacts', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> replaceAllContacts(List<dynamic> contacts) async {
    final db = await instance.database;
    await db.delete('emergency_contacts');
    for (var c in contacts) {
      await db.insert('emergency_contacts', Map<String, dynamic>.from(c));
    }
  }

  Future<List<Map<String, dynamic>>> getHospitals() async {
    final db = await instance.database;
    return await db.query('healthcare_facilities');
  }

  Future<List<Map<String, dynamic>>> searchProtocols(String query) async {
    final db = await instance.database;
    final term = '%$query%';
    return await db.query(
      'protocols',
      where: "title LIKE ? OR summary LIKE ?",
      whereArgs: [term, term],
    );
  }
}
