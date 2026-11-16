import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/database_helper.dart';
import '../services/language_service.dart';
import '../services/tts_service.dart';
import 'emergency_screen.dart';

class ProtocolScreen extends StatefulWidget {
  final int protocolId;
  const ProtocolScreen({super.key, required this.protocolId});

  @override
  State<ProtocolScreen> createState() => _ProtocolScreenState();
}

class _ProtocolScreenState extends State<ProtocolScreen> {
  Map<String, dynamic>? _data;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _loadProtocol();
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  Future<void> _loadProtocol() async {
    final data = await DatabaseHelper.instance.getProtocolWithSteps(widget.protocolId);
    setState(() { _data = data; });
  }

  Future<void> _toggleSpeech() async {
    final ls = LanguageService.instance;
    
    if (_isSpeaking) {
      await TtsService.instance.stop();
      setState(() => _isSpeaking = false);
      return;
    }

    if (_data == null) return;

    final protocol = _data!['protocol'];
    final steps = _data!['steps'] as List<dynamic>;

    // Build the script
    StringBuffer script = StringBuffer();
    script.write("${ls.tr(protocol['title'])}. ");
    script.write("${ls.tr(protocol['summary'])}. ");
    script.write("${ls.tr(protocol['warning'])}. ");

    for (var step in steps) {
      script.write("Step ${step['step_number']}. ");
      script.write("${ls.tr(step['title'])}. ");
      script.write("${ls.tr(step['instruction'])}. ");
    }

    setState(() => _isSpeaking = true);
    
    // We pass the whole script. If the user wants to stop, they press the button again.
    await TtsService.instance.speak(script.toString());
    
    // Note: To handle auto-reset when speech finishes, we'd need an event listener 
    // on flutter_tts. For MVP, we let the user manually stop it.
  }

  @override
  Widget build(BuildContext context) {
    if (_data == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final ls = LanguageService.instance;
    final protocol = _data!['protocol'];
    final steps = _data!['steps'] as List<dynamic>;
    final warning = ls.tr(protocol['warning']);

    return Scaffold(
      appBar: AppBar(
        title: Text(ls.t('First aid', 'Msaada wa kwanza')),
        actions: [
          IconButton(
            icon: Icon(_isSpeaking ? Icons.stop_circle : Icons.volume_up_outlined, 
                       color: _isSpeaking ? AppTheme.primaryRed : AppTheme.textDark), 
            onPressed: _toggleSpeech
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ls.tr(protocol['title']), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(ls.tr(protocol['summary']), style: const TextStyle(color: AppTheme.textMuted)),
            const SizedBox(height: 16),
            
            // The Big "Listen to steps" Button
            GestureDetector(
              onTap: _toggleSpeech,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.sageGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_isSpeaking ? Icons.stop : Icons.play_arrow, color: AppTheme.textDark),
                    const SizedBox(width: 8),
                    Text(
                      _isSpeaking 
                        ? ls.t('Stop listening', 'Acha kusikiliza') 
                        : ls.t('Listen to steps', 'Sikiliza hatua'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (warning.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.softRedBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryRed.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppTheme.primaryRed),
                    const SizedBox(width: 12),
                    Expanded(child: Text(warning, style: const TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.w500))),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            
            ...steps.map((step) => _buildStepCard(step, ls)).toList(),
            
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyScreen())),
              icon: const Icon(Icons.phone),
              label: Text(ls.t('Get emergency help', 'Pata msaada wa dharura'), style: const TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard(dynamic step, LanguageService ls) {
    final isCritical = step['is_critical'] == 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: isCritical ? AppTheme.primaryRed : AppTheme.textDark,
                child: Text('${step['step_number']}', style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(ls.tr(step['title']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
            ],
          ),
          const SizedBox(height: 12),
          Text(ls.tr(step['instruction']), style: const TextStyle(color: AppTheme.textMuted, height: 1.4)),
        ],
      ),
    );
  }
}
