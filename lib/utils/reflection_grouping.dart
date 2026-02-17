import '../models/teacher_dashboard.dart';

class SessionReflectionGroup {
  final String sessionId;
  final List<ReflectionRecord> reflections;

  const SessionReflectionGroup({
    required this.sessionId,
    required this.reflections,
  });
}

List<SessionReflectionGroup> buildSessionReflectionGroups({
  required List<ReflectionRecord> reflections,
  required List<SessionRecord> sessions,
  required String deviceId,
}) {
  final filteredReflections = reflections
      .where(
        (reflection) =>
            reflection.deviceId == deviceId && reflection.sessionId.isNotEmpty,
      )
      .toList()
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  if (filteredReflections.isEmpty) {
    return const [];
  }

  final orderedSessions = [...sessions]
    ..sort((a, b) => a.startTime.compareTo(b.startTime));

  final sessionOrder = <String, int>{
    for (var index = 0; index < orderedSessions.length; index++)
      orderedSessions[index].id: index,
  };

  final grouped = <String, List<ReflectionRecord>>{};
  for (final reflection in filteredReflections) {
    grouped.putIfAbsent(reflection.sessionId, () => []).add(reflection);
  }

  final orderedSessionIds = grouped.keys.toList()
    ..sort((a, b) {
      final aOrder = sessionOrder[a];
      final bOrder = sessionOrder[b];

      if (aOrder != null && bOrder != null) {
        return aOrder.compareTo(bOrder);
      }
      if (aOrder != null) return -1;
      if (bOrder != null) return 1;

      final aFirstTime = grouped[a]!.first.timestamp;
      final bFirstTime = grouped[b]!.first.timestamp;
      return aFirstTime.compareTo(bFirstTime);
    });

  return orderedSessionIds
      .map(
        (sessionId) => SessionReflectionGroup(
          sessionId: sessionId,
          reflections: grouped[sessionId]!,
        ),
      )
      .toList();
}
