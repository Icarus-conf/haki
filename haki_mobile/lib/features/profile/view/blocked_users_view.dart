import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/haki_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../friends/view_model/friends_cubit.dart';
import 'package:chat_mobile/core/theme/haki_icons.dart';

class BlockedUsersView extends StatelessWidget {
  const BlockedUsersView({super.key});

  @override
  Widget build(BuildContext context) {
    final blocked = context.select((FriendsCubit c) => c.state.blocked);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: GlassIconButton(icon: HakiIcons.arrowLeft, tooltip: 'Back', onPressed: () => Navigator.pop(context)),
            ),
            const SizedBox(height: 24),
            Text('Blocked', style: HakiText.display(42)),
            const SizedBox(height: 8),
            const Text(
              'Blocked people can’t message or call you, and don’t see when you’re online.',
              style: TextStyle(color: HakiColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 20),
            if (blocked.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: Text('Nobody here.', style: TextStyle(color: HakiColors.textMuted))),
              ),
            for (final u in blocked)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: HakiColors.surface, borderRadius: BorderRadius.circular(24)),
                  child: Row(
                    children: [
                      AuraAvatar(user: u, size: 48, radius: 17),
                      const SizedBox(width: 12),
                      Expanded(child: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                      TextButton(
                        onPressed: () async {
                          final ok = await context.read<FriendsCubit>().unblock(u.id);
                          if (context.mounted) {
                            showHakiToast(context, ok ? 'Unblocked ${u.name}' : 'Couldn’t unblock', isError: !ok);
                          }
                        },
                        style: TextButton.styleFrom(foregroundColor: HakiColors.lime),
                        child: const Text('Unblock'),
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
}
