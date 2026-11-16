import 'package:flutter/material.dart';
import 'core/db_setup.dart' if (dart.library.html) 'core/db_setup_web.dart';
import 'core/theme.dart';
import 'services/language_service.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDatabase();
  await LanguageService.instance.load();
  runApp(const FirstAidApp());
}

class FirstAidApp extends StatelessWidget {
  const FirstAidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'First Aid App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainScreen(),
    );
  }
}
