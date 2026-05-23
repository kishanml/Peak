import 'package:flutter/material.dart';
import '../theme/peak_colors.dart';
import 'exercise_modal.dart';

class ExerciseFormDialog extends StatefulWidget {
  final WorkoutSection? initialSection;
  final Exercise? exerciseToEdit;
  final Function(String sectionName, Exercise exercise) onSave;

  const ExerciseFormDialog({
    super.key,
    this.initialSection,
    this.exerciseToEdit,
    required this.onSave,
  });

  @override
  State<ExerciseFormDialog> createState() => _ExerciseFormDialogState();
}

class _ExerciseFormDialogState extends State<ExerciseFormDialog> {
  final _sectionController = TextEditingController();
  final _nameController = TextEditingController();
  final _repsController = TextEditingController();
  final _setsController = TextEditingController();
  final _durationController = TextEditingController();
  final _weightController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool get isEditMode => widget.exerciseToEdit != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _sectionController.text = widget.initialSection?.title ?? '';
      _nameController.text = widget.exerciseToEdit!.name;
      _repsController.text = widget.exerciseToEdit!.reps.toString();
      _setsController.text = widget.exerciseToEdit!.sets.toString();
      _durationController.text = _formatDurationInput(
        widget.exerciseToEdit!.duration,
      );
      _weightController.text = widget.exerciseToEdit!.weight;
    } else if (widget.initialSection != null) {
      _sectionController.text = widget.initialSection!.title;
    }
  }

  String _formatDurationInput(Duration duration) {
    final minutes = duration.inSeconds / 60;
    if (minutes == minutes.roundToDouble()) {
      return minutes.toInt().toString();
    }

    return minutes.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
  }

  Duration _parseDurationInput(String value) {
    final minutes = double.tryParse(value.trim().replaceAll(',', '.')) ?? 1;
    final seconds = (minutes * 60).round().clamp(1, 86400);
    return Duration(seconds: seconds);
  }

  @override
  void dispose() {
    _sectionController.dispose();
    _nameController.dispose();
    _repsController.dispose();
    _setsController.dispose();
    _durationController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: PeakColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isEditMode ? 'Edit Exercise' : 'Add Exercise',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      icon: const Icon(
                        Icons.close,
                        color: PeakColors.mutedText,
                      ),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                _buildLabel('Section Name'),
                _buildMainTextField(
                  _sectionController,
                  enabled: !isEditMode,
                  hint: 'e.g Warm-up',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a section name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _buildLabel('Exercise Name'),
                _buildMainTextField(
                  _nameController,
                  hint: 'e.g Bench Press',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter an exercise name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _buildLabel('Weight'),
                _buildMainTextField(_weightController, hint: 'e.g 10kg'),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildColumnInput(
                        'Sets',
                        _setsController,
                        hint: '1',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildColumnInput(
                        'Reps',
                        _repsController,
                        hint: '1',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildColumnInput(
                        'Duration',
                        _durationController,
                        hint: '1',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PeakColors.neonAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      if (!_formKey.currentState!.validate()) return;

                      final exercise = Exercise(
                        id: isEditMode
                            ? widget.exerciseToEdit!.id
                            : DateTime.now().toString(),
                        name: _nameController.text.trim(),
                        reps: int.tryParse(_repsController.text) ?? 0,
                        sets: int.tryParse(_setsController.text) ?? 0,
                        duration: _parseDurationInput(_durationController.text),
                        weight: _weightController.text.trim(),
                      );

                      widget.onSave(_sectionController.text.trim(), exercise);
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 18,
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
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            color: PeakColors.mutedText,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildMainTextField(
    TextEditingController controller, {
    bool enabled = true,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      validator: validator,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: PeakColors.mutedText),
        filled: true,
        fillColor: PeakColors.innerSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        errorStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildColumnInput(
    String label,
    TextEditingController controller, {
    String? hint,
    TextInputType keyboardType = TextInputType.number,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: PeakColors.mutedText,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          textAlign: TextAlign.center,
          keyboardType: keyboardType,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: PeakColors.mutedText),
            filled: true,
            fillColor: PeakColors.innerSurface,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
