import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/animation_constants.dart';
import '../../providers/meditations_list_provider.dart';
import '../../providers/audio_player_provider.dart';

import '../../providers/category_provider.dart';
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
  late final AudioPlayerNotifier _audio;
  
  // Sleep timer state
  int _sleepTimerMinutes = 0;
  Timer? _sleepTimer;
  
  // Breathing guide toggle (unused removed)

  // Loop/repeat mode
  bool _isLooping = false;

  // Initial buffering state
  bool _isBuffering = false;
  double _bufferProgress = 0.0;
  StreamSubscription<Duration>? _bufferSub;
  static const Duration _requiredBuffer = Duration(seconds: 30);

  // Local constants (avoid magic numbers)
  static const int _seekStepSeconds = 15;
  static const double _playButtonGradientRadius = 0.8;
  static const double _bufferStrokeWidth = 3.0;

  @override
  void initState() {
    super.initState();
    _audio = ref.read(audioPlayerProvider.notifier);
    _isLooping = false;
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
    // Listen for audio completion/looping during build as recommended by Riverpod
    ref.listen<AudioUiState>(audioPlayerProvider, (_, next) {
      _checkAudioCompletion(next);
    });

    final meditationAsync = ref.watch(meditationByIdProvider(widget.meditationId));
    final audioState = ref.watch(audioPlayerProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

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

        // Load audio when ready
        if (_loadedMeditationId != widget.meditationId && audioUrl.isNotEmpty) {
          _loadedMeditationId = widget.meditationId;
          _isLooping = false;
          // Reset buffering state for new meditation
          _isBuffering = false;
          _bufferProgress = 0.0;
          _bufferSub?.cancel();
          _bufferSub = null;

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
            Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
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
    required AudioUiState audioState,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    final heroTag = 'meditation_${widget.meditationId}';
    final double totalSeconds = (audioState.duration ?? Duration(seconds: durationSec)).inSeconds.toDouble();
    final double positionSeconds = audioState.position.inSeconds.toDouble().clamp(0, totalSeconds);

    return WillPopScope(
      onWillPop: () async {
        HapticFeedback.lightImpact();
        ref.read(audioPlayerProvider.notifier).stop();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,

        // Main content with SafeArea
        body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final mediaQuery = MediaQuery.of(context);
                final isLandscape = constraints.maxWidth > constraints.maxHeight;
                final colorScheme = Theme.of(context).colorScheme;
                var textScale = mediaQuery.textScaleFactor.clamp(
                  PlayerLayoutConfig.minTextScale,
                  PlayerLayoutConfig.maxTextScale,
                );
                final estimatedContentHeight = PlayerLayoutConfig.baseContentHeight * textScale;
                final availableInsideCardHeight = constraints.maxHeight - (AnimationConfig.cardMargin * 2) - (AnimationConfig.cardPadding * 2);
                final availableForImage = availableInsideCardHeight - estimatedContentHeight - PlayerLayoutConfig.contentGap;
                final computedImageSize = availableForImage.clamp(0.0, PlayerLayoutConfig.maxImageSize);
                final needsScroll = estimatedContentHeight > (constraints.maxHeight * PlayerLayoutConfig.scrollThresholdRatio);
                final enforceScroll = computedImageSize < PlayerLayoutConfig.minImageSize;

                // Compute portrait flexes
                final h = constraints.maxHeight;
                final imageFlex = h < PlayerLayoutConfig.smallHeightBreakpoint
                    ? 2
                    : (h > PlayerLayoutConfig.largeHeightBreakpoint ? 4 : 3);
                final contentFlex = h < PlayerLayoutConfig.smallHeightBreakpoint ? 3 : 2;

                // Image stack (Hero + back + premium)
                Widget imageStack = Stack(
                  children: [
                    Hero(
                      tag: heroTag,
                      child: Material(
                        color: Colors.transparent,
                        child: ScaleTransition(
                          scale: _imageScaleAnimation,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AnimationConfig.cardCornerRadius),
                            child: AspectRatio(
                              aspectRatio: 1.0,
                              child: imageUrl.isNotEmpty
                                  ? CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover)
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
                    Positioned(
                      top: 8,
                      left: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          ref.read(audioPlayerProvider.notifier).stop();
                          context.pop();
                        },
                      ),
                    ),
                    ),
                    if (isPremium)
                      Positioned(
                        top: 15,
                        right: 15,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.workspace_premium, color: Colors.amber, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'PREMIUM',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ),
                  ],
                );

                // Controls/content column
                Widget contentColumn = Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
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
                                      ref.read(audioPlayerProvider.notifier).seekRelative(-_seekStepSeconds);
                                    },
                            ),
                            Text(
                              '${_seekStepSeconds}s',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.6),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 16),
                        Container(
                          width: AnimationConfig.playButtonSize,
                          height: AnimationConfig.playButtonSize,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [colorScheme.primary, colorScheme.secondary],
                              center: Alignment.center,
                              radius: _playButtonGradientRadius,
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
                          child: _isBuffering
                              ? Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: CircularProgressIndicator(
                                        value: _bufferProgress,
                                        strokeWidth: _bufferStrokeWidth,
                                        valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                                        backgroundColor: colorScheme.onPrimary.withOpacity(0.3),
                                      ),
                                    ),
                                    Text(
                                      '${(_bufferProgress * 100).toInt()}%',
                                      style: TextStyle(
                                        color: colorScheme.onPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              : IconButton(
                                  icon: Icon(audioState.isPlaying ? Icons.pause : Icons.play_arrow),
                                  iconSize: 40,
                                  color: colorScheme.onPrimary,
                                  onPressed: audioState.isLoading
                                      ? null
                                      : () async {
                                          HapticFeedback.lightImpact();
                                          final ctrl = ref.read(audioPlayerProvider.notifier);
                                          if (audioState.isPlaying) {
                                            ctrl.pause();
                                          } else {
                                            // Check if meditation is cached on disk
                                            final isCached = await _isMeditationCached();

                                            if (isCached) {
                                              // File is cached, play immediately
                                              ctrl.play();
                                            } else {
                                              // Not cached - check buffered position
                                              final duration = audioState.duration;
                                              final buffered = await ctrl.bufferedPosition;

                                              if (duration == null || buffered < _requiredBuffer) {
                                                // Start buffering process
                                                _startBuffering();
                                              } else {
                                                // Already buffered, play immediately
                                                ctrl.play();
                                              }
                                            }
                                          }
                                        },
                                ),
                        ),
                        SizedBox(width: 16),
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
                    SizedBox(height: 24),
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
                );

                // Card container with glass effect
                Widget buildCard(Widget child, {double? fixedHeight}) {
                  final card = Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      maxWidth: PlayerLayoutConfig.maxContentWidth,
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
                      padding: EdgeInsets.all(AnimationConfig.cardPadding),
                      child: child,
                    ),
                  );

                  return BackdropFilter(
                    filter: ui.ImageFilter.blur(
                      sigmaX: AnimationConfig.cardBlurSigma,
                      sigmaY: AnimationConfig.cardBlurSigma,
                    ),
                    child: fixedHeight != null
                        ? SizedBox(height: fixedHeight, child: card)
                        : card,
                  );
                }

                // Choose layout mode
                if (needsScroll || enforceScroll) {
                  final physics = Theme.of(context).platform == TargetPlatform.iOS || Theme.of(context).platform == TargetPlatform.macOS
                      ? BouncingScrollPhysics()
                      : ClampingScrollPhysics();
                  return Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(AnimationConfig.cardMargin),
                      physics: physics,
                      child: buildCard(
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            imageStack,
                            SizedBox(height: 24),
                            contentColumn,
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // No scroll: shrink image only, keep content unchanged
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(AnimationConfig.cardMargin),
                    child: buildCard(
                      isLandscape
                          ? Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: EdgeInsets.only(right: 16.0),
                                    child: imageStack,
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: contentColumn,
                                ),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: computedImageSize,
                                  height: computedImageSize,
                                  child: imageStack,
                                ),
                                SizedBox(height: PlayerLayoutConfig.contentGap),
                                contentColumn,
                              ],
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

Listen on UP by VK'''; 
    
    HapticFeedback.lightImpact();
    Share.share(shareText, subject: 'Check out this meditation: $title');
  }

  /// Start buffering on first play (cache miss)
  void _startBuffering() async {
    if (_isBuffering) return;

    setState(() {
      _isBuffering = true;
      _bufferProgress = 0.0;
    });

    final notifier = ref.read(audioPlayerProvider.notifier);

    // Listen to buffered position
    _bufferSub = notifier.bufferedPositionStream.listen((buffered) {
      final bufferSec = buffered.inSeconds;
      final targetSec = _requiredBuffer.inSeconds;

      setState(() {
        _bufferProgress = (bufferSec / targetSec).clamp(0.0, 1.0);
      });

      // Auto-play when 30s buffered
      if (bufferSec >= targetSec && _isBuffering) {
        _bufferSub?.cancel();
        _bufferSub = null;
        setState(() {
          _isBuffering = false;
        });
        notifier.play();
      }
    });
  }

  /// Check if meditation audio is cached on disk
  Future<bool> _isMeditationCached() async {
    if (kIsWeb) return false;

    try {
      final cacheDir = await getApplicationCacheDirectory();
      final audioCacheDir = Directory('${cacheDir.path}/audio_cache');
      final cacheFile = File('${audioCacheDir.path}/${widget.meditationId}.mp3');
      return await cacheFile.exists();
    } catch (e) {
      debugPrint('[PlayerScreen] Cache check failed: $e');
      return false;
    }
  }

  @override
  void dispose() {
    // Stop audio when screen is disposed
    _audio.stop();
    _sleepTimer?.cancel();
    _bufferSub?.cancel();
    _imageAnimationController.dispose();
    _isLooping = false;
    super.dispose();
  }
}
