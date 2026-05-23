import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/peak_colors.dart';
import 'exercise_modal.dart'; // Ensure this points to your unified model

class TimerOverlay extends StatefulWidget {
  final Exercise exercise;
  const TimerOverlay({super.key, required this.exercise});

  @override
  State<TimerOverlay> createState() => _TimerOverlayState();
}

class _TimerOverlayState extends State<TimerOverlay> {
  static const MethodChannel _timerChannel = MethodChannel(
    'com.kishanml.peak/timer',
  );
  Timer? _ticker;

  // Use ValueNotifiers to isolate rebuilds to only the widgets that change
  late final ValueNotifier<int> _remainingSeconds;
  late final ValueNotifier<bool> _isRunning;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = ValueNotifier<int>(widget.exercise.duration.inSeconds);
    _isRunning = ValueNotifier<bool>(true);
    _startCountdown();
  }

  void _startCountdown() {
    _ticker?.cancel(); // Safety check to prevent duplicate timers
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds.value > 0) {
        _remainingSeconds.value--; // Triggers UI update automatically
        _playFinalCountdownBeep(_remainingSeconds.value);
      } else {
        _ticker?.cancel();
        // Check if widget is still on screen before popping to prevent errors
        if (mounted) Navigator.pop(context);
      }
    });
  }

  Future<void> _playFinalCountdownBeep(int remainingSeconds) async {
    if (remainingSeconds > 0 && remainingSeconds <= 5) {
      try {
        await _timerChannel.invokeMethod<void>('beep');
      } catch (_) {
        SystemSound.play(SystemSoundType.alert);
      }
      HapticFeedback.selectionClick();
    }
  }

  void _togglePlayback() {
    if (_isRunning.value) {
      _ticker?.cancel();
    } else {
      _startCountdown();
    }
    _isRunning.value = !_isRunning.value;
  }

  String _getFormattedTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  String _getDurationLabel(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds} SEC';
    }

    final minutes = duration.inSeconds / 60;
    if (minutes == minutes.roundToDouble()) {
      return '${minutes.toInt()} MIN';
    }

    return '${minutes.toStringAsFixed(1)} MIN';
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _remainingSeconds.dispose();
    _isRunning.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Added a clamp so it doesn't look absurdly large on iPads/Tablets
    final double diameter = (MediaQuery.of(context).size.width * 0.78).clamp(
      250.0,
      400.0,
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // The Main Circular Timer Card (Static background, does not rebuild)
            Container(
              width: diameter,
              height: diameter,
              decoration: BoxDecoration(
                color: PeakColors.cardSurface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: PeakColors.neonAccent.withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ONLY the text rebuilds every second
                  ValueListenableBuilder<int>(
                    valueListenable: _remainingSeconds,
                    builder: (context, seconds, _) {
                      return Text(
                        _getFormattedTime(seconds),
                        style: const TextStyle(
                          color: PeakColors.neonAccent,
                          fontSize: 46,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),

                  // Static Exercise Info
                  Text(
                    widget.exercise.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${widget.exercise.sets} X ${widget.exercise.reps}    ${_getDurationLabel(widget.exercise.duration)}",
                    style: const TextStyle(
                      color: PeakColors.mutedText,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ONLY the icon rebuilds when play/pause is tapped
                  GestureDetector(
                    onTap: _togglePlayback,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: PeakColors.neonAccent,
                        shape: BoxShape.circle,
                      ),
                      child: ValueListenableBuilder<bool>(
                        valueListenable: _isRunning,
                        builder: (context, isRunning, _) {
                          return Icon(
                            isRunning ? Icons.pause : Icons.play_arrow,
                            color: Colors.black87,
                            size: 32,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // The "X" Close Button Overlay (Static, does not rebuild)
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: () {
                  _ticker?.cancel();
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: PeakColors.innerSurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: PeakColors.neonAccent,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
