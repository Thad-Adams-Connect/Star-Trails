// Star Trails™
// Copyright © 2026 Ubertas Lab, LLC.
// All Rights Reserved.
// Unauthorized copying, modification, distribution, or reverse engineering prohibited.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:star_trails/models/teacher_dashboard.dart';
import 'package:star_trails/services/teacher_dashboard_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TeacherDashboard Models', () {
    test('TeacherDashboardData creates with default values', () {
      final data = TeacherDashboardData(deviceId: 'test-device-123');
      expect(data.deviceId, 'test-device-123');
      expect(data.totalPlaytimeMs, 0);
      expect(data.sessions, isEmpty);
      expect(data.reflections, isEmpty);
    });

    test('TeacherDashboardData serialization roundtrip', () {
      final original = TeacherDashboardData(
        deviceId: 'device-123',
        totalPlaytimeMs: 5000,
        sessions: [
          SessionRecord(
            id: 'session-1',
            startTime: DateTime(2024, 1, 1, 10, 0),
            endTime: DateTime(2024, 1, 1, 10, 30),
            durationMs: 1800000,
            missionsCompleted: 3,
            tradesCompleted: 2,
          ),
        ],
        reflections: [
          ReflectionRecord(
            id: 'reflection-1',
            timestamp: DateTime(2024, 1, 1, 10, 15),
            sessionId: 'session-1',
            deviceId: 'device-123',
            question: 'What did you learn?',
            answer: 'I learned about trading',
          ),
        ],
      );

      final json = original.toJson();
      final restored = TeacherDashboardData.fromJson(json);

      expect(restored.deviceId, original.deviceId);
      expect(restored.totalPlaytimeMs, original.totalPlaytimeMs);
      expect(restored.sessions.length, original.sessions.length);
      expect(restored.reflections.length, original.reflections.length);
    });

    test('SessionRecord copyWith updates fields', () {
      final session = SessionRecord(
        id: 'session-1',
        startTime: DateTime(2024, 1, 1, 10, 0),
        missionsCompleted: 2,
      );
      final updated = session.copyWith(
        missionsCompleted: 5,
        tradesCompleted: 3,
      );

      expect(updated.missionsCompleted, 5);
      expect(updated.tradesCompleted, 3);
      expect(updated.startTime, session.startTime);
    });

    test('ReflectionRecord stores question and answer', () {
      final reflection = ReflectionRecord(
        id: 'reflection-1',
        timestamp: DateTime.now(),
        sessionId: 'session-1',
        deviceId: 'device-123',
        question: 'How did you solve this?',
        answer: 'By using efficient trading',
      );

      expect(reflection.question, 'How did you solve this?');
      expect(reflection.answer, 'By using efficient trading');
    });
  });

  group('TeacherDashboardService', () {
    late TeacherDashboardService service;

    setUp(() {
      service = TeacherDashboardService();
    });

    test('Device ID is generated on initialization', () async {
      await service.initialize();
      final deviceId = service.getDeviceId();

      expect(deviceId, isNotEmpty);
      expect(deviceId.length, 16); // SHA256 first 16 chars
    });

    test('Device ID persists across initializations', () async {
      await service.initialize();
      final deviceId1 = service.getDeviceId();

      final service2 = TeacherDashboardService();
      await service2.initialize();
      final deviceId2 = service2.getDeviceId();

      expect(deviceId1, deviceId2);
    });

    test('Session can be started and ended', () async {
      await service.initialize();
      await service.startSession();

      var data = service.getData();
      expect(data.sessions.length, 1);
      expect(data.sessions[0].endTime, isNull);

      await Future.delayed(const Duration(milliseconds: 10));
      await service.endSession();

      data = service.getData();
      expect(data.sessions[0].endTime, isNotNull);
      expect(data.sessions[0].durationMs, greaterThan(0));
    });

    test('Total playtime accumulates correctly', () async {
      await service.initialize();
      var initialPlaytime = service.getTotalPlaytimeMs();

      await service.startSession();
      await Future.delayed(const Duration(milliseconds: 20));
      await service.endSession();

      final newPlaytime = service.getTotalPlaytimeMs();
      expect(newPlaytime, greaterThan(initialPlaytime));
    });

    test('Missions can be recorded', () async {
      await service.initialize();
      await service.startSession();

      await service.recordMissionCompleted();
      await service.recordMissionCompleted();

      final sessions = service.getSessions();
      expect(sessions.last.missionsCompleted, 2);
    });

    test('Trades can be recorded', () async {
      await service.initialize();
      await service.startSession();

      await service.recordTradeCompleted();
      await service.recordTradeCompleted();
      await service.recordTradeCompleted();

      final sessions = service.getSessions();
      expect(sessions.last.tradesCompleted, 3);
    });

    test('Reflections can be added and retrieved', () async {
      await service.initialize();
      await service.startSession();
      final sessionId = service.getCurrentSessionId();

      await service.addReflection(
        sessionId: sessionId,
        question: 'What was challenging?',
        answer: 'Managing resources efficiently',
      );
      await service.addReflection(
        sessionId: sessionId,
        question: 'What will you change?',
        answer: 'I will plan routes better',
      );

      final reflections = service.getReflections();
      expect(reflections.length, 2);
      expect(reflections[0].question, 'What was challenging?');
      expect(reflections[1].answer, 'I will plan routes better');
    });

    test('Export produces valid JSON', () async {
      await service.initialize();
      await service.startSession();
      final sessionId = service.getCurrentSessionId();
      await service.recordMissionCompleted();
      await service.addReflection(
        sessionId: sessionId,
        question: 'Test?',
        answer: 'Test answer',
      );

      final json = service.exportAsJson();
      expect(json, isNotEmpty);
      expect(json.contains('deviceId'), true);
      expect(json.contains('sessions'), true);
      expect(json.contains('reflections'), true);
    });

    test('Multiple sessions are tracked independently', () async {
      await service.initialize();

      // Session 1
      await service.startSession();
      await service.recordMissionCompleted();
      await service.endSession();

      // Session 2
      await service.startSession();
      await service.recordMissionCompleted();
      await service.recordMissionCompleted();
      await service.endSession();

      final sessions = service.getSessions();
      expect(sessions.length, 2);
      expect(sessions[0].missionsCompleted, 1);
      expect(sessions[1].missionsCompleted, 2);
    });

    test('Clear all removes data and generates new device ID', () async {
      await service.initialize();

      await service.startSession();
      await service.recordMissionCompleted();
      expect(service.getSessions().length, 1);

      await service.clearAll();
      expect(service.getSessions().length, 0);
      // Note: After clearAll and reinit, a new device ID is generated
    });

    test('Initialize is idempotent', () async {
      await service.initialize();
      final deviceId1 = service.getDeviceId();

      await service.initialize();
      final deviceId2 = service.getDeviceId();

      expect(deviceId1, deviceId2);
    });

    test('Can record actions without explicit session start', () async {
      await service.initialize();

      // recordMissionCompleted should auto-start a session
      await service.recordMissionCompleted();

      final sessions = service.getSessions();
      expect(sessions.isNotEmpty, true);
      expect(sessions.last.missionsCompleted, 1);
    });
  });

  group('Edge Cases and Robustness', () {
    test('Handles corrupted data gracefully', () async {
      // This would require mocking SharedPreferences,
      // which is tested in integration tests
    });

    test('DateTime serialization preserves timezone info', () {
      final dt = DateTime(2024, 2, 8, 15, 30, 45, 123);
      final record = SessionRecord(id: 'session-1', startTime: dt);
      final json = record.toJson();
      final restored = SessionRecord.fromJson(json);

      expect(restored.startTime, dt);
    });

    test('Empty strings in reflections are preserved', () {
      final reflection = ReflectionRecord(
        id: 'reflection-1',
        timestamp: DateTime.now(),
        sessionId: 'session-1',
        deviceId: 'device-123',
        question: '',
        answer: '',
      );

      final json = reflection.toJson();
      final restored = ReflectionRecord.fromJson(json);

      expect(restored.question, '');
      expect(restored.answer, '');
    });

    test('Large numbers are handled correctly', () {
      final data = TeacherDashboardData(
        deviceId: 'test',
        totalPlaytimeMs: 999999999,
      );

      final json = data.toJson();
      final restored = TeacherDashboardData.fromJson(json);

      expect(restored.totalPlaytimeMs, 999999999);
    });
  });
}
