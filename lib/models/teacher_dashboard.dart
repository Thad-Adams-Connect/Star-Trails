/// Models for the Teacher Dashboard data layer.
/// Tracks device ID, sessions, playtime, and reflection data.
library;

class TeacherDashboardData {
  final String deviceId;
  final String captainName;
  final String shipName;
  final int totalPlaytimeMs;
  final List<SessionRecord> sessions;
  final List<ReflectionRecord> reflections;

  TeacherDashboardData({
    required this.deviceId,
    this.captainName = '',
    this.shipName = '',
    this.totalPlaytimeMs = 0,
    this.sessions = const [],
    this.reflections = const [],
  });

  /// Convert to JSON for persistence.
  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'captainName': captainName,
      'shipName': shipName,
      'totalPlaytimeMs': totalPlaytimeMs,
      'sessions': sessions.map((s) => s.toJson()).toList(),
      'reflections': reflections.map((r) => r.toJson()).toList(),
    };
  }

  /// Create from JSON.
  factory TeacherDashboardData.fromJson(Map<String, dynamic> json) {
    return TeacherDashboardData(
      deviceId: json['deviceId'] as String? ?? '',
      captainName: json['captainName'] as String? ?? '',
      shipName: json['shipName'] as String? ?? '',
      totalPlaytimeMs: json['totalPlaytimeMs'] as int? ?? 0,
      sessions: (json['sessions'] as List?)
              ?.cast<Map<String, dynamic>>()
              .map(SessionRecord.fromJson)
              .toList() ??
          [],
      reflections: (json['reflections'] as List?)
              ?.cast<Map<String, dynamic>>()
              .map(ReflectionRecord.fromJson)
              .toList() ??
          [],
    );
  }

  /// Create a copy with updated fields.
  TeacherDashboardData copyWith({
    String? deviceId,
    String? captainName,
    String? shipName,
    int? totalPlaytimeMs,
    List<SessionRecord>? sessions,
    List<ReflectionRecord>? reflections,
  }) {
    return TeacherDashboardData(
      deviceId: deviceId ?? this.deviceId,
      captainName: captainName ?? this.captainName,
      shipName: shipName ?? this.shipName,
      totalPlaytimeMs: totalPlaytimeMs ?? this.totalPlaytimeMs,
      sessions: sessions ?? this.sessions,
      reflections: reflections ?? this.reflections,
    );
  }
}

class SessionRecord {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMs;
  final int missionsCompleted;
  final int tradesCompleted;

  SessionRecord({
    required this.id,
    required this.startTime,
    this.endTime,
    this.durationMs = 0,
    this.missionsCompleted = 0,
    this.tradesCompleted = 0,
  });

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'durationMs': durationMs,
      'missionsCompleted': missionsCompleted,
      'tradesCompleted': tradesCompleted,
    };
  }

  /// Create from JSON.
  factory SessionRecord.fromJson(Map<String, dynamic> json) {
    return SessionRecord(
      id: json['id'] as String? ?? '',
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      durationMs: json['durationMs'] as int? ?? 0,
      missionsCompleted: json['missionsCompleted'] as int? ?? 0,
      tradesCompleted: json['tradesCompleted'] as int? ?? 0,
    );
  }

  /// Create a copy with updated fields.
  SessionRecord copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMs,
    int? missionsCompleted,
    int? tradesCompleted,
  }) {
    return SessionRecord(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMs: durationMs ?? this.durationMs,
      missionsCompleted: missionsCompleted ?? this.missionsCompleted,
      tradesCompleted: tradesCompleted ?? this.tradesCompleted,
    );
  }
}

class ReflectionRecord {
  final String id;
  final DateTime timestamp;
  final String sessionId;
  final String deviceId;
  final String question;
  final String answer;

  ReflectionRecord({
    required this.id,
    required this.timestamp,
    required this.sessionId,
    required this.deviceId,
    required this.question,
    required this.answer,
  });

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'sessionId': sessionId,
      'deviceId': deviceId,
      'question': question,
      'answer': answer,
    };
  }

  /// Create from JSON.
  factory ReflectionRecord.fromJson(Map<String, dynamic> json) {
    return ReflectionRecord(
      id: json['id'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String),
      sessionId: json['sessionId'] as String? ?? '',
      deviceId: json['deviceId'] as String? ?? '',
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
    );
  }

  /// Create a copy with updated fields.
  ReflectionRecord copyWith({
    String? id,
    DateTime? timestamp,
    String? sessionId,
    String? deviceId,
    String? question,
    String? answer,
  }) {
    return ReflectionRecord(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      sessionId: sessionId ?? this.sessionId,
      deviceId: deviceId ?? this.deviceId,
      question: question ?? this.question,
      answer: answer ?? this.answer,
    );
  }
}
