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
  final List<SystemEntryRecord> systemEntries;

  TeacherDashboardData({
    required this.deviceId,
    this.captainName = '',
    this.shipName = '',
    this.totalPlaytimeMs = 0,
    this.sessions = const [],
    this.reflections = const [],
    this.systemEntries = const [],
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
      'systemEntries': systemEntries.map((e) => e.toJson()).toList(),
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
      systemEntries: (json['systemEntries'] as List?)
              ?.cast<Map<String, dynamic>>()
              .map(SystemEntryRecord.fromJson)
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
    List<SystemEntryRecord>? systemEntries,
  }) {
    return TeacherDashboardData(
      deviceId: deviceId ?? this.deviceId,
      captainName: captainName ?? this.captainName,
      shipName: shipName ?? this.shipName,
      totalPlaytimeMs: totalPlaytimeMs ?? this.totalPlaytimeMs,
      sessions: sessions ?? this.sessions,
      reflections: reflections ?? this.reflections,
      systemEntries: systemEntries ?? this.systemEntries,
    );
  }
}

class SystemEntryRecord {
  final String id;
  final DateTime timestamp;
  final String sessionId;
  final String systemId;
  final String historyText;

  SystemEntryRecord({
    required this.id,
    required this.timestamp,
    required this.sessionId,
    required this.systemId,
    required this.historyText,
  });

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'sessionId': sessionId,
      'systemId': systemId,
      'historyText': historyText,
    };
  }

  /// Create from JSON.
  factory SystemEntryRecord.fromJson(Map<String, dynamic> json) {
    return SystemEntryRecord(
      id: json['id'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String),
      sessionId: json['sessionId'] as String? ?? '',
      systemId: json['systemId'] as String? ?? '',
      historyText: json['historyText'] as String? ?? '',
    );
  }

  /// Create a copy with updated fields.
  SystemEntryRecord copyWith({
    String? id,
    DateTime? timestamp,
    String? sessionId,
    String? systemId,
    String? historyText,
  }) {
    return SystemEntryRecord(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      sessionId: sessionId ?? this.sessionId,
      systemId: systemId ?? this.systemId,
      historyText: historyText ?? this.historyText,
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
  
  // Run summary data (captured at session end)
  final int? startingCredits;
  final int? finalCredits;
  final int? totalFuelUsed;
  final int? totalCreditsSpentOnFuel;
  final int? totalCreditsSpentOnGoods;
  final int? totalCreditsSpentOnUpgrades;
  final int? totalCreditsEarned;

  SessionRecord({
    required this.id,
    required this.startTime,
    this.endTime,
    this.durationMs = 0,
    this.missionsCompleted = 0,
    this.tradesCompleted = 0,
    this.startingCredits,
    this.finalCredits,
    this.totalFuelUsed,
    this.totalCreditsSpentOnFuel,
    this.totalCreditsSpentOnGoods,
    this.totalCreditsSpentOnUpgrades,
    this.totalCreditsEarned,
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
      'startingCredits': startingCredits,
      'finalCredits': finalCredits,
      'totalFuelUsed': totalFuelUsed,
      'totalCreditsSpentOnFuel': totalCreditsSpentOnFuel,
      'totalCreditsSpentOnGoods': totalCreditsSpentOnGoods,
      'totalCreditsSpentOnUpgrades': totalCreditsSpentOnUpgrades,
      'totalCreditsEarned': totalCreditsEarned,
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
      startingCredits: json['startingCredits'] as int?,
      finalCredits: json['finalCredits'] as int?,
      totalFuelUsed: json['totalFuelUsed'] as int?,
      totalCreditsSpentOnFuel: json['totalCreditsSpentOnFuel'] as int?,
      totalCreditsSpentOnGoods: json['totalCreditsSpentOnGoods'] as int?,
      totalCreditsSpentOnUpgrades: json['totalCreditsSpentOnUpgrades'] as int?,
      totalCreditsEarned: json['totalCreditsEarned'] as int?,
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
    int? startingCredits,
    int? finalCredits,
    int? totalFuelUsed,
    int? totalCreditsSpentOnFuel,
    int? totalCreditsSpentOnGoods,
    int? totalCreditsSpentOnUpgrades,
    int? totalCreditsEarned,
  }) {
    return SessionRecord(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMs: durationMs ?? this.durationMs,
      missionsCompleted: missionsCompleted ?? this.missionsCompleted,
      tradesCompleted: tradesCompleted ?? this.tradesCompleted,
      startingCredits: startingCredits ?? this.startingCredits,
      finalCredits: finalCredits ?? this.finalCredits,
      totalFuelUsed: totalFuelUsed ?? this.totalFuelUsed,
      totalCreditsSpentOnFuel: totalCreditsSpentOnFuel ?? this.totalCreditsSpentOnFuel,
      totalCreditsSpentOnGoods: totalCreditsSpentOnGoods ?? this.totalCreditsSpentOnGoods,
      totalCreditsSpentOnUpgrades: totalCreditsSpentOnUpgrades ?? this.totalCreditsSpentOnUpgrades,
      totalCreditsEarned: totalCreditsEarned ?? this.totalCreditsEarned,
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
