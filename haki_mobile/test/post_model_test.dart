import 'package:flutter_test/flutter_test.dart';
import 'package:chat_mobile/models/post_model.dart';
import 'package:chat_mobile/models/user_model.dart';

void main() {
  final p = PostModel(
    id: 1,
    author: const UserModel(id: 1, username: 'a'),
    text: '',
    media: const [],
    createdAt: DateTime(2026),
    key: const [],
    reactions: const {'❤️': 2},
  );

  test('reacting, switching and taking back keep counts right', () {
    final loved = p.reacted('❤️');
    expect(loved.reactions, {'❤️': 3});
    final fire = loved.reacted('🔥');
    expect(fire.reactions, {'❤️': 2, '🔥': 1});
    expect(fire.myReaction, '🔥');
    final none = fire.reacted(null);
    expect(none.reactions, {'❤️': 2});
    expect(none.myReaction, isNull);
  });
}
