import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';

class GoalSettingsDialog extends ConsumerStatefulWidget {
  final int initialMinutes;
  const GoalSettingsDialog({super.key, required this.initialMinutes});

  @override
  ConsumerState<GoalSettingsDialog> createState() => _GoalSettingsDialogState();
}

class _GoalSettingsDialogState extends ConsumerState<GoalSettingsDialog> {
  late final TextEditingController _controller;
  bool _saving = false;
  String? _error;
  static const List<int> _presets = <int>[10, 30, 60];
  int? _selectedPreset;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialMinutes.toString());
    if (_presets.contains(widget.initialMinutes)) {
      _selectedPreset = widget.initialMinutes;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _error = null;
    });
    final raw = _controller.text.trim();
    final value = int.tryParse(raw);
    if (value == null) {
      setState(() {
        _error = 'Please enter a valid number';
      });
      return;
    }
    if (value <= 0) {
      setState(() {
        _error = 'Goal must be greater than 0';
      });
      return;
    }
    if (value > 300) {
      setState(() {
        _error = 'Let\'s keep it under 300 minutes';
      });
      return;
    }
    setState(() {
      _saving = true;
    });
    try {
      await AuthService().updateDailyGoldGoal(value);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _error = 'Failed to save goal';
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _selectPreset(int minutes) {
    setState(() {
      _selectedPreset = minutes;
      _error = null;
      _controller.text = minutes.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Daily Meditation Goal'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick select'),
          const SizedBox(height: 8),
          Row(
            children: [
              for (int i = 0; i < _presets.length; i++) ...[
                Expanded(
                  child: ChoiceChip(
                    label: Text('${_presets[i]} min', textAlign: TextAlign.center),
                    showCheckmark: false,
                    selected: _selectedPreset == _presets[i],
                    onSelected: _saving
                        ? null
                        : (isSelected) {
                            if (isSelected) _selectPreset(_presets[i]);
                          },
                  ),
                ),
                if (i < _presets.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
          const SizedBox(height: 12),
          const Text('Or set a custom goal'),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Minutes',
              hintText: 'e.g. 10',
              errorText: _error,
            ),
            onChanged: (value) {
              final parsed = int.tryParse(value.trim());
              if (parsed == null || !_presets.contains(parsed)) {
                if (_selectedPreset != null) {
                  setState(() {
                    _selectedPreset = null;
                  });
                }
              } else if (_selectedPreset != parsed) {
                setState(() {
                  _selectedPreset = parsed;
                });
              }
            },
            enabled: !_saving,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}


