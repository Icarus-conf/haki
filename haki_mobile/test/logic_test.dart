import 'package:chat_mobile/features/settings/view_model/settings_cubit.dart';
import 'package:chat_mobile/features/conversation/view_model/conversation_cubit.dart';
import 'package:chat_mobile/models/group_model.dart';
import 'package:chat_mobile/services/message_sender.dart';
import 'package:chat_mobile/features/session/view_model/session_state.dart';
import 'package:chat_mobile/models/message_envelope.dart';
import 'package:chat_mobile/models/message_model.dart';
import 'package:chat_mobile/services/link_preview_service.dart';
import 'package:chat_mobile/models/user_model.dart';
import 'package:chat_mobile/services/crypto_service.dart';
import 'dart:convert';

import 'package:asn1lib/asn1lib.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/export.dart' as pc;

void main() {
  test('safety number is order-independent, 12×5 digits, and key-specific', () async {
    final ab = await CryptoService.safetyNumber(['KEY-A', 'KEY-B']);
    final ba = await CryptoService.safetyNumber(['KEY-B', 'KEY-A']);
    final ac = await CryptoService.safetyNumber(['KEY-A', 'KEY-C']);
    expect(ab, ba);
    expect(ab, isNot(ac));
    expect(RegExp(r'^(\d{5} ){11}\d{5}$').hasMatch(ab), isTrue);
    // Whitespace in PEM bodies must not change the number
    expect(await CryptoService.safetyNumber(['KEY-A\n', ' KEY-B']), ab);
  });

  test('friends payload parses unread count, last message and initials', () {
    final u = UserModel.fromJson({
      'id': 3,
      'username': 'layla',
      'displayName': 'Layla Hassan',
      'unreadCount': 2,
      'lastMessage': {'content': 'x', 'timestamp': '2026-11-13T10:00:00.000Z', 'senderId': 3, 'attachmentType': 'voice'},
    });
    expect(u.unreadCount, 2);
    expect(u.lastMessage!.attachmentType, 'voice');
    expect(u.initials, 'LH');
    expect(UserModel(id: 1, username: 'omar').initials, 'O');
    expect(UserModel(id: 1, username: 'omar').name, 'omar');
  });

  test('message parses flattened reactions and read state', () {
    final m = MessageModel.fromJson({
      'id': 9,
      'sender': 'Omar',
      'username': 'omar',
      'senderId': 2,
      'message': 'hi',
      'timestamp': '2026-11-13T10:00:00.000Z',
      'recipientId': 1,
      'isRead': true,
      'attachmentUrl': '/uploads/messages/a.m4a',
      'reactions': [
        {'id': 1, 'emoji': '❤️', 'userId': 1, 'username': 'me'},
      ],
    });
    expect(m.isRead, isTrue);
    expect(m.reactions.single.userId, 1);
    expect(m.isVoice, isTrue);
    expect(m.isImage, isFalse);
  });

  test('session state exposes the signed-in user only when signed in', () {
    final me = UserModel(id: 1, username: 'me');
    expect(const SessionState.unauthenticated().me, isNull);
    expect(SessionState.authenticated(me: me).me, me);
    expect(SessionState.onboarding(me: me, mnemonic: 'w').me, me);
  });

  test('word-derived public keys are standard X.509 (rsaEncryption OID)', () {
    final key = pc.RSAPublicKey(BigInt.parse('C' * 512, radix: 16) | BigInt.one, BigInt.from(65537));
    final body = CryptoService.encodePublicKeyPem(key)
        .replaceAll(RegExp(r'-----[A-Z ]+-----|\s'), '');
    // SEQUENCE { SEQUENCE { OID 1.2.840.113549.1.1.1, NULL }, BIT STRING ... } for a 2048-bit key
    expect(body.startsWith('MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA'), isTrue, reason: body.substring(0, 44));
  });

  test('message envelope: plain text unchanged, preview round-trips', () {
    expect(MessageEnvelope.encode('hi'), 'hi');
    expect(MessageEnvelope.decode('hi').text, 'hi');
    expect(MessageEnvelope.decode('{"not":"ours"}').text, '{"not":"ours"}');
    const p = LinkPreview(url: 'https://a.test/x', title: 'A', description: 'd', site: 'a.test');
    final body = MessageEnvelope.decode(MessageEnvelope.encode('see https://a.test/x', preview: p));
    expect(body.text, 'see https://a.test/x');
    expect(body.preview, p);
  });

  test('preview parser reads Open Graph, falls back to <title>, unescapes', () {
    final og = LinkPreviewService.parse('https://news.test/a', '''
      <head><meta property="og:title" content="Big &amp; Bold">
      <meta content="Short summary" property="og:description">
      <meta property="og:site_name" content="News Test"><title>ignored</title></head>''');
    expect(og!.title, 'Big & Bold');
    expect(og.description, 'Short summary');
    expect(og.site, 'News Test');
    final plain = LinkPreviewService.parse('https://plain.test/', '<title> Plain page </title>');
    expect(plain!.title, 'Plain page');
    expect(plain.site, 'plain.test');
    expect(LinkPreviewService.parse('https://x.test', '<p>no title</p>'), isNull);
    expect(LinkPreviewService.firstUrl('go to https://x.test/a?b=1 now'), 'https://x.test/a?b=1');
  });

  test('sameKey matches one key across X.509 and PKCS#1, rejects a different key', () {
    String pkcs1(BigInt n) => base64Encode((ASN1Sequence()
          ..add(ASN1Integer(n))
          ..add(ASN1Integer(BigInt.from(65537))))
        .encodedBytes);
    final n1 = BigInt.parse('C' * 512, radix: 16) | BigInt.one;
    final n2 = BigInt.parse('D' * 512, radix: 16) | BigInt.one;
    final x509 = CryptoService.encodePublicKeyPem(pc.RSAPublicKey(n1, BigInt.from(65537)));
    expect(CryptoService.publicKeyModulus(x509), n1);
    expect(CryptoService.sameKey(x509, pkcs1(n1)), isTrue);
    expect(CryptoService.sameKey(x509, pkcs1(n2)), isFalse);
    expect(CryptoService.sameKey('not a key', pkcs1(n1)), isFalse);
  });

  test('envelope carries the forwarded flag; edits and history parse', () {
    final fwd = MessageEnvelope.decode(MessageEnvelope.encode('hi', forwarded: true));
    expect(fwd.text, 'hi');
    expect(fwd.forwarded, isTrue);
    expect(MessageEnvelope.decode('plain').forwarded, isFalse);
    final m = MessageModel.fromJson({
      'id': 1, 'sender': 'Ana', 'username': 'ana', 'senderId': 1, 'message': 'x',
      'timestamp': '2026-11-14T10:00:00.000Z', 'groupId': 7, 'pinned': true,
      'editedAt': '2026-11-14T10:05:00.000Z',
    });
    expect(m.groupId, 7);
    expect(m.pinned, isTrue);
    expect(m.editedAt, isNotNull);
  });

  test('search matches decrypted text on the phone, case-insensitive', () {
    MessageModel msg(int id, String text) => MessageModel(
      id: id, sender: 'A', username: 'a', senderId: 1, message: text, timestamp: DateTime(2026),
    );
    final s = ConversationState(messages: [msg(1, 'Dinner at 8?'), msg(2, 'ok'), msg(3, 'dinner done')]);
    expect(s.copyWith(query: 'DINNER').searchResults.map((m) => m.id), [1, 3]);
    expect(s.copyWith(query: '  ').searchResults.length, 3);
  });

  test('reader keys: DM wraps for both, group for every member with a key, Lounge none', () {
    const me = UserModel(id: 1, username: 'me', publicKey: 'K1');
    const ben = UserModel(id: 2, username: 'ben', publicKey: 'K2');
    const noKey = UserModel(id: 3, username: 'cy');
    expect(MessageSender.readerKeys((user: ben, group: null), me), {'r': 'K2', 's': 'K1'});
    expect(MessageSender.readerKeys((user: null, group: null), me), isNull);
    final g = GroupModel(id: 9, name: 'Trip', members: [me, ben, noKey]);
    expect(MessageSender.readerKeys((user: null, group: g), me), {'1': 'K1', '2': 'K2'});
    expect(() => MessageSender.readerKeys((user: noKey, group: null), me), throwsException);
    expect(
      () => MessageSender.readerKeys((user: null, group: GroupModel(id: 1, name: 'x', members: [me, noKey])), me),
      throwsException,
    );
  });

  test('envelope carries polls, story replies, stickers and voice length', () {
    final enc = MessageEnvelope.encode(
      'nice!',
      poll: const PollData(question: 'Where?', options: ['Beach', 'Hills'], multi: true),
      story: const StoryRef(id: 4, url: '/uploads/stories/a.png'),
      sticker: '🔥',
      durationSec: 12,
    );
    final b = MessageEnvelope.decode(enc);
    expect(b.text, 'nice!');
    expect(b.poll!.options, ['Beach', 'Hills']);
    expect(b.poll!.multi, isTrue);
    expect(b.story!.id, 4);
    expect(b.sticker, '🔥');
    expect(b.durationSec, 12);
    expect(MessageEnvelope.encode('plain'), 'plain'); // nothing extra = still plain text
  });

  test('poll votes parse from the server map; bad entries are skipped', () {
    expect(MessageModel.parseVotes({'3': [0, 2], 'x': [1], '5': 'bad'}), {3: [0, 2]});
    expect(MessageModel.parseVotes(null), isEmpty);
  });

  test('folders round-trip through storage JSON', () {
    final f = ChatFolder(name: 'Work', chats: {ChatFolder.userKey(2), ChatFolder.groupKey(9)});
    final back = ChatFolder.fromJson(f.toJson());
    expect(back.name, 'Work');
    expect(back.chats, {'u:2', 'g:9'});
  });

  test('file name and size travel inside the encrypted body', () {
    final b = MessageEnvelope.decode(MessageEnvelope.encode('', file: const FileMeta(name: 'Trip plan.pdf', size: 2621440)));
    expect(b.file!.name, 'Trip plan.pdf');
    expect(b.file!.sizeLabel, '2.5 MB');
    expect(b.file!.extension, 'PDF');
  });

  test('attachment kinds: videos and files are never shown as photos', () {
    MessageModel m(String? type, String url) =>
        MessageModel(sender: 'a', username: 'a', senderId: 1, message: '', timestamp: DateTime(2026), attachmentType: type, attachmentUrl: url);
    expect(m('video', '/uploads/messages/x.bin').isImage, isFalse);
    expect(m('video', '/uploads/messages/x.bin').isVideo, isTrue);
    expect(m('file', '/uploads/messages/x.bin').isImage, isFalse);
    expect(m(null, '/uploads/messages/old.jpg').isImage, isTrue); // old messages had no type
    expect(m('voice', '/uploads/messages/v.m4a').isImage, isFalse);
  });

  test('view once and disappearing fields parse from the server', () {
    final m = MessageModel.fromJson({
      'id': 1, 'sender': 'a', 'username': 'a', 'senderId': 1, 'message': 'x', 'timestamp': '2026-11-14T10:00:00Z',
      'viewOnce': true, 'viewedAt': '2026-11-14T10:01:00Z', 'expiresAt': '2026-11-15T10:00:00Z',
    });
    expect(m.viewOnce, isTrue);
    expect(m.isOpenedViewOnce, isTrue);
    expect(m.expiresAt, isNotNull);
    expect(ConversationCubit.disappearLabel(86400), '1 day');
    expect(ConversationCubit.disappearLabel(2592000), '30 days');
  });

  test('birthday countdown: today, tomorrow, wraps the year, none', () {
    const u = UserModel(id: 1, username: 'a', birthday: '03-15');
    expect(u.daysToBirthday(DateTime(2026, 3, 15, 23)), 0);
    expect(u.daysToBirthday(DateTime(2026, 3, 14)), 1);
    expect(u.daysToBirthday(DateTime(2026, 3, 16)), 364);
    expect(const UserModel(id: 2, username: 'b').daysToBirthday(DateTime(2026)), isNull);
    expect(UserModel.fromJson({'id': 3, 'username': 'c', 'birthday': '12-31'}).birthday, '12-31');
  });

  test('device link: only the new device’s key opens the sealed account key', () async {
    final (device, devicePub) = await CryptoService.linkKeyPair();
    final (sealed, phonePub) = await CryptoService.sealForLink('{"privateKey":"PEM"}', devicePub);
    expect(await CryptoService.openLink(sealed, device, phonePub), '{"privateKey":"PEM"}');
    final (other, _) = await CryptoService.linkKeyPair();
    await expectLater(CryptoService.openLink(sealed, other, phonePub), throwsA(anything));
    final check = await CryptoService.linkCheck(devicePub);
    expect(RegExp(r'^\d{3} \d{3}$').hasMatch(check), isTrue);
    expect(await CryptoService.linkCheck(devicePub), check);
  });

  test('group unread count comes from the server', () {
    expect(GroupModel.fromJson({'id': 1, 'name': 'G', 'members': [], 'unreadCount': 4}).unreadCount, 4);
  });

  test('key pins: first key is trusted, a different one is flagged until checked', () async {
    final s = SettingsCubit(storage: _MemoryStorage());
    expect(await s.checkKey(7, 'aaa'), isFalse);
    expect(await s.checkKey(7, 'aaa'), isFalse);
    expect(await s.checkKey(7, 'bbb'), isTrue);
    expect(s.state.keyChanged, {7});
    await s.acknowledgeKey(7);
    expect(s.state.keyChanged, isEmpty);
  });

  test('backup merge keeps what is on this phone and adds the rest', () async {
    final s = SettingsCubit(storage: _MemoryStorage());
    await s.setNote(1, 'mine');
    await s.toggleLock('u:1');
    await s.importBackup({
      'notes': {'1': 'old', '2': 'from backup'},
      'locked': ['g:5'],
      'pinned': [9],
      'folders': [{'name': 'Work', 'chats': ['u:2']}],
      'keyPins': {'2': 'fp'},
    });
    expect(s.state.notes, {1: 'mine', 2: 'from backup'});
    expect(s.state.lockedChats, {'u:1', 'g:5'});
    expect(s.state.pinnedIds, {9});
    expect(s.state.folders.single.name, 'Work');
    expect(s.state.keyPins[2], 'fp');
    expect(s.exportBackup()['notes'], {'1': 'mine', '2': 'from backup'});
  });
}

/// In-memory secure storage for settings tests.
class _MemoryStorage extends FlutterSecureStorage {
  _MemoryStorage();
  final _m = <String, String>{};

  @override
  Future<String?> read({required String key, AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions,
      WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async => _m[key];

  @override
  Future<void> write({required String key, required String? value, AppleOptions? iOptions, AndroidOptions? aOptions,
      LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async {
    value == null ? _m.remove(key) : _m[key] = value;
  }
}
