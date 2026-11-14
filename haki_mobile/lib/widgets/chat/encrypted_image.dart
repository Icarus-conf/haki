import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/session/view_model/session_cubit.dart';
import '../../services/api_service.dart';
import '../loading_indicator.dart';

class EncryptedImage extends StatefulWidget {
  final String url;
  final String iv;
  final Map<String, dynamic> keys;

  const EncryptedImage({super.key, required this.url, required this.iv, required this.keys});

  @override
  State<EncryptedImage> createState() => _EncryptedImageState();
}

class _EncryptedImageState extends State<EncryptedImage> {
  // Decrypted photos by URL. List rebuilds and scrolling recreate this widget; without the
  // cache every recreation re-downloaded and re-decrypted (RSA + AES) the same photo.
  // ponytail: in-memory, 40 entries, cleared on app restart
  static final Map<String, Uint8List> _cache = {};

  Uint8List? _decryptedBytes;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final cached = _cache[widget.url];
    if (cached != null) {
      _decryptedBytes = cached;
      _isLoading = false;
      return;
    }
    _decrypt();
  }

  Future<void> _decrypt() async {
    try {
      final session = context.read<SessionCubit>();
      final response = await http.get(Uri.parse('${ApiService.baseUrl}${widget.url}'));
      if (response.statusCode == 200) {
        final encryptedBytes = response.bodyBytes;
        final decrypted = await session.crypto.decryptMedia(
          encryptedBytes: encryptedBytes,
          ivBase64: widget.iv,
          keys: widget.keys,
          username: session.me!.username,
        );
        if (decrypted != null) {
          if (_cache.length >= 40) _cache.remove(_cache.keys.first);
          _cache[widget.url] = decrypted;
        }
        if (mounted) {
          setState(() {
            _decryptedBytes = decrypted;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to download');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(height: 200, child: Center(child: LoadingIndicator(size: 24)));
    }
    if (_error != null) {
      return Container(
        height: 200,
        color: const Color(0xFF1C1C26),
        child: const Center(child: Icon(Icons.error_outline, color: Colors.red)),
      );
    }
    if (_decryptedBytes == null) {
      return Container(
        height: 200,
        color: const Color(0xFF1C1C26),
        child: const Center(child: Icon(Icons.lock_outline, color: Color(0xFF8E8EA6))),
      );
    }
    return Image.memory(
      _decryptedBytes!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image)),
    );
  }
}
