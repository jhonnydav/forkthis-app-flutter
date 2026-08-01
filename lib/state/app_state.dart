import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/fixtures.dart';

/// Ported from `../app/src/state/AppState.tsx`. `localStorage` → `SharedPreferences`,
/// React context + useState → ChangeNotifier. Same shape, same starter data, same
/// mutation semantics (toggle-in-place, clamp water/movement, etc).
class LoggedItem {
  final String id;
  final String sourceId;
  final String type; // 'order' | 'recipe'
  final String title;
  final int calories;
  final int protein;
  final String image;

  const LoggedItem({
    required this.id,
    required this.sourceId,
    required this.type,
    required this.title,
    required this.calories,
    required this.protein,
    required this.image,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceId': sourceId,
        'type': type,
        'title': title,
        'calories': calories,
        'protein': protein,
        'image': image,
      };

  factory LoggedItem.fromJson(Map<String, dynamic> json) => LoggedItem(
        id: json['id'] as String,
        sourceId: json['sourceId'] as String,
        type: json['type'] as String,
        title: json['title'] as String,
        calories: json['calories'] as int,
        protein: json['protein'] as int,
        image: json['image'] as String,
      );
}

class UserProfile {
  final String name;
  final String email;
  final Goal goal;
  final String units; // 'imperial' | 'metric'
  final String surgical; // 'prepare' | 'recover' | 'none'
  final String activity; // 'sedentary' | 'lightly' | 'moderately' | 'very'
  final bool notifications;

  const UserProfile({
    this.name = 'Steven',
    this.email = '',
    this.goal = Goal.maintain,
    this.units = 'imperial',
    this.surgical = 'none',
    this.activity = 'lightly',
    this.notifications = true,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    Goal? goal,
    String? units,
    String? surgical,
    String? activity,
    bool? notifications,
  }) =>
      UserProfile(
        name: name ?? this.name,
        email: email ?? this.email,
        goal: goal ?? this.goal,
        units: units ?? this.units,
        surgical: surgical ?? this.surgical,
        activity: activity ?? this.activity,
        notifications: notifications ?? this.notifications,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'goal': goal.name,
        'units': units,
        'surgical': surgical,
        'activity': activity,
        'notifications': notifications,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        name: json['name'] as String? ?? 'Steven',
        email: json['email'] as String? ?? '',
        goal: Goal.values.byName(json['goal'] as String? ?? 'maintain'),
        units: json['units'] as String? ?? 'imperial',
        surgical: json['surgical'] as String? ?? 'none',
        activity: json['activity'] as String? ?? 'lightly',
        notifications: json['notifications'] as bool? ?? true,
      );
}

const _storageKey = 'nutrition-platform-state-v1';

List<LoggedItem> _starterLogs() => fastHacks.take(2).map((hack) {
      final index = fastHacks.indexOf(hack);
      return LoggedItem(
        id: 'starter-$index',
        sourceId: hack.id,
        type: 'order',
        title: hack.title,
        calories: hack.calories,
        protein: hack.protein,
        image: hack.image,
      );
    }).toList();

class AppState extends ChangeNotifier {
  UserProfile profile = const UserProfile();
  List<String> savedHackIds = [];
  List<String> savedRecipeIds = [];
  List<LoggedItem> logs = _starterLogs();
  int waterCups = 5;
  int movementMinutes = 18;

  bool _loaded = false;
  bool get loaded => _loaded;

  AppState() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        profile = UserProfile.fromJson(json['profile'] as Map<String, dynamic>? ?? {});
        savedHackIds = List<String>.from(json['savedHackIds'] as List? ?? []);
        savedRecipeIds = List<String>.from(json['savedRecipeIds'] as List? ?? []);
        logs = (json['logs'] as List? ?? [])
            .map((e) => LoggedItem.fromJson(e as Map<String, dynamic>))
            .toList();
        waterCups = json['waterCups'] as int? ?? 5;
        movementMinutes = json['movementMinutes'] as int? ?? 18;
      } catch (_) {
        // Corrupt or pre-migration data — fall back to defaults, same as the web app's catch block.
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode({
        'profile': profile.toJson(),
        'savedHackIds': savedHackIds,
        'savedRecipeIds': savedRecipeIds,
        'logs': logs.map((l) => l.toJson()).toList(),
        'waterCups': waterCups,
        'movementMinutes': movementMinutes,
      }),
    );
  }

  void _commit() {
    notifyListeners();
    _persist();
  }

  void updateProfile({
    String? name,
    String? email,
    Goal? goal,
    String? units,
    String? surgical,
    String? activity,
    bool? notifications,
  }) {
    profile = profile.copyWith(
      name: name,
      email: email,
      goal: goal,
      units: units,
      surgical: surgical,
      activity: activity,
      notifications: notifications,
    );
    _commit();
  }

  void toggleSavedHack(String id) {
    savedHackIds = savedHackIds.contains(id)
        ? savedHackIds.where((s) => s != id).toList()
        : [...savedHackIds, id];
    _commit();
  }

  void toggleSavedRecipe(String id) {
    savedRecipeIds = savedRecipeIds.contains(id)
        ? savedRecipeIds.where((s) => s != id).toList()
        : [...savedRecipeIds, id];
    _commit();
  }

  void logItem({
    required String sourceId,
    required String type,
    required String title,
    required int calories,
    required int protein,
    required String image,
  }) {
    logs = [
      LoggedItem(
        id: '$type-$sourceId-${DateTime.now().millisecondsSinceEpoch}',
        sourceId: sourceId,
        type: type,
        title: title,
        calories: calories,
        protein: protein,
        image: image,
      ),
      ...logs,
    ];
    _commit();
  }

  void removeLog(String id) {
    logs = logs.where((l) => l.id != id).toList();
    _commit();
  }

  void addWater() {
    waterCups = (waterCups + 1).clamp(0, 16);
    _commit();
  }

  void addMovement(int minutes) {
    movementMinutes = (movementMinutes + minutes).clamp(0, 300);
    _commit();
  }

  void clearLocalData() {
    profile = const UserProfile();
    savedHackIds = [];
    savedRecipeIds = [];
    logs = _starterLogs();
    waterCups = 5;
    movementMinutes = 18;
    _commit();
  }
}
