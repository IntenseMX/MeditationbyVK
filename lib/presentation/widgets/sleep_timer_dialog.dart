import 'package:flutter/material.dart';
import '../../core/animation_constants.dart';

/// Sleep timer dialog with preset options
/// Options: Off, 5min, 10min, 15min, 30min, 45min, 60min, End of track
class SleepTimerDialog extends StatefulWidget {
  final int currentMinutes;
  final Function(int minutes) onTimerSelected;

  const SleepTimerDialog({
    required this.currentMinutes,
    required this.onTimerSelected,
    super.key,
  });

  @override
  State<SleepTimerDialog> createState() => _SleepTimerDialogState();
}

class _SleepTimerDialogState extends State<SleepTimerDialog> {
  late int _selectedMinutes;

  static const List<Map<String, dynamic>> _timerOptions = [
    {'label': 'Off', 'minutes': 0, 'icon': Icons.timer_off},
    {'label': '5 minutes', 'minutes': 5, 'icon': Icons.timer},
    {'label': '10 minutes', 'minutes': 10, 'icon': Icons.timer},
    {'label': '15 minutes', 'minutes': 15, 'icon': Icons.timer},
    {'label': '30 minutes', 'minutes': 30, 'icon': Icons.timer},
    {'label': '45 minutes', 'minutes': 45, 'icon': Icons.timer},
    {'label': '60 minutes', 'minutes': 60, 'icon': Icons.timer},
    {'label': 'End of track', 'minutes': -1, 'icon': Icons.track_changes},
  ];

  @override
  void initState() {
    super.initState();
    _selectedMinutes = widget.currentMinutes;
  }

  String _getCurrentTimerText() {
    if (_selectedMinutes == 0) return 'Off';
    if (_selectedMinutes == -1) return 'End of track';
    return '$_selectedMinutes min';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AnimationConfig.cardCornerRadius),
      ),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.bedtime_outlined, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Sleep Timer',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Stop playback automatically after:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
            
            const SizedBox(height: 16),
            
            // Current selection display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Current timer:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                  ),
                  Text(
                    _getCurrentTimerText(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Timer options grid
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _timerOptions.length,
              itemBuilder: (context, index) {
                final option = _timerOptions[index];
                final isSelected = _selectedMinutes == option['minutes'];
                
                return _TimerOptionCard(
                  label: option['label'],
                  icon: option['icon'],
                  isSelected: isSelected,
                  onTap: () {
                    setState(() => _selectedMinutes = option['minutes']);
                  },
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onTimerSelected(_selectedMinutes);
                      Navigator.of(context).pop();
                    },
                    child: Text('Set Timer'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual timer option card
class _TimerOptionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimerOptionCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withOpacity(0.15)
                : colorScheme.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurface.withOpacity(0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface.withOpacity(0.8),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper function to show sleep timer dialog
Future<int?> showSleepTimerDialog({
  required BuildContext context,
  required int currentMinutes,
  required Function(int minutes) onTimerSelected,
}) async {
  return showDialog<int>(
    context: context,
    builder: (context) => SleepTimerDialog(
      currentMinutes: currentMinutes,
      onTimerSelected: onTimerSelected,
    ),
  );
}
