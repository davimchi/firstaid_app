class Protocol {
  final int id;
  final String title;
  final String warning;
  final String summary;
  final List<ProtocolStep> steps;

  Protocol({required this.id, required this.title, required this.warning, required this.summary, required this.steps});

  factory Protocol.fromJson(Map<String, dynamic> json) {
    return Protocol(
      id: json['id'],
      title: json['title']?['en'] ?? 'Protocol', // Default to English
      warning: json['warning']?['en'] ?? '',
      summary: json['summary']?['en'] ?? '',
      steps: (json['steps'] as List? ?? [])
          .map((s) => ProtocolStep.fromJson(s))
          .toList(),
    );
  }
}

class ProtocolStep {
  final int stepNumber;
  final String title;
  final String instruction;
  final bool isCritical;
  final String actionType;

  ProtocolStep({
    required this.stepNumber,
    required this.title,
    required this.instruction,
    required this.isCritical,
    required this.actionType,
  });

  factory ProtocolStep.fromJson(Map<String, dynamic> json) {
    return ProtocolStep(
      stepNumber: json['step_number'],
      title: json['title']?['en'] ?? '',
      instruction: json['instruction']?['en'] ?? '',
      isCritical: json['is_critical'] ?? false,
      actionType: json['action_type'] ?? 'instruction',
    );
  }
}
