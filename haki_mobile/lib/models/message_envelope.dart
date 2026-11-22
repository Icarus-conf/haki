import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'message_envelope.freezed.dart';

/// Link preview built on the sender's phone and sent inside the encrypted message, so the
/// server never learns the link and the reader's phone never contacts the website.
@Freezed(fromJson: false, toJson: false)
abstract class LinkPreview with _$LinkPreview {
  const LinkPreview._();

  const factory LinkPreview({
    required String url,
    required String title,
    String? description,
    String? site,
  }) = _LinkPreview;

  factory LinkPreview.fromJson(Map<String, dynamic> j) => LinkPreview(
    url: j['url'] as String,
    title: j['title'] as String,
    description: j['description'] as String?,
    site: j['site'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'url': url,
    'title': title,
    'description': ?description,
    'site': ?site,
  };
}

/// A poll. The question and options travel encrypted; the server only counts option numbers.
class PollData {
  const PollData({required this.question, required this.options, this.multi = false});
  final String question;
  final List<String> options;
  final bool multi;

  factory PollData.fromJson(Map<String, dynamic> j) => PollData(
    question: j['q'] as String? ?? '',
    options: [for (final o in j['o'] as List? ?? const []) o.toString()],
    multi: j['m'] == true,
  );

  Map<String, dynamic> toJson() => {'q': question, 'o': options, if (multi) 'm': true};
}

/// The story a message replies to (its image URL is already public to friends).
class StoryRef {
  const StoryRef({required this.id, required this.url});
  final int id;
  final String url;

  factory StoryRef.fromJson(Map<String, dynamic> j) => StoryRef(id: j['id'] as int, url: j['url'] as String);
  Map<String, dynamic> toJson() => {'id': id, 'url': url};
}

/// A shared video or document: its real name and size travel encrypted, the server only
/// stores an anonymous encrypted blob.
class FileMeta {
  const FileMeta({required this.name, required this.size});
  final String name;
  final int size;

  factory FileMeta.fromJson(Map<String, dynamic> j) => FileMeta(name: j['n'] as String? ?? 'file', size: (j['s'] as num?)?.toInt() ?? 0);
  Map<String, dynamic> toJson() => {'n': name, 's': size};

  String get sizeLabel {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(0)} KB';
    return '${(size / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  String get extension => name.contains('.') ? name.split('.').last.toUpperCase() : 'FILE';
}

typedef EnvelopeBody = ({
  String text,
  LinkPreview? preview,
  bool forwarded,
  PollData? poll,
  StoryRef? story,
  String? sticker,
  int? durationSec,
  FileMeta? file,
});

/// What actually gets encrypted. Plain text stays plain text (old clients and messages keep
/// working); anything richer becomes `{"haki":1,"text":…, …}`.
abstract final class MessageEnvelope {
  static String encode(
    String text, {
    LinkPreview? preview,
    bool forwarded = false,
    PollData? poll,
    StoryRef? story,
    String? sticker,
    int? durationSec,
    FileMeta? file,
  }) {
    final extra = <String, dynamic>{
      'file': ?file?.toJson(),
      'preview': ?preview?.toJson(),
      if (forwarded) 'fwd': true,
      'poll': ?poll?.toJson(),
      'story': ?story?.toJson(),
      'sticker': ?sticker,
      'dur': ?durationSec,
    };
    return extra.isEmpty ? text : jsonEncode({'haki': 1, 'text': text, ...extra});
  }

  static EnvelopeBody decode(String plaintext) {
    EnvelopeBody plain() =>
        (text: plaintext, preview: null, forwarded: false, poll: null, story: null, sticker: null, durationSec: null, file: null);
    if (!plaintext.startsWith('{"haki":')) return plain();
    try {
      final j = jsonDecode(plaintext) as Map<String, dynamic>;
      Map<String, dynamic>? obj(String k) => j[k] is Map<String, dynamic> ? j[k] as Map<String, dynamic> : null;
      return (
        text: j['text'] as String? ?? '',
        preview: obj('preview') == null ? null : LinkPreview.fromJson(obj('preview')!),
        forwarded: j['fwd'] == true,
        poll: obj('poll') == null ? null : PollData.fromJson(obj('poll')!),
        story: obj('story') == null ? null : StoryRef.fromJson(obj('story')!),
        sticker: j['sticker'] as String?,
        durationSec: (j['dur'] as num?)?.toInt(),
        file: obj('file') == null ? null : FileMeta.fromJson(obj('file')!),
      );
    } catch (_) {
      return plain();
    }
  }
}
