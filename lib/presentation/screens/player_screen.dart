import 'package:flutter/material.dart';
import '../../data/datasources/dummy_data.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.meditationId});
  final String meditationId;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool isPlaying = false;
  double positionSeconds = 0;

  Map<String, dynamic>? get _meditation {
    try {
      return DummyData.meditations.firstWhere(
        (m) => m['id'] == widget.meditationId,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final meditation = _meditation;
    if (meditation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Player')),
        body: const Center(child: Text('Meditation not found')),
      );
    }

    final String title = meditation['title'] as String;
    final String subtitle = meditation['subtitle'] as String;
    final int durationMin = meditation['duration'] as int;
    final String imageUrl = meditation['imageUrl'] as String;

    final double totalSeconds = (durationMin * 60).toDouble().clamp(60, 3600);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onBackground
                      .withOpacity(0.7),
                ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 56,
                onPressed: () {
                  setState(() => isPlaying = !isPlaying);
                },
                icon: Icon(
                  isPlaying ? Icons.pause_circle_filled : Icons.play_circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Slider(
            value: positionSeconds.clamp(0, totalSeconds),
            min: 0,
            max: totalSeconds,
            onChanged: null,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_format(positionSeconds)),
              Text(_format(totalSeconds)),
            ],
          ),
        ],
      ),
    );
  }

  String _format(double seconds) {
    final total = seconds.round();
    final m = (total ~/ 60).toString().padLeft(1, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}


