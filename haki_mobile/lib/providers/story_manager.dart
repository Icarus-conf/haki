import 'dart:developer' as dev;

import 'package:flutter/material.dart';

import '../models/story_model.dart';
import '../services/api_service.dart';

/// Manages stories functionality
class StoryManager extends ChangeNotifier {
  final ApiService _api;

  List<StoryModel> _stories = [];
  bool _isLoading = false;

  StoryManager({required ApiService api}) : _api = api;

  // Getters
  List<StoryModel> get stories => _stories;
  bool get isLoading => _isLoading;

  /// Fetch active stories
  Future<void> fetchStories() async {
    final List data = await _api.getActiveStories();
    _stories = data.map((s) => StoryModel.fromJson(s)).toList();
    notifyListeners();
  }

  /// Post a new story
  Future<bool> postStory(String filePath) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.uploadStory(filePath);
      if (res != null) {
        await fetchStories();
        return true;
      }
    } catch (e) {
      dev.log('Error posting story: $e', name: 'StoryManager');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  /// Clear stories
  void clear() {
    _stories = [];
    _isLoading = false;
  }
}
