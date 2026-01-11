import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../providers/chat_provider.dart';
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
  Uint8List? _decryptedBytes;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _decrypt();
  }

  Future<void> _decrypt() async {
    try {
      final chat = context.read<ChatProvider>();
      final response = await http.get(Uri.parse('${ApiService.baseUrl}${widget.url}'));
      if (response.statusCode == 200) {
        final encryptedBytes = response.bodyBytes;
        final decrypted = await chat.crypto.decryptMedia(
          encryptedBytes: encryptedBytes,
          ivBase64: widget.iv,
          keys: widget.keys,
          username: chat.me!.username,
        );
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
        color: Colors.grey[100],
        child: const Center(child: Icon(Icons.error_outline, color: Colors.red)),
      );
    }
    if (_decryptedBytes == null) {
      return Container(
        height: 200,
        color: Colors.grey[100],
        child: const Center(child: Icon(Icons.lock_outline, color: Colors.grey)),
      );
    }
    return Image.memory(
      _decryptedBytes!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image)),
    );
  }
}
