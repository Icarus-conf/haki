import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/chat_provider.dart';
import '../services/api_service.dart';
import '../utils/toast_utils.dart';

class BlockedUsersView extends StatefulWidget {
  const BlockedUsersView({super.key});

  @override
  State<BlockedUsersView> createState() => _BlockedUsersViewState();
}

class _BlockedUsersViewState extends State<BlockedUsersView> {
  final _api = ApiService();
  List<UserModel> _blockedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() => _isLoading = true);
    final users = await _api.getBlockedUsers();
    setState(() {
      _blockedUsers = users;
      _isLoading = false;
    });
  }

  Future<void> _unblockUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unblock User'),
        content: Text('Unblock ${user.displayName ?? user.username}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Unblock')),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final chat = context.read<ChatProvider>();
      await chat.unblockUser(user.id);
      if (mounted) {
        ToastUtils.showToast(context, '${user.displayName ?? user.username} unblocked');
        _loadBlockedUsers();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blocked Users'), elevation: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _blockedUsers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.block, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No blocked users',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _blockedUsers.length,
              itemBuilder: (context, index) {
                final user = _blockedUsers[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user.avatarUrl != null
                        ? CachedNetworkImageProvider('${ApiService.baseUrl}${user.avatarUrl}')
                        : CachedNetworkImageProvider(
                                'https://api.dicebear.com/7.x/avataaars/png?seed=${user.username}',
                              )
                              as ImageProvider,
                  ),
                  title: Text(user.displayName ?? user.username),
                  subtitle: Text('@${user.username}'),
                  trailing: ElevatedButton(
                    onPressed: () => _unblockUser(user),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Unblock'),
                  ),
                );
              },
            ),
    );
  }
}
