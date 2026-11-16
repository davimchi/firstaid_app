import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/database_helper.dart';
import '../services/language_service.dart';
import 'protocol_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await DatabaseHelper.instance.getCategories();
    if (mounted) {
      setState(() {
        _categories = cats;
        _loading = false;
      });
    }
  }

  Future<void> _openCategory(int categoryId) async {
    final ls = LanguageService.instance;
    final protocolId = await DatabaseHelper.instance.getFirstProtocolIdForCategory(categoryId);
    
    if (!mounted) return;
    if (protocolId != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ProtocolScreen(protocolId: protocolId)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ls.t('No published protocol available for this category yet.', 'Hakuna mwongozo uliochapishwa kwa kitengo hiki bado.'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ls = LanguageService.instance;
    
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

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
              child: Text(ls.t('What\'s happening?', 'Nini kinaendelea?'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ls.t('Select a situation or symptom', 'Chagua hali au dalili'), style: const TextStyle(color: AppTheme.textMuted)),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.8,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                return GestureDetector(
                  onTap: () => _openCategory(cat['id']),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.sageGreen, 
                      borderRadius: BorderRadius.circular(16)
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.medical_services, size: 32, color: AppTheme.textDark),
                        const SizedBox(height: 12),
                        Text(
                          ls.tr(cat['name']), 
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark)
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
