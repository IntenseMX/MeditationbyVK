import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/meditation_service.dart';

class MeditationEditorState {
  final String? id;
  final String title;
  final String description;
  final List<String> tags;
  final String? categoryId;
  final String difficulty; // beginner | intermediate | advanced
  final bool isPremium;
  final String status; // draft | published
  final String? imageUrl;
  final String? audioUrl;
  final int? durationSec;
  final bool isSaving;
  final String? error;

  const MeditationEditorState({
    this.id,
    this.title = '',
    this.description = '',
    this.tags = const [],
    this.categoryId,
    this.difficulty = 'beginner',
    this.isPremium = false,
    this.status = 'draft',
    this.imageUrl,
    this.audioUrl,
    this.durationSec,
    this.isSaving = false,
    this.error,
  });

  MeditationEditorState copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? tags,
    String? categoryId,
    String? difficulty,
    bool? isPremium,
    String? status,
    String? imageUrl,
    String? audioUrl,
    int? durationSec,
    bool? isSaving,
    String? error,
  }) {
    return MeditationEditorState(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      categoryId: categoryId ?? this.categoryId,
      difficulty: difficulty ?? this.difficulty,
      isPremium: isPremium ?? this.isPremium,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      durationSec: durationSec ?? this.durationSec,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }
}

class MeditationEditorNotifier extends Notifier<MeditationEditorState> {
  late final MeditationService _service;

  @override
  MeditationEditorState build() {
    _service = MeditationService();
    return const MeditationEditorState();
  }

  Future<void> load(String id) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final data = await _service.getMeditation(id);
      if (data == null) {
        state = state.copyWith(isSaving: false, error: 'Not found');
        return;
      }
      state = MeditationEditorState(
        id: id,
        title: (data['title'] ?? '') as String,
        description: (data['description'] ?? '') as String,
        tags: List<String>.from(data['tags'] ?? <String>[]),
        categoryId: data['categoryId'] as String?,
        difficulty: (data['difficulty'] ?? 'beginner') as String,
        isPremium: (data['isPremium'] ?? false) as bool,
        status: (data['status'] ?? 'draft') as String,
        imageUrl: data['imageUrl'] as String?,
        audioUrl: data['audioUrl'] as String?,
        durationSec: (data['durationSec'] as int?),
        isSaving: false,
      );
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
    }
  }

  void setTitle(String v) => state = state.copyWith(title: v);
  void setDescription(String v) => state = state.copyWith(description: v);
  void setTags(List<String> v) => state = state.copyWith(tags: v);
  void setCategory(String? v) => state = state.copyWith(categoryId: v);
  void setDifficulty(String v) => state = state.copyWith(difficulty: v);
  void setPremium(bool v) => state = state.copyWith(isPremium: v);
  void setImageUrl(String? v) => state = state.copyWith(imageUrl: v);
  void setAudioUrl(String? v) => state = state.copyWith(audioUrl: v);
  void setDuration(int? v) => state = state.copyWith(durationSec: v);

  Future<String?> saveDraft() async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final data = {
        'title': state.title,
        'description': state.description,
        'tags': state.tags,
        'categoryId': state.categoryId,
        'difficulty': state.difficulty,
        'isPremium': state.isPremium,
        'status': 'draft',
        'imageUrl': state.imageUrl,
        'audioUrl': state.audioUrl,
        'durationSec': state.durationSec,
      };
      if (state.id == null) {
        final id = await _service.createMeditation(data);
        state = state.copyWith(id: id, status: 'draft', isSaving: false);
        return id;
      } else {
        await _service.updateMeditation(state.id!, data);
        state = state.copyWith(status: 'draft', isSaving: false);
        return state.id;
      }
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return null;
    }
  }

  Future<bool> publish() async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      // Minimal validation
      if (state.id == null) {
        final id = await saveDraft();
        if (id == null) return false;
      }
      await _service.publishMeditation(state.id!);
      state = state.copyWith(status: 'published', isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  Future<bool> delete() async {
    if (state.id == null) return false;
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _service.deleteMeditation(state.id!);
      state = const MeditationEditorState();
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  void reset() {
    state = const MeditationEditorState();
  }
}

final meditationEditorProvider = NotifierProvider<MeditationEditorNotifier, MeditationEditorState>(
  () => MeditationEditorNotifier(),
);


