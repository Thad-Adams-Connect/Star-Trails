// Star Trails™
// Copyright © 2026 Ubertas Lab, LLC.
// All Rights Reserved.
// Unauthorized copying, modification, distribution, or reverse engineering prohibited.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_state.dart';
import '../utils/json_utils.dart';

class PersistenceService {
  static const String _gameStateKey = 'game_state';
  static const String _checksumKey = 'game_checksum';
  static const String _eduPromptsKey = 'edu_prompts_enabled';
  static const String _reflectionEnabledKey = 'reflection_enabled';

  Future<bool> saveGameState(GameState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = JsonUtils.toStableJson(state.toJson());
      final checksum = JsonUtils.calculateChecksum(jsonStr);

      final okState = await prefs.setString(_gameStateKey, jsonStr);
      final okChecksum = await prefs.setString(_checksumKey, checksum);
      return okState && okChecksum;
    } catch (e) {
      return false;
    }
  }

  Future<GameState?> loadGameState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_gameStateKey);
      final savedChecksum = prefs.getString(_checksumKey);

      if (jsonStr == null || savedChecksum == null) {
        return null;
      }

      final calculatedChecksum = JsonUtils.calculateChecksum(jsonStr);
      if (calculatedChecksum != savedChecksum) {
        await clearGameState();
        return null;
      }

      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return GameState.fromJson(json);
    } catch (e) {
      await clearGameState();
      return null;
    }
  }

  Future<void> clearGameState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_gameStateKey);
    await prefs.remove(_checksumKey);
  }

  Future<void> setEduPromptsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_eduPromptsKey, enabled);
  }

  Future<bool> getEduPromptsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_eduPromptsKey) ?? true;
  }

  Future<void> setReflectionEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reflectionEnabledKey, enabled);
  }

  Future<bool> getReflectionEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_reflectionEnabledKey) ?? true;
  }
}
