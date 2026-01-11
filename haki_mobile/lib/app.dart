import 'dart:developer';

import 'package:chat_mobile/views/recovery_onboarding_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/chat_provider.dart';
import 'views/blocked_users_view.dart';
import 'views/login_view.dart';
import 'views/responsive_home.dart';
import 'views/shared_media_view.dart';
import 'widgets/full_page_loading.dart';

class ChatApp extends StatefulWidget {
  const ChatApp({super.key});

  @override
  State<ChatApp> createState() => _ChatAppState();
}

class _ChatAppState extends State<ChatApp> {
  @override
  void initState() {
    super.initState();
    // Defer the auto-login check until after the provider is available in the tree
    // Actually, we can't access provider in initState easily without listen: false context,
    // but the Consumer below will rebuild.
    // However, we want to trigger the check ONCE.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().tryAutoLogin();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chat, child) {
        // Debug navigation logic
        if (chat.isAppInitialized) {
          log('ChatApp Rebuild: me=${chat.me?.username}, needsOnboarding=${chat.needsOnboarding}');
        }

        return MaterialApp(
          key: ValueKey('${chat.me?.id ?? 'guest'}_${chat.needsOnboarding}'),
          title: 'Haki',
          debugShowCheckedModeBanner: false,
          themeMode: chat.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Poppins',
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromARGB(255, 29, 30, 126),
              primary: const Color.fromARGB(255, 29, 30, 126),
              secondary: const Color.fromARGB(255, 107, 92, 255),
              surface: Colors.white,
            ),
            textTheme: const TextTheme(
              titleLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
              bodyMedium: TextStyle(color: Color(0xFF475569)),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Poppins',
            brightness: Brightness.dark,

            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromARGB(255, 107, 92, 255),
              primary: const Color.fromARGB(255, 107, 92, 255),
              secondary: const Color.fromARGB(255, 147, 132, 255),
              surface: Colors.black, // Deep Dark OLED
              // ignore: deprecated_member_use
              background: Colors.black,
              onSurface: Colors.white,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: Colors.black,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.black,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
            ),
            cardTheme: CardThemeData(
              color: Colors.grey[900],
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            textTheme: const TextTheme(
              titleLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white),
              bodyMedium: TextStyle(color: Color(0xFFE2E8F0)),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF1E293B), // Dark Slate
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              hintStyle: const TextStyle(color: Colors.grey),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
          home: chat.isAppInitialized
              ? (chat.me == null
                    ? const LoginView(key: ValueKey('login'))
                    : (chat.needsOnboarding
                          ? RecoveryOnboardingView(
                              key: const ValueKey('onboarding'),
                              mnemonic:
                                  chat.currentMnemonic ?? '', // Should be set during registration
                            )
                          : const ResponsiveHome(key: ValueKey('home'))))
              : const FullPageLoading(message: 'Initializing...'),
          onGenerateRoute: (settings) {
            if (settings.name == '/shared-media') {
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (context) => SharedMediaView(
                  recipientId: args['recipientId'],
                  recipientName: args['recipientName'],
                ),
              );
            } else if (settings.name == '/blocked-users') {
              return MaterialPageRoute(builder: (context) => const BlockedUsersView());
            }
            return null;
          },
        );
      },
    );
  }
}
