class Exercise {
  String id;
  String name;
  int sets;
  int reps;
  Duration duration;
  String weight;
  bool isCompleted;

  Exercise({
    required this.id,
    required this.name,
    required this.sets,
    required this.reps,
    required this.duration,
    this.weight = "",
    this.isCompleted = false,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sets': sets,
    'reps': reps,
    'duration_seconds': duration.inSeconds,
    'weight': weight,
    'is_completed': isCompleted,
  };

  // Create from JSON when loading
  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
    id: json['id'] as String? ?? DateTime.now().toString(),
    name: json['name'] as String? ?? 'Exercise',
    sets: json['sets'] is int
        ? json['sets'] as int
        : int.tryParse('${json['sets']}') ?? 0,
    reps: json['reps'] is int
        ? json['reps'] as int
        : int.tryParse('${json['reps']}') ?? 0,
    duration: Duration(
      seconds: json['duration_seconds'] is int
          ? json['duration_seconds'] as int
          : int.tryParse('${json['duration_seconds']}') ?? 60,
    ),
    weight: json['weight'] as String? ?? "",
    isCompleted: json['is_completed'] as bool? ?? false,
  );
}

class WorkoutSection {
  String id;
  String title;
  List<Exercise> exercises;

  WorkoutSection({
    required this.id,
    required this.title,
    required this.exercises,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };

  factory WorkoutSection.fromJson(Map<String, dynamic> json) => WorkoutSection(
    id: json['id'] as String? ?? DateTime.now().toString(),
    title: json['title'] as String? ?? 'Workout',
    exercises: (json['exercises'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(Exercise.fromJson)
        .toList(),
  );
}
