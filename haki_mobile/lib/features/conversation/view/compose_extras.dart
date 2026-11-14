import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/haki_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../../models/message_envelope.dart';
import '../../../models/message_model.dart';
import 'package:chat_mobile/core/theme/haki_icons.dart';

/// Bundled stickers: sent inside the encrypted body, so no sticker service ever sees them.
const hakiStickers = [
  '🔥', '😂', '🥹', '😍', '🤯', '😎', '🥳', '🙌', '👀', '💀', '🫶', '✨', //
  '🎉', '💯', '🤝', '😴', '🤔', '😭', '🙏', '❤️‍🔥', '🍕', '☕️', '🚀', '🌙',
];

abstract final class StickerSheet {
  static Future<String?> pick(BuildContext context) => showModalBottomSheet<String>(
    context: context,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text('Stickers', style: HakiText.display(26)),
            ),
            GridView.count(
              crossAxisCount: 6,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final s in hakiStickers)
                  InkResponse(
                    onTap: () => Navigator.pop(sheet, s),
                    child: Center(child: Text(s, style: const TextStyle(fontSize: 34))),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// A sticker in the chat: big, frameless, with a soft aura behind it.
class StickerBubble extends StatelessWidget {
  const StickerBubble({super.key, required this.sticker, required this.seed});
  final String sticker;
  final int seed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      height: 132,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [HakiColors.auraFor(seed)[0].withValues(alpha: 0.45), Colors.transparent],
        ),
      ),
      child: Text(sticker, style: const TextStyle(fontSize: 84)),
    );
  }
}

/// Create a poll: a question and 2–10 options, single or multiple choice.
class PollComposerSheet extends StatefulWidget {
  const PollComposerSheet({super.key});

  static Future<PollData?> show(BuildContext context) => showModalBottomSheet<PollData>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const PollComposerSheet(),
  );

  @override
  State<PollComposerSheet> createState() => _PollComposerSheetState();
}

class _PollComposerSheetState extends State<PollComposerSheet> {
  final _question = TextEditingController();
  final _options = [TextEditingController(), TextEditingController()];
  bool _multi = false;

  @override
  void dispose() {
    _question.dispose();
    for (final c in _options) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _filled => [for (final c in _options) if (c.text.trim().isNotEmpty) c.text.trim()];
  bool get _valid => _question.text.trim().isNotEmpty && _filled.length >= 2;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('New poll', style: HakiText.display(28)),
            const SizedBox(height: 4),
            const Text(
              'The question and options are encrypted. The server only counts votes.',
              style: TextStyle(color: HakiColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _question,
              autofocus: true,
              maxLength: 140,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Question'),
            ),
            for (var i = 0; i < _options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextField(
                  controller: _options[i],
                  maxLength: 60,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() {
                    // A new empty row appears once the last one is used
                    if (i == _options.length - 1 && _options[i].text.isNotEmpty && _options.length < 10) {
                      _options.add(TextEditingController());
                    }
                  }),
                  decoration: InputDecoration(labelText: 'Option ${i + 1}', counterText: ''),
                ),
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _multi,
              onChanged: (v) => setState(() => _multi = v),
              activeThumbColor: HakiColors.lime,
              title: const Text('Allow more than one answer'),
            ),
            const SizedBox(height: 8),
            LimeButton(
              label: 'Send poll',
              icon: HakiIcons.chartBar,
              onPressed: _valid
                  ? () => Navigator.pop(context, PollData(question: _question.text.trim(), options: _filled, multi: _multi))
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// The poll inside a bubble: tap an option to vote; bars show the share of voters.
class PollCard extends StatelessWidget {
  const PollCard({super.key, required this.message, required this.myId, required this.onVote});
  final MessageModel message;
  final int myId;
  final ValueChanged<int> onVote;

  @override
  Widget build(BuildContext context) {
    final poll = message.poll!;
    final votes = message.pollVotes;
    final voters = votes.values.where((v) => v.isNotEmpty).length;
    final mine = votes[myId] ?? const [];
    int count(int i) => votes.values.where((v) => v.contains(i)).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(HakiIcons.chartBar, size: 16, color: HakiColors.lime),
              const SizedBox(width: 6),
              Text(poll.multi ? 'Poll · pick any' : 'Poll · pick one',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
            ],
          ),
          const SizedBox(height: 6),
          Text(poll.question, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.3)),
          const SizedBox(height: 10),
          for (var i = 0; i < poll.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Semantics(
                button: true,
                selected: mine.contains(i),
                label: '${poll.options[i]}, ${count(i)} votes',
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: message.id == null ? null : () => onVote(i),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: voters == 0 ? 0 : count(i) / voters,
                            child: ColoredBox(
                              color: (mine.contains(i) ? HakiColors.lime : Colors.white).withValues(alpha: 0.22),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: mine.contains(i) ? HakiColors.lime : Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                mine.contains(i)
                                    ? HakiIcons.checkCircleFill
                                    : (poll.multi ? HakiIcons.square : HakiIcons.circle),
                                size: 18,
                                color: mine.contains(i) ? HakiColors.lime : Colors.white.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(poll.options[i], style: const TextStyle(fontSize: 14))),
                              Text('${count(i)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Text(
            voters == 1 ? '1 person voted' : '$voters people voted',
            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.65)),
          ),
        ],
      ),
    );
  }
}

/// Date + time picker for "send later". Returns null if cancelled or in the past.
Future<DateTime?> pickSendTime(BuildContext context) async {
  final now = DateTime.now();
  final day = await showDatePicker(
    context: context,
    initialDate: now,
    firstDate: now,
    lastDate: now.add(const Duration(days: 29)),
    helpText: 'Send on',
  );
  if (day == null || !context.mounted) return null;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(now.add(const Duration(minutes: 5))),
    helpText: 'Send at',
  );
  if (time == null) return null;
  final at = DateTime(day.year, day.month, day.day, time.hour, time.minute);
  if (at.isBefore(DateTime.now().add(const Duration(seconds: 30)))) {
    if (context.mounted) showHakiToast(context, 'Pick a time in the future', isError: true);
    return null;
  }
  return at;
}

String sendTimeLabel(DateTime at) {
  final now = DateTime.now();
  final sameDay = at.year == now.year && at.month == now.month && at.day == now.day;
  return sameDay ? 'today at ${DateFormat.jm().format(at)}' : DateFormat('EEE d MMM, h:mm a').format(at);
}
