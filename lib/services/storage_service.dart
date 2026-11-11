import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/parsed_command_log.dart';
import '../models/task_item.dart';
import '../models/undo_action.dart';

class StorageService {
  static const _keyTasks = 'nexu_tasks';
  static const _keyHistory = 'nexu_command_history';
  static const _keyDemoClock = 'nexu_demo_clock';
  static const _keyIsMuted = 'nexu_is_muted';
  static const _keyUndoStack = 'nexu_undo_stack';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // 1. Tasks
  Future<void> saveTasks(List<TaskItem> tasks) async {
    final jsonList = tasks.map((t) => t.toJson()).toList();
    await _prefs.setString(_keyTasks, jsonEncode(jsonList));
  }

  List<TaskItem> loadTasks() {
    final raw = _prefs.getString(_keyTasks);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((item) => TaskItem.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // 2. Command History
  Future<void> saveHistory(List<ParsedCommandLog> history) async {
    final jsonList = history.map((h) => h.toJson()).toList();
    await _prefs.setString(_keyHistory, jsonEncode(jsonList));
  }

  List<ParsedCommandLog> loadHistory() {
    final raw = _prefs.getString(_keyHistory);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((item) => ParsedCommandLog.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // 3. Demo Clock
  Future<void> saveDemoClock(DateTime clock) async {
    await _prefs.setString(_keyDemoClock, clock.toIso8601String());
  }

  DateTime? loadDemoClock() {
    final raw = _prefs.getString(_keyDemoClock);
    if (raw == null) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  // 4. Mute Setting
  Future<void> saveMute(bool isMuted) async {
    await _prefs.setBool(_keyIsMuted, isMuted);
  }

  bool loadMute() {
    return _prefs.getBool(_keyIsMuted) ?? false;
  }

  // 5. Undo Stack
  Future<void> saveUndoStack(List<UndoAction> stack) async {
    final jsonList = stack.map((a) => a.toJson()).toList();
    await _prefs.setString(_keyUndoStack, jsonEncode(jsonList));
  }

  List<UndoAction> loadUndoStack() {
    final raw = _prefs.getString(_keyUndoStack);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((item) => UndoAction.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearAll() async {
    await _prefs.clear();
  }
}

