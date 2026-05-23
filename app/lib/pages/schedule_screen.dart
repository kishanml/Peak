import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/peak_storage.dart';
import '../theme/peak_colors.dart';
import 'profile_setup_screen.dart';
import 'routine_view_screen.dart';

class ScheduleScreen extends StatefulWidget {
  final UserProfile profile;

  const ScheduleScreen({super.key, required this.profile});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late UserProfile _profile;
  Map<String, RoutineProgress> _progressByDay = {};

  final List<Map<String, dynamic>> _dayRoutines = [
    {
      "day": "MONDAY",
      "subtitle": "Chest and Triceps",
      "icon": Icons.fitness_center,
    },
    {
      "day": "TUESDAY",
      "subtitle": "Back and Biceps",
      "icon": Icons.fitness_center,
    },
    {
      "day": "WEDNESDAY",
      "subtitle": "Legs",
      "icon": Icons.fitness_center,
    },
    {
      "day": "THURSDAY",
      "subtitle": "Shoulders",
      "icon": Icons.fitness_center,
    },
    {
      "day": "FRIDAY",
      "subtitle": "Legs",
      "icon": Icons.fitness_center,
    },
    {
      "day": "SATURDAY",
      "subtitle": "Outdoor",
      "icon": Icons.pool,
    },
    {"day": "SUNDAY", 
    "subtitle": "Rest Day", 
    "icon": Icons.directions_run},
  ];

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _loadRoutineProgress();
  }

  Future<void> _loadRoutineProgress() async {
    await PeakStorage.resetCompletedExercisesForNewMonday(
      _dayRoutines.map((routine) => routine['day'] as String),
    );

    final progressEntries = await Future.wait(
      _dayRoutines.map((routine) async {
        final day = routine['day'] as String;
        final sections = await PeakStorage.loadRoutine(day);
        final totalExercises =
            sections?.fold<int>(
              0,
              (total, section) => total + section.exercises.length,
            ) ??
            0;
        final completedExercises =
            sections?.fold<int>(
              0,
              (total, section) =>
                  total +
                  section.exercises
                      .where((exercise) => exercise.isCompleted)
                      .length,
            ) ??
            0;

        return MapEntry(
          day,
          RoutineProgress(
            completedExercises: completedExercises,
            totalExercises: totalExercises,
          ),
        );
      }),
    );

    if (!mounted) return;
    setState(() => _progressByDay = Map.fromEntries(progressEntries));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PeakColors.baseBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _dayRoutines.length,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 24),
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final routine = _dayRoutines[index];
                        final day = routine['day'] as String;

                        return RoutineCard(
                          routine: routine,
                          progress:
                              _progressByDay[day] ??
                              const RoutineProgress(
                                completedExercises: 0,
                                totalExercises: 0,
                              ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    RoutineViewScreen(dayName: day),
                              ),
                            );
                            await _loadRoutineProgress();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'HELLO ${_profile.name.toUpperCase()}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PeakColors.mutedText,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Edit profile',
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.person_outline,
                color: PeakColors.mutedText,
              ),
              onPressed: () async {
                final updatedProfile = await Navigator.push<UserProfile>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ProfileSetupScreen(initialProfile: _profile),
                  ),
                );

                if (updatedProfile != null && mounted) {
                  setState(() => _profile = updatedProfile);
                }
              },
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Expanded(
              child: Text(
                'Schedule',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                '${_profile.age}y • ${_profile.weight.toStringAsFixed(1)}kg',
                style: const TextStyle(
                  color: PeakColors.neonAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class RoutineProgress {
  final int completedExercises;
  final int totalExercises;

  const RoutineProgress({
    required this.completedExercises,
    required this.totalExercises,
  });

  double get value {
    if (totalExercises == 0) return 0;
    return completedExercises / totalExercises;
  }

  int get percentage => (value * 100).round();
}

// ============================================================================
// CUSTOM CARD WIDGET: Handles Hover & Touch Highlight States perfectly
// ============================================================================
class RoutineCard extends StatefulWidget {
  final Map<String, dynamic> routine;
  final RoutineProgress progress;
  final VoidCallback onTap;

  const RoutineCard({
    super.key,
    required this.routine,
    required this.progress,
    required this.onTap,
  });

  @override
  State<RoutineCard> createState() => _RoutineCardState();
}

class _RoutineCardState extends State<RoutineCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isHovered = true),
        onTapUp: (_) {
          setState(() => _isHovered = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: PeakColors.cardSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHovered ? PeakColors.neonAccent : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: PeakColors.neonAccent.withValues(alpha: 0.08),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _isHovered
                          ? PeakColors.neonAccent.withValues(alpha: 0.15)
                          : PeakColors.innerSurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.routine['icon'],
                      color: _isHovered
                          ? PeakColors.neonAccent
                          : const Color(0xFF9E9E9E),
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.routine['day'],
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _isHovered
                                ? PeakColors.neonAccent
                                : Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.routine['subtitle'],
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: PeakColors.mutedText,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _ProgressBadge(progress: widget.progress),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: widget.progress.value,
                  minHeight: 6,
                  backgroundColor: PeakColors.innerSurface,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    PeakColors.neonAccent,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${widget.progress.completedExercises} / ${widget.progress.totalExercises} exercises',
                    style: const TextStyle(
                      color: PeakColors.mutedText,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: _isHovered
                        ? PeakColors.neonAccent
                        : PeakColors.mutedText,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressBadge extends StatelessWidget {
  final RoutineProgress progress;

  const _ProgressBadge({required this.progress});

  @override
  Widget build(BuildContext context) {
    final isDone = progress.totalExercises > 0 && progress.percentage == 100;

    return Container(
      constraints: const BoxConstraints(minWidth: 58),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDone
            ? PeakColors.neonAccent
            : PeakColors.neonAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: PeakColors.neonAccent.withValues(alpha: isDone ? 0 : 0.25),
        ),
      ),
      child: Text(
        '${progress.percentage}%',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isDone ? Colors.black : PeakColors.neonAccent,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
