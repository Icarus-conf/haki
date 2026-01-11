import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/story_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../widgets/loading_indicator.dart';

class StoryView extends StatefulWidget {
  final UserModel user;
  final List<StoryModel> stories;

  const StoryView({super.key, required this.user, required this.stories});

  @override
  State<StoryView> createState() => _StoryViewState();
}

class _StoryViewState extends State<StoryView> {
  int _currentIndex = 0;
  double _progress = 0.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _progress = 0.0;
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        if (_progress < 1.0) {
          _progress += 0.01;
        } else {
          _nextStory();
        }
      });
    });
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() {
        _currentIndex++;
        _startTimer();
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _startTimer();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final x = details.globalPosition.dx;
          final width = MediaQuery.of(context).size.width;
          if (x < width / 3) {
            _previousStory();
          } else {
            _nextStory();
          }
        },
        child: Stack(
          children: [
            // Background Story Image
            Center(
              child: CachedNetworkImage(
                imageUrl: '${ApiService.baseUrl}${story.content}',
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => const LoadingIndicator(size: 40),
                errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
              ),
            ),

            // Top Progress Bars
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  children: List.generate(widget.stories.length, (index) {
                    return Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: index < _currentIndex ? 1.0 : 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: index == _currentIndex
                            ? LinearProgressIndicator(
                                value: _progress,
                                backgroundColor: Colors.transparent,
                                valueColor: const AlwaysStoppedAnimation(Colors.white),
                              )
                            : const SizedBox.shrink(),
                      ),
                    );
                  }),
                ),
              ),
            ),

            // Top Header (User Info)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 30, 16, 0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: widget.user.avatarUrl != null
                          ? CachedNetworkImageProvider(
                              '${ApiService.baseUrl}${widget.user.avatarUrl}',
                            )
                          : CachedNetworkImageProvider(
                                  'https://api.dicebear.com/7.x/avataaars/png?seed=${widget.user.username}',
                                )
                                as ImageProvider,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.user.displayName ?? widget.user.username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            _getTimeAgo(story.createdAt),
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 30),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
