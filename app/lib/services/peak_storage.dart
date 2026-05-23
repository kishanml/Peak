import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/user_profile.dart';
import '../pages/exercise_modal.dart';

class PeakStorage {
  const PeakStorage._();

  static Future<Directory> peakDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final peakFolder = Directory('${directory.path}/Peak');
    final legacyFolder = Directory('${directory.path}/peak');

    if (!await peakFolder.exists()) {
      await peakFolder.create(recursive: true);
    }

    if (await legacyFolder.exists()) {
      for (final entity in legacyFolder.listSync()) {
        if (entity is! File) continue;

        final targetFile = File(
          '${peakFolder.path}/${entity.uri.pathSegments.last}',
        );
        if (!await targetFile.exists()) {
          await entity.copy(targetFile.path);
        }
      }
    }

    return peakFolder;
  }

  static Future<File> _profileFile() async {
    final directory = await peakDirectory();
    return File('${directory.path}/user_profile.json');
  }

  static Future<File> _weeklyResetFile() async {
    final directory = await peakDirectory();
    return File('${directory.path}/weekly_reset.json');
  }

  static DateTime _weekStartMonday(DateTime date) {
    final localDate = DateTime(date.year, date.month, date.day);
    return localDate.subtract(
      Duration(days: localDate.weekday - DateTime.monday),
    );
  }

  static String _routineFileName(String dayName) {
    final safeDay = dayName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    return '${safeDay.isEmpty ? 'routine' : safeDay}_routine.json';
  }

  static Future<File> routineFile(String dayName) async {
    final directory = await peakDirectory();
    return File('${directory.path}/${_routineFileName(dayName)}');
  }

  static Future<UserProfile?> loadProfile() async {
    final file = await _profileFile();
    if (!await file.exists()) return null;

    final contents = await file.readAsString();
    if (contents.trim().isEmpty) return null;

    final profile = UserProfile.fromJson(jsonDecode(contents));
    return profile.isComplete ? profile : null;
  }

  static Future<void> saveProfile(UserProfile profile) async {
    final file = await _profileFile();
    await file.writeAsString(jsonEncode(profile.toJson()));
  }

  static Future<List<WorkoutSection>?> loadRoutine(String dayName) async {
    final file = await routineFile(dayName);
    if (!await file.exists()) return null;

    final contents = await file.readAsString();
    if (contents.trim().isEmpty) return null;

    final List<dynamic> jsonData = jsonDecode(contents);
    return jsonData
        .map((data) => WorkoutSection.fromJson(data as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveRoutine(
    String dayName,
    List<WorkoutSection> sections,
  ) async {
    final file = await routineFile(dayName);
    final jsonData = sections.map((section) => section.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonData));
  }

  static Future<void> ensureRoutineFiles(Iterable<String> dayNames) async {
    for (final dayName in dayNames) {
      final file = await routineFile(dayName);
      if (!await file.exists()) {
        await file.writeAsString(jsonEncode(<dynamic>[]));
      }
    }
  }

  static Future<void> resetCompletedExercisesForNewMonday(
    Iterable<String> dayNames,
  ) async {
    final resetFile = await _weeklyResetFile();
    final currentMonday = _weekStartMonday(DateTime.now());

    DateTime? lastResetMonday;
    if (await resetFile.exists()) {
      final contents = await resetFile.readAsString();
      if (contents.trim().isNotEmpty) {
        final metadata = jsonDecode(contents) as Map<String, dynamic>;
        final savedDate = DateTime.tryParse(
          metadata['last_reset_monday'] as String? ?? '',
        );
        if (savedDate != null) {
          lastResetMonday = _weekStartMonday(savedDate);
        }
      }
    }

    if (lastResetMonday == null) {
      await resetFile.writeAsString(
        jsonEncode({'last_reset_monday': currentMonday.toIso8601String()}),
      );
      return;
    }

    if (!lastResetMonday.isBefore(currentMonday)) return;

    for (final dayName in dayNames) {
      final sections = await loadRoutine(dayName);
      if (sections == null) continue;

      var changed = false;
      for (final section in sections) {
        for (final exercise in section.exercises) {
          if (exercise.isCompleted) {
            exercise.isCompleted = false;
            changed = true;
          }
        }
      }

      if (changed) {
        await saveRoutine(dayName, sections);
      }
    }

    await resetFile.writeAsString(
      jsonEncode({'last_reset_monday': currentMonday.toIso8601String()}),
    );
  }
}
