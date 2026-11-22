import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/haki_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/glass.dart';
import '../../friends/view_model/friends_cubit.dart';
import 'add_friend_sheet.dart';
import 'package:chat_mobile/core/theme/haki_icons.dart';

class RequestsTab extends StatelessWidget {
  const RequestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final requests = context.select((FriendsCubit c) => c.state.requests);
    final cubit = context.read<FriendsCubit>();

    return Stack(
      children: [
        const AuroraBackground(height: 380, colors: [HakiColors.pink, HakiColors.violet, HakiColors.blue]),
        SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 140),
            children: [
              Text('Requests', style: HakiText.display(46)),
              const SizedBox(height: 6),
              Text(
                switch (requests.length) {
                  0 => 'Nothing waiting on you.',
                  1 => '1 person wants to chat.',
                  final n => '$n people want to chat.',
                },
                style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 24),
              for (final r in requests)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: HakiColors.surface, borderRadius: BorderRadius.circular(24)),
                    child: Row(
                      children: [
                        AuraAvatar(user: r.sender, size: 52, radius: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.sender.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                              Text(
                                '@${r.sender.username} · ${chatTime(r.createdAt)}',
                                style: const TextStyle(color: HakiColors.textMuted, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Decline ${r.sender.name}',
                          onPressed: () => cubit.decline(r.id),
                          style: IconButton.styleFrom(backgroundColor: HakiColors.surfaceHigh),
                          icon: const Icon(HakiIcons.x),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          tooltip: 'Accept ${r.sender.name}',
                          onPressed: () => cubit.accept(r.id),
                          style: IconButton.styleFrom(
                            backgroundColor: HakiColors.lime,
                            foregroundColor: HakiColors.onLime,
                          ),
                          icon: const Icon(HakiIcons.check),
                        ),
                      ],
                    ),
                  ),
                ),
              if (requests.isEmpty)
                GlassButton(label: 'Add a friend', onPressed: () => AddFriendSheet.show(context)),
            ],
          ),
        ),
      ],
    );
  }
}
