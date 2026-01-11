import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../views/profile_view.dart';

class HomeAppBar extends StatelessWidget {
  final UserModel? currentUser;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onAddFriend;

  const HomeAppBar({
    super.key,
    required this.currentUser,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onAddFriend,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 100.0,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color.fromARGB(255, 29, 30, 126), Color.fromARGB(255, 107, 92, 255)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                left: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                bottom: 16,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '#Haki',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 28,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(
                              isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                            onPressed: onToggleTheme,
                            tooltip: 'Toggle Theme',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.person_add_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                            onPressed: onAddFriend,
                            tooltip: 'Add Friend',
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ProfileView()),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Hero(
                              tag: 'profile_avatar',
                              flightShuttleBuilder:
                                  (context, animation, direction, fromContext, toContext) {
                                    return fromContext.widget;
                                  },
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.white,
                                child: CircleAvatar(
                                  radius: 23,
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
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
