import '../models/story_model.dart';
import '../models/user_model.dart';

class StoryHelper {
  static Map<UserModel, List<StoryModel>> groupStories(List<StoryModel> stories) {
    final map = <int, List<StoryModel>>{};
    final userMap = <int, UserModel>{};

    for (var s in stories) {
      if (s.user == null) continue;
      if (!map.containsKey(s.userId)) {
        map[s.userId] = [];
        userMap[s.userId] = s.user!;
      }
      map[s.userId]!.add(s);
    }

    final result = <UserModel, List<StoryModel>>{};
    for (var id in map.keys) {
      result[userMap[id]!] = map[id]!;
    }
    return result;
  }
}
