import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/chat_provider.dart';
import '../services/api_service.dart';
import '../widgets/full_page_loading.dart';
import '../widgets/loading_indicator.dart';
import 'login_view.dart';
import 'recovery_phrase_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _statusController = TextEditingController();
  final _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<ChatProvider>().me;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      _bioController.text = user.bio ?? '';
      _statusController.text = user.statusMessage ?? '';
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _isLoading = true);
      try {
        if (mounted) {
          final chat = context.read<ChatProvider>();
          await chat.uploadAvatar(image.path);
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Avatar updated!')));
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Failed to upload avatar')));
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final chat = context.read<ChatProvider>();
      final success = await chat.updateProfile(
        displayName: _nameController.text,
        bio: _bioController.text,
      );

      // Update status message separately
      if (_statusController.text != chat.me?.statusMessage) {
        await chat.api.updateStatus(_statusController.text);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
      } else {
        throw Exception('Failed to update');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to update profile')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final chat = context.read<ChatProvider>();

    // Check if user has backed up their recovery phrase
    if (!chat.hasViewedRecoveryPhrase) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Backup Your Recovery Phrase'),
          content: const Text(
            'Without your recovery phrase, you won\'t be able to recover your account on a new device. '
            'Do you want to view it now?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Logout Anyway'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context, true);
              },
              child: const Text('View Recovery Phrase'),
            ),
          ],
        ),
      );

      if (shouldContinue == true && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RecoveryPhraseView()),
        );
        return; // Don't logout, let them try again
      }
    }

    // Proceed with logout
    if (mounted) {
      await context.read<ChatProvider>().logout();
    }

    if (mounted) {
      Navigator.of(
        context,
      ).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginView()), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final user = chat.me;

    if (user == null) {
      return const FullPageLoading(message: 'Loading profile...');
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            stretch: true,
            leadingWidth: 70, // Reduced from 100 to pull back button closer
            backgroundColor: const Color.fromARGB(255, 29, 30, 126),
            leading: CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final top = constraints.biggest.height;
                final padding = MediaQuery.of(context).padding.top;
                final collapsedHeight = kToolbarHeight + padding;
                final expandedHeight = 280.0;

                // t goes from 0.0 (collapsed) to 1.0 (expanded)
                final t = ((top - collapsedHeight) / (expandedHeight - collapsedHeight)).clamp(
                  0.0,
                  1.0,
                );

                // Animations
                final avatarRadius = Tween<double>(begin: 20, end: 60).transform(t);

                // Adjusted left positions to avoid overlap with leadingWidth (70)
                final avatarLeft = Tween<double>(
                  begin: 70, // Start after the back button
                  end: MediaQuery.of(context).size.width / 2 - 60,
                ).transform(t);

                final avatarTop = Tween<double>(
                  begin: padding + (kToolbarHeight - 40) / 2,
                  end: 100,
                ).transform(t);

                final nameLeft = Tween<double>(
                  begin: 70 + 40 + 12, // leading + avatar + gap
                  end: MediaQuery.of(context).size.width / 2 - 50,
                ).transform(t);

                final nameTop = Tween<double>(
                  begin: padding + (kToolbarHeight - 20) / 2,
                  end: 100 + 120 + 16, // avatarTop + avatarHeight + gap
                ).transform(t);

                final nameFontSize = Tween<double>(begin: 18, end: 16).transform(t);
                final nameColor = Color.lerp(Colors.white, Colors.white.withValues(alpha: 0.9), t);

                // Opacity for elements that disappear on collapse (like "edit" icon, bio?)
                final fadeT = Tween<double>(
                  begin: 0.0,
                  end: 1.0,
                ).transform(Interval(0.5, 1.0).transform(t));

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: Theme.of(context).brightness == Brightness.dark
                              ? [Colors.black, const Color.fromARGB(255, 17, 38, 101)]
                              : [
                                  const Color.fromARGB(255, 29, 30, 126),
                                  const Color.fromARGB(255, 107, 92, 255),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    _buildDecorativeCircle(-40, -40, 150, Colors.white.withValues(alpha: 0.1)),
                    _buildDecorativeCircle(
                      null,
                      null,
                      100,
                      Colors.white.withValues(alpha: 0.05),
                      bottom: -20,
                      right: -20,
                    ),

                    // Avatar
                    Positioned(
                      top: avatarTop,
                      left: avatarLeft,
                      child: Stack(
                        children: [
                          Container(
                            padding: EdgeInsets.all(4 * t), // Reduce border on collapse
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[800]
                                  : Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              radius: avatarRadius,
                              backgroundColor: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.black
                                  : Colors.grey[200],
                              backgroundImage: user.avatarUrl != null
                                  ? CachedNetworkImageProvider(
                                      '${ApiService.baseUrl}${user.avatarUrl}',
                                    )
                                  : CachedNetworkImageProvider(
                                          'https://api.dicebear.com/7.x/avataaars/png?seed=${user.username}',
                                        )
                                        as ImageProvider,
                            ),
                          ),
                          // Edit Icon (Fade out on collapse)
                          if (t > 0.5)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Opacity(
                                opacity: fadeT,
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.grey[800]
                                          : Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.camera_alt_rounded,
                                      color: Theme.of(context).primaryColor,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Name
                    Positioned(
                      top: nameTop,
                      left: t < 0.5 ? nameLeft : 0, // In expanded, constrain width/center
                      right: t < 0.5 ? null : 0,
                      child: t < 0.5
                          ? Text(
                              '@${user.username}',
                              style: TextStyle(
                                color: nameColor,
                                fontSize: nameFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : Center(
                              // Centered in expanded mode
                              child: Text(
                                '@${user.username}',
                                style: TextStyle(
                                  color: nameColor,
                                  fontSize: nameFontSize,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -30),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      // decoration: BoxDecoration(
                      //   color:
                      //       Theme.of(context).cardTheme.color?.withValues(alpha:0.85) ??
                      //       Colors.white.withValues(alpha:0.85),
                      //   borderRadius: BorderRadius.circular(32),
                      //   border: Border.all(
                      //     color: Theme.of(context).brightness == Brightness.dark
                      //         ? Colors.white.withValues(alpha:0.1)
                      //         : Colors.white.withValues(alpha:0.5),
                      //   ),
                      //   boxShadow: [
                      //     BoxShadow(
                      //       color: Colors.black.withValues(alpha:0.05),
                      //       blurRadius: 20,
                      //       offset: const Offset(0, 10),
                      //     ),
                      //   ],
                      // ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Warning banner if not backed up
                          // if (!chat.hasViewedRecoveryPhrase)
                          //   Container(
                          //     margin: const EdgeInsets.only(bottom: 24),
                          //     padding: const EdgeInsets.all(16),
                          //     decoration: BoxDecoration(
                          //       color: Colors.orange.shade100.withValues(alpha:0.3),
                          //       borderRadius: BorderRadius.circular(12),
                          //       border: Border.all(color: Colors.orange, width: 2),
                          //     ),
                          //     child: Row(
                          //       children: [
                          //         const Icon(
                          //           Icons.warning_amber_rounded,
                          //           color: Colors.orange,
                          //           size: 24,
                          //         ),
                          //         const SizedBox(width: 12),
                          //         Expanded(
                          //           child: Text(
                          //             '⚠️ Backup your recovery phrase to avoid losing access to your account',
                          //             style: TextStyle(
                          //               fontSize: 14,
                          //               fontWeight: FontWeight.w600,
                          //               color: Theme.of(context).colorScheme.onSurface,
                          //             ),
                          //           ),
                          //         ),
                          //       ],
                          //     ),
                          //   ),
                          // const SizedBox(height: 16),
                          // const Text(
                          //   'General Info',
                          //   style: TextStyle(
                          //     fontSize: 18,
                          //     fontWeight: FontWeight.bold,
                          //     color: Color(0xFF1e293b),
                          //   ),
                          // ),
                          const SizedBox(height: 24),
                          _buildTextField(
                            controller: _nameController,
                            label: 'Display Name',
                            icon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _bioController,
                            label: 'Bio',
                            icon: Icons.info_outline_rounded,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _statusController,
                            label: 'Status Message',
                            icon: Icons.message_outlined,
                            hint: 'e.g., At the gym, Coding...',
                            maxLength: 100,
                          ),
                          const SizedBox(height: 40),
                          _buildSaveButton(),
                          const SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            height: 56,
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.blue.shade900
                                    : Colors.blue.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const RecoveryPhraseView()),
                                );
                                // Refresh state after viewing
                                setState(() {});
                              },
                              icon: const Icon(Icons.shield_rounded),
                              label: const Text('View Recovery Phrase'),
                            ),

                            // if (!chat.hasViewedRecoveryPhrase)
                            //   Positioned(
                            //     top: 8,
                            //     right: 8,
                            //     child: Container(
                            //       padding: const EdgeInsets.all(6),
                            //       decoration: const BoxDecoration(
                            //         color: Colors.red,
                            //         shape: BoxShape.circle,
                            //       ),
                            //       child: const Icon(
                            //         Icons.priority_high,
                            //         color: Colors.white,
                            //         size: 16,
                            //       ),
                            //     ),
                            //   ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            height: 56,
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.withValues(alpha: 0.8),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _logout,
                              child: const Text('Logout'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? hint,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          textAlign: TextAlign.start,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            // prefixIcon: Icon(icon, color: Theme.of(context).primaryColor, size: 22),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.5)
                : Colors.white,
            hintText: hint,
            contentPadding: const EdgeInsets.all(16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]!
                    : Colors.grey.shade200,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color.fromARGB(255, 29, 30, 126), Color.fromARGB(255, 107, 92, 255)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading
            ? const LoadingIndicator(size: 24)
            : const Text(
                'Save Changes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildDecorativeCircle(
    double? top,
    double? left,
    double size,
    Color color, {
    double? bottom,
    double? right,
  }) {
    return Positioned(
      top: top,
      left: left,
      bottom: bottom,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
