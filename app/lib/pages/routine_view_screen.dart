import 'package:flutter/material.dart';
import '../services/peak_storage.dart';
import '../theme/peak_colors.dart';
import 'exercise_form_dialog.dart';
import 'exercise_modal.dart';
import 'timer_overlay.dart';

class RoutineViewScreen extends StatefulWidget {
  final String dayName; // Added to save files distinctly (e.g., "monday.json")
  const RoutineViewScreen({super.key, this.dayName = "Routine"});

  @override
  State<RoutineViewScreen> createState() => _RoutineViewScreenState();
}

class _RoutineViewScreenState extends State<RoutineViewScreen> {
  List<WorkoutSection> _sections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutineData();
  }

  Future<void> _loadRoutineData() async {
    try {
      await PeakStorage.resetCompletedExercisesForNewMonday([widget.dayName]);
      final savedSections = await PeakStorage.loadRoutine(widget.dayName);
      if (!mounted) return;

      setState(() {
        _sections = savedSections ?? _defaultSections();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _sections = _defaultSections();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveRoutineData() async {
    try {
      await PeakStorage.saveRoutine(widget.dayName, _sections);
    } catch (e) {
      debugPrint("Error saving data: $e");
    }
  }

  int get _totalExercises {
    return _sections.fold<int>(
      0,
      (total, section) => total + section.exercises.length,
    );
  }

  int get _completedExercises {
    return _sections.fold<int>(
      0,
      (total, section) =>
          total +
          section.exercises.where((exercise) => exercise.isCompleted).length,
    );
  }

  double get _completionProgress {
    if (_totalExercises == 0) return 0;
    return _completedExercises / _totalExercises;
  }

  List<WorkoutSection> _defaultSections() {
    return [
      WorkoutSection(
        id: 's1',
        title: 'Warmup',
        exercises: [
          Exercise(
            id: 'e1',
            name: 'Torso Twists',
            sets: 2,
            reps: 20,
            duration: const Duration(minutes: 2),
          ),
        ],
      ),
    ];
  }

  // ==========================================
  // UI ACTIONS
  // ==========================================
  void _addNewExercise({String? prefillSection}) {
    showDialog(
      context: context,
      builder: (context) => ExerciseFormDialog(
        initialSection: prefillSection != null
            ? WorkoutSection(id: '', title: prefillSection, exercises: [])
            : null,
        onSave: (sectionName, newExercise) {
          setState(() {
            final existingSection = _sections.firstWhere(
              (s) => s.title.toLowerCase() == sectionName.toLowerCase(),
              orElse: () {
                final newSec = WorkoutSection(
                  id: DateTime.now().toString(),
                  title: sectionName,
                  exercises: [],
                );
                _sections.add(newSec);
                return newSec;
              },
            );
            existingSection.exercises.add(newExercise);
            _saveRoutineData(); // Save to local storage
          });
        },
      ),
    );
  }

  void _editExercise(WorkoutSection section, Exercise exercise) {
    showDialog(
      context: context,
      builder: (context) => ExerciseFormDialog(
        initialSection: section,
        exerciseToEdit: exercise,
        onSave: (_, updatedExercise) {
          setState(() {
            exercise.name = updatedExercise.name;
            exercise.sets = updatedExercise.sets;
            exercise.reps = updatedExercise.reps;
            exercise.duration = updatedExercise.duration;
            exercise.weight = updatedExercise.weight;
            _saveRoutineData(); // Save to local storage
          });
        },
      ),
    );
  }

  Future<void> _deleteExercise(
    WorkoutSection section,
    Exercise exercise,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PeakColors.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Delete exercise?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: Text(
          exercise.name,
          style: const TextStyle(color: PeakColors.mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: PeakColors.mutedText),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    setState(() {
      section.exercises.removeWhere((item) => item.id == exercise.id);
      _saveRoutineData();
    });
  }

  void _startExerciseTimer(Exercise exercise) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => TimerOverlay(exercise: exercise),
    );
  }

  void _toggleExerciseCompleted(Exercise exercise, bool? value) {
    setState(() {
      exercise.isCompleted = value ?? false;
      _saveRoutineData();
    });
  }

  // ==========================================
  // BUILD METHOD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PeakColors.baseBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.dayName.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: Colors.white,
            letterSpacing: 1.0,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: PeakColors.neonAccent),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
              itemCount:
                  _sections.length + 2, // progress + global Add Section button
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildProgressSummary();
                }

                // Render the "+ Create New Section" button at the very bottom
                if (index == _sections.length + 1) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text(
                        "Create New Section",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => _addNewExercise(),
                    ),
                  );
                }

                final section = _sections[index - 1];
                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: PeakColors.cardSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            section.title.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Icon(
                            Icons.edit,
                            color: PeakColors.mutedText,
                            size: 18,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Exercises in this section
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: section.exercises.length,
                        itemBuilder: (context, exIdx) {
                          final exercise = section.exercises[exIdx];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: PeakColors.innerSurface,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        exercise.name,
                                        style: TextStyle(
                                          color: exercise.isCompleted
                                              ? PeakColors.mutedText
                                              : Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          decoration: exercise.isCompleted
                                              ? TextDecoration.lineThrough
                                              : TextDecoration.none,
                                          decorationColor:
                                              PeakColors.neonAccent,
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      // Custom Info Metrics Row (Repeat, Weights, Timer)
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 8,
                                        children: [
                                          _buildMetric(
                                            Icons.repeat,
                                            '${exercise.sets} Sets',
                                          ),
                                          _buildMetric(
                                            Icons.fitness_center,
                                            '${exercise.reps} Reps',
                                          ),
                                          _buildMetric(
                                            Icons.timer_outlined,
                                            _formatDurationLabel(
                                              exercise.duration,
                                            ),
                                          ),
                                          if (exercise.weight.isNotEmpty) ...[
                                            _buildMetric(
                                              Icons.monitor_weight_outlined,
                                              exercise.weight,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                PopupMenuButton<String>(
                                  tooltip: 'Exercise options',
                                  color: PeakColors.cardSurface,
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: PeakColors.mutedText,
                                  ),
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _editExercise(section, exercise);
                                      return;
                                    }
                                    if (value == 'delete') {
                                      _deleteExercise(section, exercise);
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.edit_outlined,
                                            color: PeakColors.mutedText,
                                            size: 20,
                                          ),
                                          SizedBox(width: 10),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete_outline,
                                            color: Colors.redAccent,
                                            size: 20,
                                          ),
                                          SizedBox(width: 10),
                                          Text('Delete'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Checkbox(
                                  value: exercise.isCompleted,
                                  activeColor: PeakColors.neonAccent,
                                  checkColor: Colors.black,
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  onChanged: (value) =>
                                      _toggleExerciseCompleted(exercise, value),
                                ),
                                GestureDetector(
                                  onTap: () => _startExerciseTimer(exercise),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: PeakColors.neonAccent.withValues(
                                        alpha: 0.15,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow_rounded,
                                      color: PeakColors.neonAccent,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      // Inline Add Exercise Button
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: PeakColors.neonAccent,
                          ),
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text(
                            "Add exercise",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () =>
                              _addNewExercise(prefillSection: section.title),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildProgressSummary() {
    final progress = _completionProgress;
    final percentage = (progress * 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PeakColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Workout Progress',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '$_completedExercises / $_totalExercises',
                style: const TextStyle(
                  color: PeakColors.neonAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: PeakColors.innerSurface,
              valueColor: const AlwaysStoppedAnimation<Color>(
                PeakColors.neonAccent,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$percentage% completed',
            style: const TextStyle(
              color: PeakColors.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDurationLabel(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds}s';
    }

    final minutes = duration.inSeconds / 60;
    if (minutes == minutes.roundToDouble()) {
      return '${minutes.toInt()}m';
    }

    return '${minutes.toStringAsFixed(1)}m';
  }

  // Small helper widget for the detailed sub-labels
  Widget _buildMetric(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: PeakColors.mutedText, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: PeakColors.mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
