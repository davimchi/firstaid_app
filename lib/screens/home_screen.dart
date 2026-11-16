import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../services/database_helper.dart';
import '../services/sync_service.dart';
import '../services/language_service.dart';
import 'protocol_screen.dart';
import 'emergency_screen.dart';
import 'hospital_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String _lastSyncedText = '';
  String _searchQuery = '';
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await SyncService.instance.checkAndSync();
    final lastSynced = await DatabaseHelper.instance.getLastSyncedTime();

    String syncedText = '';
    if (lastSynced != null) {
      final dt = DateTime.parse(lastSynced);
      syncedText = DateFormat('HH:mm').format(dt);
    }

    if (mounted) {
      setState(() {
        _lastSyncedText = syncedText;
        _isLoading = false;
      });
    }
  }

  Future<void> _performSearch(String query) async {
    setState(() => _searchQuery = query);
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final results = await DatabaseHelper.instance.searchProtocols(query);
    if (mounted) setState(() => _searchResults = results);
  }

  Future<void> _toggleLanguage() async {
    final next = LanguageService.instance.currentLocale == 'en' ? 'sw' : 'en';
    await LanguageService.instance.setLocale(next);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final ls = LanguageService.instance;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/images/logo.png', width: 36, height: 36, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Text(ls.t('First Aid Guide', 'Mwongozo wa Msaada'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: _toggleLanguage,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.border)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('EN', style: TextStyle(fontSize: 11, fontWeight: ls.currentLocale == 'en' ? FontWeight.bold : FontWeight.normal, color: ls.currentLocale == 'en' ? AppTheme.primaryRed : AppTheme.textMuted)),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('|', style: TextStyle(fontSize: 11, color: AppTheme.border))),
                  Text('SW', style: TextStyle(fontSize: 11, fontWeight: ls.currentLocale == 'sw' ? FontWeight.bold : FontWeight.normal, color: ls.currentLocale == 'sw' ? AppTheme.primaryRed : AppTheme.textMuted)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ls.t('Ready.', 'Tayari.'), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 4),
            Text(ls.t('A little calm. A clear next step.', 'Utulivu kidogo. Hatua inayofuata.'), style: const TextStyle(color: AppTheme.textMuted)),
            const SizedBox(height: 24),

            // Red Emergency Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppTheme.primaryRed, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ls.t('WHEN EVERY SECOND COUNTS', 'WAKATI KILA SEKUNDE INA HESABIKA'), style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  Text(ls.t('You don\'t have to\nhandle it alone.', 'Huna budi\nkushughulikia peke yako.'), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, height: 1.2)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyScreen())),
                    icon: const Icon(Icons.phone, size: 18),
                    label: Text(ls.t('Get emergency help', 'Pata msaada wa dharura')),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.primaryRed),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Search
            TextField(
              onChanged: _performSearch,
              decoration: InputDecoration(
                hintText: ls.t('Search situations or symptoms', 'Tafuta hali au dalili'),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),

            if (_searchQuery.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12), 
                  border: Border.all(color: AppTheme.border)
                ),
                child: Material(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias, // Ensures the ripple stays inside the rounded corners
                  child: _searchResults.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(ls.t('No results found.', 'Hakuna matokeo yaliyopatikana.'), style: const TextStyle(color: AppTheme.textMuted)),
                        )
                      : Column(
                          children: _searchResults.map((r) => ListTile(
                            title: Text(ls.tr(r['title']), style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(ls.tr(r['category_name']), style: const TextStyle(color: AppTheme.textMuted)),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProtocolScreen(protocolId: r['id']))),
                          )).toList(),
                        ),
                ),
              ),
            const SizedBox(height: 24),

            // Hospital Locator
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HospitalScreen())),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
                child: Row(
                  children: [
                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.primaryRed.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.local_hospital, color: AppTheme.primaryRed, size: 20)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ls.t('Find nearby hospital', 'Pata hospitali iliyo karibu'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(ls.t('Locate the closest emergency care', 'Pata huduma ya dharura iliyo karibu zaidi'), style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Offline Status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.sageGreen.withOpacity(0.4), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(ls.t('Ready, even offline', 'Tayari, hata nje ya mtandao'), style: const TextStyle(fontWeight: FontWeight.w500)),
                  const Spacer(),
                  Text('${ls.t('Last synced', 'Ilisasishwa')}: $_lastSyncedText', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
