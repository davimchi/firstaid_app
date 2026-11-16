import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../services/database_helper.dart';
import '../services/language_service.dart';
import '../services/api_service.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  String _emergencyNumber = '999';
  String _countryCode = 'KE';
  List<Map<String, dynamic>> _contacts = [];
  bool _loading = true;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final numData = await DatabaseHelper.instance.getPrimaryEmergencyNumber();
    final contacts = await DatabaseHelper.instance.getContacts();
    setState(() {
      if (numData != null) {
        _emergencyNumber = numData['phone_number'];
        _countryCode = numData['country_code'];
      }
      _contacts = contacts;
      _loading = false;
    });
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _showAddContactDialog() {
    final ls = LanguageService.instance;
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(ls.t('Add Trusted Contact', 'Ongeza Mtu Unayemwamini')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: ls.t('Name', 'Jina'))),
            TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: ls.t('Phone Number', 'Nambari ya Simu'))),
            TextField(controller: relationController, decoration: InputDecoration(labelText: ls.t('Relationship (e.g. Spouse)', 'Uhusiano (mf. Mke/Mume)'))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(ls.t('Cancel', 'Ghairi'))),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                await DatabaseHelper.instance.addContact(nameController.text, phoneController.text, relationController.text);
                if (mounted) Navigator.pop(dialogContext);
                _loadData();
              }
            },
            child: Text(ls.t('Save', 'Hifadhi')),
          ),
        ],
      ),
    );
  }

  Future<void> _showBackupDialog() async {
    final ls = LanguageService.instance;
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(ls.t('Cloud Backup', 'Hifadhi Mtandaoni')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(ls.t('Create an account to safely back up your emergency contacts.', 'Unda akaunti ili uhifadhi taarifa zako salama.')),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, decoration: InputDecoration(labelText: ls.t('Full Name', 'Jina Kamili'))),
            TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: ls.t('Email', 'Barua Pepe'))),
            TextField(controller: passCtrl, obscureText: true, decoration: InputDecoration(labelText: ls.t('Password', 'Nenosiri'))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(ls.t('Cancel', 'Ghairi'))),
          ElevatedButton(
            onPressed: () async {
              if (emailCtrl.text.isNotEmpty && passCtrl.text.isNotEmpty) {
                Navigator.pop(dialogContext); // Close the dialog
                setState(() => _syncing = true);
                
                try {
                  await ApiService().upgradeAccount(nameCtrl.text, emailCtrl.text, passCtrl.text);
                  await ApiService().backupContacts(_contacts);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(ls.t('Contacts backed up successfully!', 'Mawasiliano yamehifadhiwa!')), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    // Clean up the error message for the user
                    String errorMsg = e.toString().replaceAll('Exception: ', '');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(errorMsg), backgroundColor: AppTheme.primaryRed),
                    );
                  }
                }
                
                if (mounted) setState(() => _syncing = false);
              }
            },
            child: Text(ls.t('Backup Now', 'Hifadhi Sasa')),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreContacts() async {
    final ls = LanguageService.instance;
    setState(() => _syncing = true);
    try {
      final apiContacts = await ApiService().restoreContacts();
      await DatabaseHelper.instance.replaceAllContacts(apiContacts);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ls.t('Contacts restored successfully!', 'Mawasiliano yamerejeshwa!')), backgroundColor: Colors.green),
        );
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: AppTheme.primaryRed),
        );
      }
    }
    if (mounted) setState(() => _syncing = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
            Expanded(
              child: Text(ls.t('Emergency help', 'Msaada wa dharura'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: _syncing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator()) : const Icon(Icons.cloud_sync),
            onPressed: _syncing ? null : _restoreContacts,
            tooltip: ls.t('Restore Contacts from Cloud', 'Rejesha Mawasiliano kutoka Mtandaoni'),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ls.t('Help starts here.', 'Msaada unaanza hapa.'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(ls.t('If there\'s immediate danger, call now.', 'Ikiwa kuna hatari ya haraka, piga simu sasa.'), style: const TextStyle(color: AppTheme.textMuted)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppTheme.primaryRed, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(ls.t('EMERGENCY SERVICES', 'HUDUMA ZA DHARURA'), style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      Text(ls.t('Change region', 'Badilisha eneo'), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_emergencyNumber, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  Text(_countryCode == 'KE' ? 'Kenya' : _countryCode, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _makePhoneCall(_emergencyNumber),
                    icon: const Icon(Icons.phone, size: 18),
                    label: Text('${ls.t('Call', 'Piga')} $_emergencyNumber'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.primaryRed, minimumSize: const Size(double.infinity, 50)),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(ls.t('Your people', 'Watu wako'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _showBackupDialog,
                  icon: const Icon(Icons.cloud_upload, size: 16),
                  label: Text(ls.t('Backup', 'Hifadhi')),
                )
              ],
            ),
            const SizedBox(height: 12),
            ..._contacts.map((c) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: AppTheme.sageGreen, child: Icon(Icons.person, color: AppTheme.textDark)),
                title: Text(c['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(c['relationship'] ?? ls.t('Contact', 'Mtu wa kuwasiliana')),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.phone, color: Colors.green), onPressed: () => _makePhoneCall(c['phone_number'])),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async {
                      await DatabaseHelper.instance.deleteContact(c['id']);
                      _loadData();
                    }),
                  ],
                ),
              ),
            )).toList(),
            GestureDetector(
              onTap: _showAddContactDialog,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
                child: Row(
                  children: [
                    const CircleAvatar(backgroundColor: AppTheme.border, child: Icon(Icons.add, color: AppTheme.textDark)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ls.t('Add a trusted contact', 'Ongeza mtu unayemwamini'), style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(ls.t('Keep someone close, just a tap away', 'Weka mtu karibu, mbali ya kugusa tu'), style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
