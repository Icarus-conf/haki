import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/haki_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../../models/group_model.dart';
import '../../friends/view_model/friends_cubit.dart';
import '../../friends/view_model/friends_state.dart';
import '../../session/view_model/session_cubit.dart';
import 'group_avatar.dart';
import 'pick_friends_view.dart';

/// Members, add people, leave. Returns true when the user left the group.
abstract final class GroupInfoSheet {
  static Future<bool> show(BuildContext context, GroupModel group) async {
    final left = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => BlocBuilder<FriendsCubit, FriendsState>(
        builder: (sheet, friends) {
          final g = friends.groupById(group.id) ?? group;
          final meId = sheet.read<SessionCubit>().state.me?.id;
          final online = friends.onlineIds;
          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheet).height * 0.8),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                Row(
                  children: [
                    GroupAvatar(group: g, size: 56),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(g.name, style: HakiText.display(26)),
                          Text('${g.members.length} people · end-to-end encrypted',
                              style: const TextStyle(color: HakiColors.textMuted, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: HakiColors.lime,
                    foregroundColor: HakiColors.onLime,
                    child: Icon(Icons.person_add_alt_1_rounded),
                  ),
                  title: const Text('Add people'),
                  onTap: () => PickFriendsView.addTo(sheet, g),
                ),
                for (final m in g.members)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: AuraAvatar(user: m, size: 40, radius: 14),
                    title: Text(m.id == meId ? '${m.name} (you)' : m.name),
                    subtitle: Text(
                      [
                        if (m.id == g.ownerId) 'Created the group',
                        if (online.contains(m.id) && m.id != meId) 'online',
                        if (m.publicKey == null) 'hasn’t set up encryption',
                      ].join(' · '),
                      style: const TextStyle(color: HakiColors.textMuted, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    final sure = await confirmAction(
                      sheet,
                      title: 'Leave ${g.name}?',
                      message: 'You’ll stop getting its messages. Someone in the group can add you back.',
                      action: 'Leave',
                    );
                    if (!sure || !sheet.mounted) return;
                    final ok = await sheet.read<FriendsCubit>().leaveGroup(g.id);
                    if (!sheet.mounted) return;
                    if (ok) {
                      Navigator.pop(sheet, true);
                    } else {
                      showHakiToast(sheet, 'Couldn’t leave the group', isError: true);
                    }
                  },
                  icon: const Icon(Icons.logout_rounded, color: HakiColors.dangerText),
                  label: const Text('Leave group', style: TextStyle(color: HakiColors.dangerText)),
                ),
              ],
            ),
          );
        },
      ),
    );
    return left ?? false;
  }
}
