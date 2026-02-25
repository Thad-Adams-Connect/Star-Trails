// Star Trails™
// Copyright © 2026 Ubertas Lab, LLC.
// All Rights Reserved.
// Unauthorized copying, modification, distribution, or reverse engineering prohibited.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import '../models/teacher_dashboard.dart';
import '../utils/json_utils.dart';

/// Service for managing teacher dashboard data.
/// Handles device ID generation, session tracking, and reflection storage.
/// All data is persisted locally using shared_preferences (works on Flutter Web).
class TeacherDashboardService {
  static const String _dataKey = 'teacher_dashboard_data';
  static const String _checksumKey = 'teacher_dashboard_checksum';

  TeacherDashboardData _data = TeacherDashboardData(deviceId: '');
  bool _initialized = false;

  /// Initialize the service and load existing data.
  Future<void> initialize() async {
    if (_initialized) return;
    _data = await _load();
    if (_data.deviceId.isEmpty) {
      _data = _data.copyWith(deviceId: _generateDeviceId());
      await _save();
    }
    _initialized = true;
  }

  /// Get current dashboard data.
  TeacherDashboardData getData() => _data;

  /// Get the unique device ID for this installation.
  String getDeviceId() => _data.deviceId;

  /// Update captain and ship names.
  Future<TeacherDashboardData> updatePlayerNames({
    required String captainName,
    required String shipName,
  }) async {
    await _ensureInitialized();
    _data = _data.copyWith(
      captainName: captainName,
      shipName: shipName,
    );
    await _save();
    return _data;
  }

  /// Start a new session. Returns the updated data.
  Future<TeacherDashboardData> startSession() async {
    await _ensureInitialized();
    final sessionId = _generateUniqueId();
    final newSession = SessionRecord(
      id: sessionId,
      startTime: DateTime.now(),
    );
    final updatedSessions = [..._data.sessions, newSession];
    _data = _data.copyWith(sessions: updatedSessions);
    await _save();
    return _data;
  }

  /// End the current session. Returns the updated data.
  /// Optional run summary data can be provided to record session statistics.
  Future<TeacherDashboardData> endSession({
    int? startingCredits,
    int? finalCredits,
    int? totalFuelUsed,
    int? totalCreditsSpentOnFuel,
    int? totalCreditsSpentOnGoods,
    int? totalCreditsSpentOnUpgrades,
    int? totalCreditsEarned,
  }) async {
    await _ensureInitialized();
    if (_data.sessions.isEmpty) return _data;

    final lastSessionIndex = _data.sessions.length - 1;
    final lastSession = _data.sessions[lastSessionIndex];

    // Don't end a session that's already ended
    if (lastSession.endTime != null) return _data;

    final now = DateTime.now();
    final duration = now.difference(lastSession.startTime).inMilliseconds;
    final endedSession = lastSession.copyWith(
      endTime: now,
      durationMs: duration,
      startingCredits: startingCredits,
      finalCredits: finalCredits,
      totalFuelUsed: totalFuelUsed,
      totalCreditsSpentOnFuel: totalCreditsSpentOnFuel,
      totalCreditsSpentOnGoods: totalCreditsSpentOnGoods,
      totalCreditsSpentOnUpgrades: totalCreditsSpentOnUpgrades,
      totalCreditsEarned: totalCreditsEarned,
    );

    final updatedSessions = [..._data.sessions];
    updatedSessions[lastSessionIndex] = endedSession;

    // Add duration to total playtime
    final newTotalPlaytime = _data.totalPlaytimeMs + duration;

    _data = _data.copyWith(
      sessions: updatedSessions,
      totalPlaytimeMs: newTotalPlaytime,
    );
    await _save();
    return _data;
  }

  /// Increment missions completed in the current session.
  Future<TeacherDashboardData> recordMissionCompleted() async {
    return _incrementCurrentSessionCounter(isMission: true);
  }

  /// Increment trades completed in the current session.
  Future<TeacherDashboardData> recordTradeCompleted() async {
    return _incrementCurrentSessionCounter(isMission: false);
  }

  Future<TeacherDashboardData> _incrementCurrentSessionCounter({
    required bool isMission,
  }) async {
    await _ensureInitialized();
    if (_data.sessions.isEmpty) {
      await startSession();
    }

    final lastSessionIndex = _data.sessions.length - 1;
    final lastSession = _data.sessions[lastSessionIndex];
    final updatedSession = isMission
        ? lastSession.copyWith(
            missionsCompleted: lastSession.missionsCompleted + 1)
        : lastSession.copyWith(
            tradesCompleted: lastSession.tradesCompleted + 1);

    final updatedSessions = [..._data.sessions];
    updatedSessions[lastSessionIndex] = updatedSession;
    _data = _data.copyWith(sessions: updatedSessions);
    await _save();
    return _data;
  }

  /// Add a reflection question and answer.
  Future<TeacherDashboardData> addReflection({
    required String sessionId,
    required String question,
    required String answer,
  }) async {
    await _ensureInitialized();
    final reflection = ReflectionRecord(
      id: _generateUniqueId(),
      timestamp: DateTime.now(),
      sessionId: sessionId,
      deviceId: _data.deviceId,
      question: question,
      answer: answer,
    );
    final updatedReflections = [..._data.reflections, reflection];
    _data = _data.copyWith(reflections: updatedReflections);
    await _save();
    return _data;
  }

  /// Add a system entry to the current session logbook.
  Future<TeacherDashboardData> addSystemEntry({
    required String sessionId,
    required String systemId,
    required String historyText,
  }) async {
    await _ensureInitialized();
    final entry = SystemEntryRecord(
      id: _generateUniqueId(),
      timestamp: DateTime.now(),
      sessionId: sessionId,
      systemId: systemId,
      historyText: historyText,
    );
    final updatedEntries = [..._data.systemEntries, entry];
    _data = _data.copyWith(systemEntries: updatedEntries);
    await _save();
    return _data;
  }

  /// Get all reflection records.
  List<ReflectionRecord> getReflections() => _data.reflections;

  /// Get reflection by ID.
  ReflectionRecord? getReflectionById(String id) {
    try {
      return _data.reflections.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Update a reflection answer (preserves question).
  Future<TeacherDashboardData> updateReflectionAnswer({
    required String reflectionId,
    required String newAnswer,
  }) async {
    await _ensureInitialized();
    final reflections = _data.reflections;
    final index = reflections.indexWhere((r) => r.id == reflectionId);
    if (index == -1) return _data;

    final updatedReflection = reflections[index].copyWith(answer: newAnswer);
    final updatedReflections = [...reflections];
    updatedReflections[index] = updatedReflection;
    _data = _data.copyWith(reflections: updatedReflections);
    await _save();
    return _data;
  }

  /// Get all sessions.
  List<SessionRecord> getSessions() => _data.sessions;

  /// Get current session ID (ID of the last session).
  String getCurrentSessionId() {
    if (_data.sessions.isEmpty) return '';
    return _data.sessions.last.id;
  }

  /// Get total playtime in milliseconds.
  int getTotalPlaytimeMs() => _data.totalPlaytimeMs;

  /// Clear all teacher dashboard data (including device ID).
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dataKey);
    await prefs.remove(_checksumKey);
    _data = TeacherDashboardData(deviceId: _generateDeviceId());
    _initialized = false;
    await initialize();
  }

  /// Export dashboard data as JSON string (for debugging/backup).
  String exportAsJson() {
    return jsonEncode(_data.toJson());
  }

  /// Ensure service is initialized.
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  /// Generate a unique device ID (UUID-like string).
  String _generateDeviceId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    final combined = '$timestamp-$random';
    final bytes = utf8.encode(combined);
    final hash = sha256.convert(bytes).toString();
    return hash.substring(0, 16); // Use first 16 chars of SHA256
  }

  /// Generate a unique ID for sessions and reflections.
  String _generateUniqueId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    final combined = '$timestamp-$random-${_data.deviceId}';
    final bytes = utf8.encode(combined);
    final hash = sha256.convert(bytes).toString();
    return hash.substring(0, 16);
  }

  /// Load dashboard data from storage.
  Future<TeacherDashboardData> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_dataKey);
      final savedChecksum = prefs.getString(_checksumKey);

      if (jsonStr == null || savedChecksum == null) {
        return TeacherDashboardData(deviceId: '');
      }

      // Verify integrity
      final calculatedChecksum = JsonUtils.calculateChecksum(jsonStr);
      if (calculatedChecksum != savedChecksum) {
        await _clearStorage();
        return TeacherDashboardData(deviceId: '');
      }

      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return TeacherDashboardData.fromJson(json);
    } catch (e) {
      await _clearStorage();
      return TeacherDashboardData(deviceId: '');
    }
  }

  /// Save dashboard data to storage.
  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = JsonUtils.toStableJson(_data.toJson());
      final checksum = JsonUtils.calculateChecksum(json);

      await prefs.setString(_dataKey, json);
      await prefs.setString(_checksumKey, checksum);
    } catch (e) {
      // Silently fail - this is a non-critical save
    }
  }

  /// Clear storage.
  Future<void> _clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dataKey);
    await prefs.remove(_checksumKey);
  }
}
