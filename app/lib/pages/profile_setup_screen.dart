import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/peak_storage.dart';
import '../theme/peak_colors.dart';
import 'schedule_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  final UserProfile? initialProfile;

  const ProfileSetupScreen({super.key, this.initialProfile});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _weightController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    _nameController = TextEditingController(text: profile?.name ?? '');
    _ageController = TextEditingController(
      text: profile == null ? '' : profile.age.toString(),
    );
    _weightController = TextEditingController(
      text: profile == null ? '' : profile.weight.toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final profile = UserProfile(
      name: _nameController.text.trim(),
      age: int.parse(_ageController.text.trim()),
      weight: double.parse(_weightController.text.trim().replaceAll(',', '.')),
    );

    try {
      await PeakStorage.saveProfile(profile);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }

    if (!mounted) return;
    if (widget.initialProfile != null) {
      Navigator.of(context).pop(profile);
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ScheduleScreen(profile: profile)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PeakColors.baseBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            widget.initialProfile == null
                                ? 'Create Profile'
                                : 'Edit Profile',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Your routine will be stored locally in the Peak folder.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: PeakColors.mutedText,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 30),
                          _ProfileField(
                            controller: _nameController,
                            label: 'Name',
                            icon: Icons.person_outline,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _ProfileField(
                            controller: _ageController,
                            label: 'Age',
                            icon: Icons.cake_outlined,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              final age = int.tryParse(value?.trim() ?? '');
                              if (age == null || age <= 0) {
                                return 'Enter a valid age';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _ProfileField(
                            controller: _weightController,
                            label: 'Weight',
                            icon: Icons.monitor_weight_outlined,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.done,
                            suffix: 'kg',
                            onFieldSubmitted: (_) => _saveProfile(),
                            validator: (value) {
                              final weight = double.tryParse(
                                (value ?? '').trim().replaceAll(',', '.'),
                              );
                              if (weight == null || weight <= 0) {
                                return 'Enter a valid weight';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: PeakColors.neonAccent,
                                foregroundColor: Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              onPressed: _isSaving ? null : _saveProfile,
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.black,
                                      ),
                                    )
                                  : const Text(
                                      'Continue',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? suffix;
  final ValueChanged<String>? onFieldSubmitted;
  final String? Function(String?) validator;

  const _ProfileField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.validator,
    this.keyboardType,
    this.textInputAction,
    this.suffix,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: PeakColors.mutedText),
        suffixText: suffix,
        suffixStyle: const TextStyle(color: PeakColors.mutedText),
        prefixIcon: Icon(icon, color: PeakColors.neonAccent),
        filled: true,
        fillColor: PeakColors.cardSurface,
        errorStyle: const TextStyle(fontWeight: FontWeight.w600),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: PeakColors.neonAccent),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}
