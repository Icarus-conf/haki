import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/haki_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../../services/message_sender.dart';
import '../../friends/view_model/friends_cubit.dart';
import '../../groups/view/group_avatar.dart';

/// Pick where to forward a message: a friend, a group or the Lounge.
abstract final class ForwardSheet {
  static Future<ChatTarget?> pick(BuildContext context) {
    final state = context.read<FriendsCubit>().state;
    return showModalBottomSheet<ChatTarget>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheet).height * 0.75),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('Forward to', style: HakiText.display(26)),
            ),
            for (final g in state.groups)
              ListTile(
                leading: GroupAvatar(group: g, size: 40, radius: 14),
                title: Text(g.name),
                subtitle: Text('${g.members.length} people', style: const TextStyle(color: HakiColors.textMuted)),
                onTap: () => Navigator.pop(sheet, (user: null, group: g)),
              ),
            for (final f in state.friends)
              ListTile(
                leading: AuraAvatar(user: f, size: 40, radius: 14),
                title: Text(f.name),
                onTap: () => Navigator.pop(sheet, (user: f, group: null)),
              ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: RadialGradient(colors: HakiColors.auras[4]),
                ),
                child: Text('#', style: HakiText.display(16)),
              ),
              title: const Text('Haki Lounge'),
              subtitle: const Text('Public · not encrypted', style: TextStyle(color: HakiColors.dangerText)),
              onTap: () => Navigator.pop(sheet, (user: null, group: null)),
            ),
          ],
        ),
      ),
    );
  }
}
