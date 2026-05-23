import 'package:flutter/material.dart';

import 'models/user_profile.dart';
import 'pages/profile_setup_screen.dart';
import 'pages/schedule_screen.dart';
import 'services/peak_storage.dart';
import 'theme/peak_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const List<String> _routineDays = [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY',
  ];

  double _progress = 0;
  String _status = 'Starting Peak...';

  @override
  void initState() {
    super.initState();
    _prepareApp();
  }

  Future<void> _prepareApp() async {
    try {
      await _updateProgress(0.2, 'Preparing storage...');
      await PeakStorage.peakDirectory();

      await _updateProgress(0.45, 'Creating weekly routines...');
      await PeakStorage.ensureRoutineFiles(_routineDays);

      await _updateProgress(0.7, 'Checking weekly reset...');
      await PeakStorage.resetCompletedExercisesForNewMonday(_routineDays);

      await _updateProgress(0.9, 'Loading profile...');
      final profile = await PeakStorage.loadProfile();

      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;

      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => _nextPage(profile)));
    } catch (e) {
      debugPrint('Error preparing Peak: $e');
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
      );
    }
  }

  Future<void> _updateProgress(double value, String status) async {
    if (!mounted) return;
    setState(() {
      _progress = value;
      _status = status;
    });
    await Future.delayed(const Duration(milliseconds: 120));
  }

  Widget _nextPage(UserProfile? profile) {
    if (profile == null) return const ProfileSetupScreen();
    return ScheduleScreen(profile: profile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PeakColors.baseBg,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 118,
                        height: 118,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: PeakColors.cardSurface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: PeakColors.neonAccent.withValues(alpha: 0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: PeakColors.neonAccent.withValues(
                                alpha: 0.08,
                              ),
                              blurRadius: 28,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Peak',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 30),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 6,
                          backgroundColor: PeakColors.innerSurface,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            PeakColors.neonAccent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _status,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: PeakColors.mutedText,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Text(
                'kishanml',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: PeakColors.mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
