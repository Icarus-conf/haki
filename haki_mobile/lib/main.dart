import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app.dart';
import 'features/call/view_model/call_cubit.dart';
import 'features/call/view_model/group_call_cubit.dart';
import 'features/friends/view_model/friends_cubit.dart';
import 'features/session/view_model/session_cubit.dart';
import 'features/settings/view_model/settings_cubit.dart';
import 'features/stories/view_model/stories_cubit.dart';
import 'services/api_service.dart';
import 'services/chat_service.dart';
import 'services/crypto_service.dart';
import 'services/push_service.dart';
import 'services/webrtc_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Model layer: one instance of each service for the whole app
  final api = ApiService();
  final chat = ChatService();
  final crypto = CryptoService();
  final webrtc = WebRTCService(chat);
  final push = PushService(api);

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: api),
        RepositoryProvider.value(value: chat),
        RepositoryProvider.value(value: crypto),
        RepositoryProvider.value(value: push),
      ],
      // ViewModels shared across screens; per-screen ones (ConversationCubit) are created by their view
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => SessionCubit(api: api, chat: chat, crypto: crypto, push: push)..tryAutoLogin(),
          ),
          BlocProvider(create: (_) => FriendsCubit(api: api, chat: chat, crypto: crypto)),
          BlocProvider(create: (_) => StoriesCubit(api: api, chat: chat)),
          BlocProvider(create: (_) => SettingsCubit()..load()),
          BlocProvider(create: (_) => CallCubit(chat: chat, webrtc: webrtc)),
          BlocProvider(
            create: (ctx) => GroupCallCubit(chat: chat, myId: () => ctx.read<SessionCubit>().me?.id),
          ),
        ],
        child: const HakiApp(),
      ),
    ),
  );
}
