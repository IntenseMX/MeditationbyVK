import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/meditation_editor_provider.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/category_provider.dart';
import '../../../services/category_service.dart';
import '../../widgets/file_picker_field.dart';
import '../../../services/upload_service.dart';
import 'package:file_picker/file_picker.dart';
import '../../../services/meditation_service.dart';

class MeditationEditorScreen extends ConsumerStatefulWidget {
  const MeditationEditorScreen({super.key, this.meditationId});

  final String? meditationId;

  @override
  ConsumerState<MeditationEditorScreen> createState() => _MeditationEditorScreenState();
}

class _MeditationEditorScreenState extends ConsumerState<MeditationEditorScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _tagController = TextEditingController();
  double? _imageProgress;
  double? _audioProgress;
  Uint8List? _imageBytes;
  String? _imageExt;
  String? _imageName;
  Uint8List? _audioBytes;
  String? _audioExt;
  String? _audioName;

  @override
  void initState() {
    super.initState();
    // Defer provider mutation outside of build
    if (widget.meditationId != null && widget.meditationId!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(meditationEditorProvider.notifier).load(widget.meditationId!);
      });
    } else {
      // Always start with a fresh state when creating a new meditation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(meditationEditorProvider.notifier).reset();
        _title.clear();
        _description.clear();
        _tagController.clear();
        setState(() {
          _imageBytes = null;
          _imageExt = null;
          _imageName = null;
          _audioBytes = null;
          _audioExt = null;
          _audioName = null;
          _imageProgress = null;
          _audioProgress = null;
        });
      });
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(meditationEditorProvider);
    final notifier = ref.read(meditationEditorProvider.notifier);
    if (state.id == null && state.isSaving) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    {
        // Sync controllers from state when empty
        _title.value = _title.value.copyWith(text: _title.text.isEmpty ? state.title : _title.text);
        _description.value = _description.value.copyWith(text: _description.text.isEmpty ? state.description : _description.text);

        bool _hasRequiredFields() {
          final hasTitle = _title.text.trim().isNotEmpty;
          final hasCategory = state.categoryId != null;
          final hasTags = state.tags.isNotEmpty;
          return hasTitle && hasCategory && hasTags;
        }

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: 'Admin',
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/admin'),
            ),
            title: Text(state.id == null ? 'New Meditation' : 'Edit Meditation'),
            actions: [
              if (state.id != null)
                IconButton(
                  tooltip: 'Delete',
                  onPressed: state.isSaving
                      ? null
                      : () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete meditation?'),
                              content: const Text('This action cannot be undone.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                              ],
                            ),
                          );
                          if (ok == true) {
                            final success = await notifier.delete();
                            if (success && mounted) context.pop();
                          }
                        },
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (state.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(state.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ),
                    TextField(
                      controller: _title,
                      onChanged: notifier.setTitle,
                      decoration: const InputDecoration(labelText: 'Title*'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _description,
                      onChanged: notifier.setDescription,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final t in state.tags)
                          Chip(
                            label: Text(t),
                            onDeleted: () {
                              final next = [...state.tags]..remove(t);
                              notifier.setTags(next);
                            },
                          ),
                        SizedBox(
                          width: 240,
                          child: TextField(
                            controller: _tagController,
                            decoration: InputDecoration(
                              labelText: 'Add tag',
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  final v = _tagController.text.trim();
                                  if (v.isEmpty) return;
                                  final next = {...state.tags, v}.toList();
                                  notifier.setTags(next);
                                  _tagController.clear();
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _CategoryDropdown(
                            selectedId: state.categoryId,
                            onChanged: notifier.setCategory,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: state.difficulty,
                            decoration: const InputDecoration(labelText: 'Difficulty'),
                            items: const [
                              DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
                              DropdownMenuItem(value: 'intermediate', child: Text('Intermediate')),
                              DropdownMenuItem(value: 'advanced', child: Text('Advanced')),
                            ],
                            onChanged: (v) => notifier.setDifficulty(v ?? 'beginner'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: state.isPremium,
                      onChanged: notifier.setPremium,
                      title: const Text('Premium'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilePickerField(
                            label: 'Select Cover Image',
                            previewText: _imageName ?? state.imageUrl,
                            progress: _imageProgress,
                            enabled: !state.isSaving,
                            onPick: () async {
                              final result = await FilePicker.platform.pickFiles(
                                type: FileType.image,
                                withData: true,
                              );
                              if (result == null || result.files.isEmpty) return;
                              final file = result.files.first;
                              if (file.bytes == null) return;
                              setState(() {
                                _imageBytes = file.bytes;
                                _imageExt = file.extension ?? 'jpg';
                                _imageName = file.name;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilePickerField(
                            label: 'Select Audio',
                            previewText: _audioName ?? state.audioUrl,
                            progress: _audioProgress,
                            enabled: !state.isSaving,
                            onPick: () async {
                              final result = await FilePicker.platform.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: const ['mp3', 'm4a', 'aac', 'wav'],
                                withData: true,
                              );
                              if (result == null || result.files.isEmpty) return;
                              final file = result.files.first;
                              if (file.bytes == null) return;
                              setState(() {
                                _audioBytes = file.bytes;
                                _audioExt = file.extension ?? 'mp3';
                                _audioName = file.name;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.cloud_upload_outlined),
                        label: const Text('Upload Files'),
                        onPressed: state.isSaving
                            ? null
                            : () async {
                                if (!_hasRequiredFields()) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Add a title, select a category, and add at least one tag.')),
                                  );
                                  return;
                                }
                                await _uploadPendingFiles(ref);
                              },
                      ),
                    ),
                    if (state.durationSec != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('Duration: ${state.durationSec}s'),
                      ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: state.isSaving
                                ? null
                                : () async {
                                    if (!_hasRequiredFields()) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Add a title, select a category, and add at least one tag.')),
                                      );
                                      return;
                                    }
                                    await _uploadPendingFiles(ref);
                                    final id = await notifier.saveDraft();
                                    if (id != null && mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Draft saved')));
                                    }
                                  },
                            icon: const Icon(Icons.save_outlined),
                            label: const Text('Save Draft'),
                          ),
                          ElevatedButton.icon(
                            onPressed: state.isSaving
                                ? null
                                : () async {
                                    if (!_hasRequiredFields()) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Add a title, select a category, and add at least one tag.')),
                                      );
                                      return;
                                    }
                                    await _uploadPendingFiles(ref);
                                    final ok = await notifier.publish();
                                    if (ok && mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Published')));
                                    }
                                  },
                            icon: const Icon(Icons.public),
                            label: const Text('Publish'),
                          ),
                        ],
                      ),
                    ),
                    if (state.isSaving)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: LinearProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
    }
  }
}

class _CategoryDropdown extends ConsumerWidget {
  const _CategoryDropdown({required this.selectedId, required this.onChanged});
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    return categoriesAsync.when(
      data: (List<CategoryItem> items) {
        return DropdownButtonFormField<String>(
          value: selectedId != null && items.any((c) => c.id == selectedId) ? selectedId : null,
          decoration: const InputDecoration(labelText: 'Category'),
          items: [
            const DropdownMenuItem<String>(value: null, child: Text('Select')),
            ...items.map((c) => DropdownMenuItem<String>(value: c.id, child: Text(c.name))),
          ],
          onChanged: onChanged,
        );
      },
      loading: () => DropdownButtonFormField<String>(
        value: null,
        decoration: const InputDecoration(labelText: 'Category'),
        items: const [DropdownMenuItem<String>(value: null, child: Text('Loading...'))],
        onChanged: null,
      ),
      error: (e, _) => DropdownButtonFormField<String>(
        value: null,
        decoration: const InputDecoration(labelText: 'Category'),
        items: const [DropdownMenuItem<String>(value: null, child: Text('Error loading categories'))],
        onChanged: null,
      ),
    );
  }
}

extension _UploadHelpers on _MeditationEditorScreenState {
  Future<void> _uploadPendingFiles(WidgetRef ref) async {
    final state = ref.read(meditationEditorProvider);
    final notifier = ref.read(meditationEditorProvider.notifier);
    final upload = UploadService();
    final medService = MeditationService();

    // Ensure we have a final ID to use in storage paths (no temp/orphans)
    String meditationId = state.id ?? medService.newId();

    if (_imageBytes != null && _imageExt != null) {
      setState(() => _imageProgress = 0);
      final res = await upload.uploadImage(
        bytes: _imageBytes!,
        meditationId: meditationId,
        fileExtension: _imageExt!,
        onProgress: (p) => setState(() => _imageProgress = p),
      );
      notifier.setImageUrl(res.downloadUrl);
      setState(() {
        _imageProgress = null;
        _imageBytes = null;
        _imageName = null;
      });
    }

    if (_audioBytes != null && _audioExt != null) {
      setState(() => _audioProgress = 0);
      final res = await upload.uploadAudio(
        bytes: _audioBytes!,
        meditationId: meditationId,
        fileExtension: _audioExt!,
        onProgress: (p) => setState(() => _audioProgress = p),
      );
      notifier.setAudioUrl(res.downloadUrl);
      notifier.setDuration(res.durationSeconds);
      setState(() {
        _audioProgress = null;
        _audioBytes = null;
        _audioName = null;
      });
    }
  }
}


