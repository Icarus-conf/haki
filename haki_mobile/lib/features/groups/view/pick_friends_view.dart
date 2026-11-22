import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/haki_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../../models/group_model.dart';
import '../../friends/view_model/friends_cubit.dart';
import 'package:chat_mobile/core/theme/haki_icons.dart';

/// New group (name + friends), or "Add people" to an existing [group].
class PickFriendsView extends StatefulWidget {
  const PickFriendsView({super.key, this.group});
  final GroupModel? group;

  static Future<GroupModel?> newGroup(BuildContext context) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const PickFriendsView()));

  static Future<void> addTo(BuildContext context, GroupModel group) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => PickFriendsView(group: group)));

  @override
  State<PickFriendsView> createState() => _PickFriendsViewState();
}

class _PickFriendsViewState extends State<PickFriendsView> {
  final _name = TextEditingController();
  final _picked = <int>{};
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final friends = context.read<FriendsCubit>();
    setState(() => _busy = true);
    String? error;
    GroupModel? created;
    if (widget.group == null) {
      final res = await friends.createGroup(_name.text, _picked.toList());
      created = res.$1;
      error = res.$2;
    } else {
      error = await friends.addToGroup(widget.group!.id, _picked.toList());
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) return showHakiToast(context, error, isError: true);
    Navigator.pop(context, created);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.group == null;
    final already = {for (final m in widget.group?.members ?? const []) m.id};
    final friends = context.select((FriendsCubit c) => c.state.friends).where((f) => !already.contains(f.id)).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final canSave = _picked.isNotEmpty && (!isNew || _name.text.trim().isNotEmpty);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(left: 0, right: 0, top: 0, child: AuroraBackground(height: 300)),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 20, 0),
                  child: Row(
                    children: [
                      GlassIconButton(icon: HakiIcons.arrowLeft, tooltip: 'Back', onPressed: () => Navigator.pop(context)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(isNew ? 'New group' : 'Add people', style: HakiText.display(30))),
                    ],
                  ),
                ),
                if (isNew)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: TextField(
                      controller: _name,
                      maxLength: 60,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(labelText: 'Group name'),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                  child: Row(
                    children: [
                      const Icon(HakiIcons.lockFill, size: 14, color: HakiColors.textMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          isNew
                              ? 'End-to-end encrypted. Only people in the group can read it.'
                              : 'New people see messages from now on, not older ones.',
                          style: const TextStyle(fontSize: 13, color: HakiColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: friends.isEmpty
                      ? Center(
                          child: Text(
                            isNew ? 'Add friends first, then make a group.' : 'All your friends are already here.',
                            style: const TextStyle(color: HakiColors.textMuted),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 110),
                          itemCount: friends.length,
                          itemBuilder: (context, i) {
                            final f = friends[i];
                            final on = _picked.contains(f.id);
                            return CheckboxListTile(
                              value: on,
                              onChanged: (_) => setState(() => on ? _picked.remove(f.id) : _picked.add(f.id)),
                              secondary: AuraAvatar(user: f, size: 42, radius: 15),
                              title: Text(f.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('@${f.username}', style: const TextStyle(color: HakiColors.textMuted)),
                              activeColor: HakiColors.lime,
                              checkColor: HakiColors.onLime,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 0,
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 16),
              child: LimeButton(
                label: isNew
                    ? (_picked.isEmpty ? 'Create group' : 'Create with ${_picked.length + 1} people')
                    : (_picked.isEmpty ? 'Add' : 'Add ${_picked.length}'),
                icon: isNew ? HakiIcons.userCirclePlus : HakiIcons.userPlus,
                busy: _busy,
                onPressed: canSave && !_busy ? _save : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
