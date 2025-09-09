// lib/models/reminder.dart
class Reminder {
  final String id;
  final String title;
  final String body;
  final int hour;
  final int minute;
  final bool repeatDaily;
  final bool enabled;
  final String type;
  final int intervalHours;

  Reminder({
    required this.id,
    required this.title,
    required this.body,
    required this.hour,
    required this.minute,
    this.repeatDaily = true,
    this.enabled = true,
    this.type = 'custom',
    this.intervalHours = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'hour': hour,
      'minute': minute,
      'repeatDaily': repeatDaily,
      'enabled': enabled,
      'type': type,
      'intervalHours': intervalHours,
    };
  }

  factory Reminder.fromMap(String id, Map<String, dynamic> map) {
    return Reminder(
      id: id,
      title: map['title']?.toString() ?? 'Reminder',
      body: map['body']?.toString() ?? '',
      hour:
      (map['hour'] is int) ? map['hour'] as int : int.tryParse(map['hour']?.toString() ?? '') ?? 8,
      minute: (map['minute'] is int)
          ? map['minute'] as int
          : int.tryParse(map['minute']?.toString() ?? '') ?? 0,
      repeatDaily: map['repeatDaily'] ?? true,
      enabled: map['enabled'] ?? true,
      type: map['type']?.toString() ?? 'custom',
      intervalHours: (map['intervalHours'] is int)
          ? map['intervalHours'] as int
          : int.tryParse(map['intervalHours']?.toString() ?? '') ?? 0,
    );
  }

  Reminder copyWith({
    String? id,
    String? title,
    String? body,
    int? hour,
    int? minute,
    bool? repeatDaily,
    bool? enabled,
    String? type,
    int? intervalHours,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      repeatDaily: repeatDaily ?? this.repeatDaily,
      enabled: enabled ?? this.enabled,
      type: type ?? this.type,
      intervalHours: intervalHours ?? this.intervalHours,
    );
  }
}
