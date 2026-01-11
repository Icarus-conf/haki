import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/story_model.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../views/story_view.dart';

class StorySection extends StatelessWidget {
  final UserModel? currentUser;
  final Map<UserModel, List<StoryModel>> groupedStories;
  final Function(String) onPostStory;

  const StorySection({
    super.key,
    required this.currentUser,
    required this.groupedStories,
    required this.onPostStory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 135,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          // My Story Add
          GestureDetector(
            onTap: () async {
              final picker = ImagePicker();
              final image = await picker.pickImage(source: ImageSource.gallery);
              if (image != null) {
                onPostStory(image.path);
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [Colors.grey[300]!, Colors.grey[100]!]),
                        ),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          backgroundImage: currentUser?.avatarUrl != null
                              ? CachedNetworkImageProvider(
                                  '${ApiService.baseUrl}${currentUser!.avatarUrl}',
                                )
                              : CachedNetworkImageProvider(
                                      'https://api.dicebear.com/7.x/avataaars/png?seed=${currentUser?.username ?? "User"}',
                                    )
                                    as ImageProvider,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 107, 92, 255),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.add, size: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'My Status',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748b),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Friend Stories
          ...groupedStories.entries.map((entry) {
            final user = entry.key;
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StoryView(user: user, stories: entry.value),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Color.fromARGB(255, 29, 30, 126),
                            Color.fromARGB(255, 107, 92, 255),
                          ],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        backgroundImage: user.avatarUrl != null
                            ? CachedNetworkImageProvider('${ApiService.baseUrl}${user.avatarUrl}')
                            : CachedNetworkImageProvider(
                                    'https://api.dicebear.com/7.x/avataaars/png?seed=${user.username}',
                                  )
                                  as ImageProvider,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.displayName ?? user.username,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
