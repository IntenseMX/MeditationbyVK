import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/animation_constants.dart';
import '../../providers/meditations_list_provider.dart';
import '../../providers/audio_player_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/category_provider.dart';
import '../widgets/animated_controls.dart';
import '../widgets/animated_gradient_background.dart';
import '../widgets/breathing_circle.dart';
import '../widgets/waveform_slider.dart';
import '../widgets/title_metadata_block.dart';
import '../widgets/sleep_timer_dialog.dart';

class PlayerScreenRedesigned extends ConsumerStatefulWidget {
  const PlayerScreenRedesigned({super.key, required this.meditationId});
  final String meditationId;

  @override
  ConsumerState<PlayerScreenRedesigned> createState() => _PlayerScreenRedesignedState();
}

class _PlayerScreenRedesignedState extends ConsumerState<PlayerScreenRedesigned>
    with SingleTickerProviderStateMixin {
  String? _loadedMeditationId;
  late AnimationController _imageAnimationController;
  late Animation<double> _imageScaleAnimation;
  bool _isLoading = true;
  
  // Sleep timer state
  int _sleepTimerMinutes = 0;
  Timer? _sleepTimer;
  DateTime? _sleepTimerEndTime;
  
  // Breathing guide toggle
  bool _showBreathingGuide = true;

  // Loop/repeat mode
  bool _isLooping = false;

  // Layout sizing constants
  static const double _breathingSectionHeight = 220.0;
  static const double _breathingCircleSize = 180.0;
  static const double _playButtonSize = 80.0;

  @override
  void initState() {
    super.initState();
    _imageAnimationController = AnimationController(
      duration: PlayerAnimationConfig.imageScale,
      vsync: this,
    );

    _imageScaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _imageAnimationController,
        curve: PlayerAnimationConfig.imageScaleCurve,
      ),
    );

    _imageAnimationController.forward();
  }

  void _checkAudioCompletion(AudioUiState audioState) {
    // Check if audio has completed (position >= duration)
    final duration = audioState.duration;
    final position = audioState.position;

    if (duration != null && position >= duration && duration.inSeconds > 0) {
      // Audio has completed - always reset to beginning and pause
      Future.microtask(() async {
        await ref.read(audioPlayerProvider.notifier).seek(Duration.zero);
        await ref.read(audioPlayerProvider.notifier).pause();

        // If looping is enabled, start playing again
        if (_isLooping) {
          await ref.read(audioPlayerProvider.notifier).play();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final meditationAsync = ref.watch(meditationByIdProvider(widget.meditationId));
    final audioState = ref.watch(audioPlayerProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    // Check for audio completion and handle loop/reset
    _checkAudioCompletion(audioState);
    
    // Categories lookup for resolving categoryId → category name
    final catList = categoriesAsync.asData?.value;
    final Map<String, String> categoryIdToName = {
      if (catList != null) ...{
        for (final c in catList) c.id: c.name,
      }
    };

    return meditationAsync.when(
      loading: () => _buildLoadingScreen(),
      error: (e, _) => _buildErrorScreen(),
      data: (data) {
        if (data == null) {
          return _buildNotFoundScreen();
        }

        final String title = (data['title'] as String?) ?? '';
        final String subtitle = (data['description'] as String?) ?? '';
        final int durationSec = (data['durationSec'] as int?) ?? 300;
        final String imageUrl = (data['imageUrl'] as String?) ?? '';
        final String audioUrl = (data['audioUrl'] as String?) ?? '';
        final String? categoryId = data['categoryId'] as String?;
        final bool isPremium = (data['isPremium'] == true);

        // Subscription gate
        final sub = ref.watch(subscriptionProvider);
        if (isPremium && !sub.isPremium) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Premium content. Upgrade to continue.')),
              );
              context.push('/paywall');
            }
          });
          return _buildPremiumLockedScreen();
        }

        // Load audio when ready
        if (_loadedMeditationId != widget.meditationId && audioUrl.isNotEmpty) {
          _loadedMeditationId = widget.meditationId;
          _isLoading = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(audioPlayerProvider.notifier).load(
                  meditationId: widget.meditationId,
                  title: title,
                  audioUrl: audioUrl,
                  imageUrl: imageUrl,
                  durationSec: durationSec,
                );
          });
        }

        return _buildPlayerContent(
          title: title,
          subtitle: subtitle,
          durationSec: durationSec,
          imageUrl: imageUrl,
          categoryId: categoryId,
          categoryIdToName: categoryIdToName,
          isPremium: isPremium,
          audioState: audioState,
        );
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading meditation...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text('Failed to load meditation'),
            SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go('/'),
              child: Text('Return to Home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundScreen() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text('Player')),
      body: Center(child: Text('Meditation not found')),
    );
  }

  Widget _buildPremiumLockedScreen() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text('Player')),
      body: Center(child: Text('Premium content locked')),
    );
  }

  Widget _buildPlayerContent({
    required String title,
    required String subtitle,
    required int durationSec,
    required String imageUrl,
    required String? categoryId,
    required Map<String, String> categoryIdToName,
    required bool isPremium,
    required dynamic audioState,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final gradientColors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
    ];

    final heroTag = 'meditation_${widget.meditationId}';
    final double totalSeconds = (audioState.duration ?? Duration(seconds: durationSec)).inSeconds.toDouble();
    final double positionSeconds = audioState.position.inSeconds.toDouble().clamp(0, totalSeconds);

    return WillPopScope(
      onWillPop: () async {
        HapticFeedback.lightImpact();
        ref.read(audioPlayerProvider.notifier).pause();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
            onPressed: () => context.pop(),
          ),
        ),

        // Main content with SafeArea
        body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmall = constraints.maxHeight < 600;
                final isLarge = constraints.maxHeight > 800;
                
                return Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(AnimationConfig.cardMargin),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(
                        sigmaX: AnimationConfig.cardBlurSigma,
                        sigmaY: AnimationConfig.cardBlurSigma,
                      ),
                      child: Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          maxWidth: 500, // Limit width on tablets
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withOpacity(AnimationConfig.cardOpacity),
                          borderRadius: BorderRadius.circular(AnimationConfig.cardCornerRadius),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(AnimationConfig.cardShadowOpacity),
                              blurRadius: AnimationConfig.cardBlurRadius,
                              spreadRadius: AnimationConfig.cardSpreadRadius,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                            // Hero animated image
                            Hero(
                              tag: heroTag,
                              child: Material(
                                color: Colors.transparent,
                                child: ScaleTransition(
                                  scale: _imageScaleAnimation,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: AspectRatio(
                                      aspectRatio: 16 / 9,
                                      child: imageUrl.isNotEmpty
                                          ? Image.network(imageUrl, fit: BoxFit.cover)
                                          : Container(
                                              color: colorScheme.secondary.withOpacity(0.3),
                                              child: Icon(
                                                Icons.music_note,
                                                size: 64,
                                                color: colorScheme.onSurface.withOpacity(0.5),
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            
                            SizedBox(height: isSmall ? 16 : 24),
                            
                            // Title and metadata block
                            TitleMetadataBlock(
                              title: title,
                              subtitle: subtitle,
                              categoryId: categoryId,
                              durationSec: durationSec,
                              isPremium: isPremium,
                              categoryIdToName: categoryIdToName,
                              onSleepTimerTap: () => _showSleepTimerDialog(),
                              onShareTap: () => _shareMeditation(),
                            ),
                            
                            SizedBox(height: isSmall ? 24 : 32),
                            
                            // Enhanced control row (rewind, play/pause, forward, speed)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Rewind 15s
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.fast_rewind),
                                      iconSize: AnimationConfig.skipButtonSize,
                                      color: colorScheme.onSurface.withOpacity(0.8),
                                      onPressed: audioState.isLoading
                                          ? null
                                          : () {
                                              HapticFeedback.lightImpact();
                                              ref.read(audioPlayerProvider.notifier).seekRelative(-15);
                                            },
                                    ),
                                    Text(
                                      '15s',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurface.withOpacity(0.6),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(width: 16),

                                // Play/Pause (center, larger)
                                Container(
                                  width: AnimationConfig.playButtonSize,
                                  height: AnimationConfig.playButtonSize,
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      colors: [colorScheme.primary, colorScheme.secondary],
                                      center: Alignment.center,
                                      radius: 0.8,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.primary.withOpacity(0.3),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: Icon(audioState.isPlaying ? Icons.pause : Icons.play_arrow),
                                    iconSize: 40,
                                    color: colorScheme.onPrimary,
                                    onPressed: audioState.isLoading
                                        ? null
                                        : () {
                                            HapticFeedback.lightImpact();
                                            final ctrl = ref.read(audioPlayerProvider.notifier);
                                            if (audioState.isPlaying) {
                                              ctrl.pause();
                                            } else {
                                              ctrl.play();
                                            }
                                          },
                                  ),
                                ),

                                SizedBox(width: 16),

                                // Forward 15s
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.fast_forward),
                                      iconSize: AnimationConfig.skipButtonSize,
                                      color: colorScheme.onSurface.withOpacity(0.8),
                                      onPressed: audioState.isLoading
                                          ? null
                                          : () {
                                              HapticFeedback.lightImpact();
                                              ref.read(audioPlayerProvider.notifier).seekRelative(15);
                                            },
                                    ),
                                    Text(
                                      '15s',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurface.withOpacity(0.6),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            
                            SizedBox(height: isSmall ? 16 : 24),
                            
                            // Time display with centered speed control
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _format(positionSeconds),
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                // Speed selector and replay button (centered)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    PopupMenuButton<double>(
                                      icon: Text(
                                        '${audioState.speed}x',
                                        style: TextStyle(
                                          color: colorScheme.onSurface.withOpacity(0.8),
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                      onSelected: audioState.isLoading
                                          ? null
                                          : (speed) {
                                              HapticFeedback.lightImpact();
                                              ref.read(audioPlayerProvider.notifier).setSpeed(speed);
                                            },
                                      itemBuilder: (context) => [
                                        PopupMenuItem(value: 0.75, child: Text('0.75x')),
                                        PopupMenuItem(value: 1.0, child: Text('1x')),
                                        PopupMenuItem(value: 1.25, child: Text('1.25x')),
                                        PopupMenuItem(value: 1.5, child: Text('1.5x')),
                                        PopupMenuItem(value: 2.0, child: Text('2x')),
                                      ],
                                    ),
                                    SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(Icons.repeat, size: 20),
                                      color: _isLooping
                                          ? colorScheme.primary
                                          : colorScheme.onSurface.withOpacity(0.8),
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(),
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        setState(() => _isLooping = !_isLooping);
                                      },
                                    ),
                                  ],
                                ),
                                Text(
                                  _format(totalSeconds),
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                            
                            SizedBox(height: 16),
                            
                            // Waveform slider
                            WaveformSlider(
                              value: positionSeconds.clamp(0, totalSeconds),
                              min: 0,
                              max: totalSeconds,
                              onChanged: (value) {
                                ref.read(audioPlayerProvider.notifier).seek(Duration(seconds: value.round()));
                              },
                              activeColor: colorScheme.primary,
                              inactiveColor: colorScheme.onSurface.withOpacity(0.2),
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
      ),
    );
  }

  String _format(double seconds) {
    final total = seconds.round();
    final m = (total ~/ 60).toString().padLeft(1, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString();
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _resolveCategoryName(String? categoryId, Map<String, String> idToName) {
    if (categoryId == null || categoryId.trim().isEmpty) return 'General';
    final byName = idToName[categoryId];
    if (byName != null && byName.trim().isNotEmpty) return byName;
    return _prettyCategory(categoryId);
  }

  String _prettyCategory(String input) {
    final s = input.replaceAll('_', ' ').replaceAll('-', ' ').trim();
    return s.split(' ').map((w) => w.isEmpty ? '' : (w[0].toUpperCase() + w.substring(1))).join(' ');
  }

  void _showSleepTimerDialog() {
    showDialog<int>(
      context: context,
      builder: (context) => SleepTimerDialog(
        currentMinutes: _sleepTimerMinutes,
        onTimerSelected: (minutes) {
          setState(() {
            _sleepTimerMinutes = minutes;
          });
          _startSleepTimer(minutes);
        },
      ),
    );
  }

  void _startSleepTimer(int minutes) {
    _sleepTimer?.cancel();
    _sleepTimerEndTime = null;

    if (minutes > 0) {
      // Simple timer - stops after N minutes
      _sleepTimer = Timer(Duration(minutes: minutes), () {
        ref.read(audioPlayerProvider.notifier).pause();
        setState(() {
          _sleepTimerMinutes = 0;
        });
        
        // Show confirmation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sleep timer ended - playback stopped')),
          );
        }
      });
      
      _sleepTimerEndTime = DateTime.now().add(Duration(minutes: minutes));
    } else if (minutes == -1) {
      // End of track - handled by audio completion
      // Just store the preference
      setState(() {
        _sleepTimerMinutes = -1;
      });
    }
  }

  void _shareMeditation() {
    final meditationAsync = ref.read(meditationByIdProvider(widget.meditationId));
    final data = meditationAsync.asData?.value;
    
    if (data == null) return;
    
    final String title = (data['title'] as String?) ?? '';
    final String subtitle = (data['description'] as String?) ?? '';
    final String? categoryId = data['categoryId'] as String?;
    final int durationSec = (data['durationSec'] as int?) ?? 0;
    
    final String shareText = '''🧘‍♀️ $title

$subtitle

⏱️ Duration: ${_formatDuration(durationSec)}
${categoryId != null ? '🏷️ Category: ${_resolveCategoryName(categoryId, {})}' : ''}

Listen on CLARITY Meditation App'''; 
    
    HapticFeedback.lightImpact();
    Share.share(shareText, subject: 'Check out this meditation: $title');
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _imageAnimationController.dispose();
    super.dispose();
  }
}
